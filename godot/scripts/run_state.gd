class_name RonkeRun
extends RefCounted

const WIDTH = 600.0
const HEIGHT = 820.0
const LAST_WAVE = 10
const WALL_LEFT = 16.0
const WALL_RIGHT = 584.0
const WALL_TOP = 22.0
const WALL_BOTTOM = 804.0

var character_profile: Dictionary = {}
var crew: Dictionary
var world: int
var rng = RandomNumberGenerator.new()
var practice = false
var phase = "playing"
var time = 0.0
var wave = 0
var wave_clock = 0.0
var clear_clock = 0.0
var next_id = 0
var balls: Array = []
var enemies: Array = []
var bullets: Array = []
var events: Array = []
var kills = 0
var bounces = 0
var combo = 0
var best_combo = 0
var combo_time = 0.0
var level = 1
var xp = 0
var xp_needed = 10
var choices: Array = []
var upgrade_clock = 0.0
var surge = 0.0
var surge_time = 0.0
var turn_time = 0.0
var reward = 0
var picks: Array = []
var player: Dictionary
var stats: Dictionary
var elements: Array = []
var element_levels: Dictionary = {}
var shot_clock = 0.0
var shot_count = 0
var dash_count = 0
var surge_count = 0
var breach_count = 0
var guardians_defeated = 0
var damage_taken = 0.0
var end_reason = ""
var special_slots = 5
var passive_slots = 5
var passives: Array = []
var passive_levels: Dictionary = {}
var special_cooldowns: Dictionary = {}
var special_inflight: Dictionary = {}
var launch_groups: Dictionary = {}
var turn_phase = "aim"
var enemy_turn_left = 0.0
var volley_released = false
var shoot_was_held = false
var world_time = 0.0
var hazards: Array = []
var falcons: Array[Vector2] = []
var available = true
var protective_charges = 0
var protective_recharge = 0.0
var automatic_choice = -1
var seekers: Array = []
var timestop_left = 0.0
var aura_clocks: Dictionary = {}
var allies: Array = []
var rejected_spawns: Dictionary = {"ball": 0, "seeker": 0, "hazard": 0, "ally": 0}
var hit_depth = 0
var pending_deaths: Array = []
var step_accumulator = 0.0
var pending_actions: Dictionary = {}
const FIXED_STEP = 1.0 / 120.0
const MAX_SEEKERS = 64
const MAX_HAZARDS = 64
const MAX_ALLIES = 32
const MAX_BALLS = 96
const TILE = 58.0

func _init(crew_id: String = "warrior", world_index: int = 0, run_seed: int = 1, meta: Dictionary = {}, practice_mode: bool = false) -> void:
	practice = practice_mode
	crew = RonkeData.crew(crew_id)
	available = crew.get("enabled", true)
	world = clampi(world_index, 0, 2)
	rng.seed = run_seed
	special_slots = 2 if crew.id == "hoary_hoarder" else 10 if crew.id == "ballbearer" else 5
	passive_slots = 10 if crew.id == "hoary_hoarder" else 0 if crew.id == "ballbearer" else 5
	var profile = RonkeBallRules.character(crew.id)
	character_profile = profile
	var health = float(profile.hp) + clampi(int(meta.get("vitality", 0)), 0, 3) * 10
	var capacity = 0 if crew.id in ["empty_nester", "makeshift_sisyphus"] else int(profile.baby_capacity) + clampi(int(meta.get("reserves", 0)), 0, 3)
	player = {"pos": Vector2(300, 750), "hp": float(health), "max_hp": float(health), "ammo": capacity, "capacity": capacity,
		"hurt": 0.0, "shoot": 0.0, "dash": 0.0, "dash_cd": 0.0, "moving": false, "invincible": 0.0, "dash_direction": Vector2.RIGHT}
	stats = {"damage": float(profile.damage) * (1.0 + clampi(int(meta.get("power", 0)), 0, 3) * 0.05),
		"interval": float(profile.interval), "speed": float(profile.speed), "bounce": 0.0,
		"instances": int(profile.nester_instances) + clampi(int(meta.get("reserves", 0)), 0, 3), "crit": float(profile.crit), "status": 1.0, "area": 1.0}
	elements = [] if crew.element == "" else [crew.element]
	for element in elements:
		element_levels[element] = 1
	falcons = [Vector2(30, 700), Vector2(570, 700)]
	if not available:
		phase = "unavailable"
		return
	if practice:
		_spawn_practice_targets()
		surge = 100.0
	else:
		spawn_wave()

func _spawn_practice_targets() -> void:
	for x in [120, 300, 480]:
		_add_enemy(Vector2(x, 220), 60, 120, "moss", 0)
	emit("practice_ready")

func emit(kind: String, data: Dictionary = {}) -> void:
	var event = data.duplicate()
	event["type"] = kind
	events.append(event)
	if events.size() > 240:
		events.pop_front()

func drain_events() -> Array:
	var result = events
	events = []
	return result

func advance(delta: float, input: Dictionary = {}) -> void:
	if not is_finite(delta) or delta <= 0: return
	delta = minf(delta, 0.25)
	if phase == "upgrade":
		if crew.id in ["cogitator", "radical"]:
			upgrade_clock += delta
			if upgrade_clock >= 0.9:
				choose_upgrade(automatic_choice if automatic_choice >= 0 else _automatic_upgrade_index())
		return
	if phase != "playing": return
	for action in ["dash", "surge", "recall"]:
		pending_actions[action] = bool(pending_actions.get(action, false)) or bool(input.get(action, false))
	step_accumulator += delta
	while step_accumulator + 0.00000001 >= FIXED_STEP and phase == "playing":
		step_accumulator = maxf(0, step_accumulator - FIXED_STEP)
		var frame = input.duplicate()
		for action in ["dash", "surge", "recall"]:
			frame[action] = pending_actions.get(action, false)
			pending_actions[action] = false
		_step(FIXED_STEP, frame)
	if phase != "playing":
		step_accumulator = 0
		pending_actions.clear()

const PRISM_WINDUP = 0.55
const BOSS_WINDUP = 0.75

func spawn_wave() -> void:
	wave += 1
	wave_clock = 0.0
	clear_clock = 0.0
	var boss = wave % 5 == 0
	var rows = 1 if boss else mini(3, 1 + int(wave / 3.0))
	for row in range(rows):
		for col in range(8):
			if not boss and rng.randf() < 0.17:
				continue
			var roll = rng.randf()
			var kind = "prism" if roll < 0.16 else "granite" if roll < 0.33 else "swift" if roll < 0.47 else "moss"
			var width = 37.0 if kind == "swift" else 55.0 if kind == "granite" else 47.0
			var hp = (18.0 + wave * 7.0 + world * 5.0) * (1.7 if kind == "granite" else 0.7 if kind == "swift" else 1.0)
			_add_enemy(Vector2(55 + col * 70, 65 + row * 66), width, hp, kind, 15.0 if kind == "swift" else 7.0 + wave * 0.6)
	if boss:
		_add_enemy(Vector2(300, 120), 110.0, (420.0 if wave == 5 else 900.0) * (1.0 + world * 0.15), "boss", 5.0)
	emit("wave", {"wave": wave, "boss": boss})

func _add_enemy(pos: Vector2, width: float, hp: float, kind: String, speed: float) -> void:
	next_id += 1
	enemies.append({"id": next_id, "pos": pos, "width": width, "hp": hp, "max_hp": hp, "kind": kind,
		"guardian": ("rootheart" if wave >= 10 else "gatekeeper") if kind == "boss" else "",
		"boss_phase": 1, "volley": 0, "attack_phase": 1, "attack_pattern": "gate_fan",
		"speed": speed, "fire": 2.0 + rng.randf() * 4.0, "charging": false, "attack_angle": 0.0, "burn": 0.0, "poison": 0.0, "slow": 0.0, "weak": 0.0, "flash": 0.0, "dead": false, "bleed_stacks": 0, "burn_stacks": 0, "poison_stacks": 0, "freeze": 0.0, "blind": 0.0, "charm": 0.0, "charm_attack": 0.0, "status_factor": 1.0, "statuses": {}, "blind_miss": false})

func _step(delta: float, supplied_input: Dictionary) -> void:
	var input = _radical_input() if crew.id == "radical" else supplied_input
	time += delta
	combo_time = maxf(0.0, combo_time - delta)
	if combo_time <= 0.0:
		combo = 0
	for key in ["hurt", "shoot", "invincible", "dash_cd", "dash"]:
		player[key] = maxf(0.0, float(player[key]) - delta)
	var tactician_clock = crew.id == "tactician" and not practice
	var field_delta = delta if not tactician_clock or turn_phase == "enemy" else 0.0
	for element in special_cooldowns:
		special_cooldowns[element] = maxf(0.0, float(special_cooldowns[element]) - field_delta)
	surge_time = maxf(0.0, surge_time - delta)
	if practice and surge_time <= 0.0:
		surge = 100.0
	var movement: Vector2 = input.get("move", Vector2.ZERO)
	movement = movement.limit_length()
	var aim: Vector2 = input.get("aim", Vector2(300, 100))
	var tactician = crew.id == "tactician" and not practice
	if tactician and turn_phase != "aim":
		movement = Vector2.ZERO
	player.moving = movement.length() > 0.05
	if input.get("recall", false):
		recall_balls()
	if input.get("dash", false) and player.dash_cd <= 0.0 and (not tactician or turn_phase == "aim"):
		player.dash = 0.18
		player.dash_cd = 3.5
		player.invincible = maxf(player.invincible, 0.25)
		player.dash_direction = movement.normalized() if movement.length() > 0.05 else Vector2(signf(aim.x - player.pos.x), 0)
		if player.dash_direction == Vector2.ZERO:
			player.dash_direction = Vector2.RIGHT
		dash_count += 1
		emit("dash", {"pos": player.pos})
	var motion: Vector2 = player.dash_direction if player.dash > 0.0 else movement
	var move_speed: float = stats.speed * (1.1 if passives.has("fleet_feet") else 1.0)
	if player.shoot > 0 and crew.id != "itchy_finger" and not passives.has("fleet_feet"):
		move_speed *= 0.8
	player.pos = (player.pos + motion * move_speed * (3.0 if player.dash > 0 else 1.0) * delta).clamp(Vector2(25, HEIGHT - 190), Vector2(WIDTH - 25, HEIGHT - 32))
	falcons[0] = Vector2(30, player.pos.y - 40 + sin(time * 2.2) * 18)
	falcons[1] = Vector2(570, player.pos.y - 40 - sin(time * 2.2) * 18)
	if input.get("surge", false) and surge >= 100.0 and (not tactician or turn_phase == "aim"):
		surge = 0.0
		surge_time = 4.0
		player.invincible = 1.2
		player.hp = minf(player.max_hp, player.hp + 6.0)
		for i in range(16):
			var element: String = "baby" if elements.is_empty() else elements[i % elements.size()]
			add_ball(player.pos, Vector2.from_angle(-PI + i / 16.0 * TAU), element, 1.5, false)
		if tactician:
			turn_phase = "volley"
			volley_released = true
		surge_count += 1
		emit("surge", {"pos": player.pos})
	if passives.has("protective_charm") and protective_charges == 0:
		protective_recharge = maxf(0, protective_recharge - field_delta)
		if protective_recharge <= 0: protective_charges = 1
	if passives.has("wretched_onion") and field_delta > 0:
		for enemy in RonkeEvolvedEffects.targets(self, player.pos, TILE * 2): damage(enemy, rng.randf_range(6, 12) * field_delta * area_multiplier(), false, "area")
	shot_clock -= delta
	var held: bool = input.get("shoot", false) or crew.id in ["radical", "itchy_finger"]
	if tactician:
		if turn_phase == "aim" and held and not shoot_was_held and can_shoot():
			shoot(aim, true)
			turn_phase = "volley"
			volley_released = true
	else:
		if held and shot_clock <= 0.0 and can_shoot():
			shoot(aim)
			shot_clock = maxf(0.05, stats.interval / (1.15 if passives.has("shortbow") else 1.0))
	shoot_was_held = held
	field_delta = delta if not tactician or turn_phase == "enemy" else 0.0
	var world_delta = field_delta * (0.55 if surge_time > 0.0 else 1.0)
	if tactician and turn_phase != "enemy":
		world_delta = 0.0
	if timestop_left > 0:
		timestop_left = maxf(0, timestop_left - delta)
		world_delta = 0.0
	world_time += world_delta
	wave_clock += world_delta
	_update_enemies(field_delta, world_delta)
	if _combat_interrupted(): return
	_update_hazards(field_delta)
	if _combat_interrupted(): return
	_update_seekers(field_delta)
	if _combat_interrupted(): return
	_update_allies(field_delta, world_delta)
	if _combat_interrupted(): return
	# A shot already touching its target has arrived before this step.
	# Resolve those contacts before future ball hits; moving shots can still be intercepted.
	for bullet in bullets: bullet.previous = bullet.pos
	_resolve_hostile_projectiles(world_delta)
	if _combat_interrupted(): return
	for bullet in bullets:
		if phase != "playing":
			break
		if bullet.dead:
			continue
		var bullet_start: Vector2 = bullet.pos
		bullet.previous = bullet_start
		bullet.pos += bullet.velocity * world_delta
		if bullet.get("ally", false):
			for enemy in enemies:
				if not enemy.dead and enemy.charm <= 0 and not RonkeCombatGeometry.sweep_circle_box(bullet_start, bullet.pos, bullet.radius, enemy.pos, enemy.width * 0.5).is_empty():
					damage(enemy, bullet.damage, false, "summon")
					bullet.dead = true
					break
			continue
	if not tactician or turn_phase != "enemy":
		for ball in balls.duplicate():
			if phase != "playing":
				break
			if not ball.dead:
				_update_ball(ball, delta)
	if tactician and turn_phase == "enemy":
		for ball in balls:
			ball.previous = ball.pos
			ball.motion_from = 0.0
			ball.motion_to = 1.0
			_intercept_ball_projectiles(ball)
	_resolve_hostile_projectiles(world_delta)
	balls = balls.filter(func(ball): return not ball.dead)
	enemies = enemies.filter(func(enemy): return not enemy.dead)
	bullets = bullets.filter(func(bullet): return not bullet.dead)
	if phase != "playing":
		return
	if tactician:
		if turn_phase == "volley" and balls.is_empty():
			turn_phase = "enemy"
			enemy_turn_left = 0.4
		elif turn_phase == "enemy":
			enemy_turn_left -= world_delta
			if enemy_turn_left <= 0:
				turn_phase = "aim"
	if practice:
		if enemies.is_empty():
			_spawn_practice_targets()
		return
	if enemies.is_empty():
		clear_clock += delta
		if clear_clock > 1.6:
			if wave == LAST_WAVE:
				finish(true)
			else:
				spawn_wave()
	elif crew.id != "tactician" and wave_clock > 17.0 and wave < LAST_WAVE and enemies.size() < 46:
		spawn_wave()

func _resolve_hostile_projectiles(world_delta: float) -> void:
	for bullet in bullets:
		if phase != "playing": break
		if bullet.dead or bullet.get("ally", false): continue
		var bullet_start: Vector2 = bullet.get("previous", bullet.pos)
		for ally in allies:
			if not ally.dead and RonkeCombatGeometry.segment_circle(bullet_start, bullet.pos, ally.pos, ally.radius + bullet.radius):
				ally.hp -= bullet.damage
				ally.dead = ally.hp <= 0
				bullet.dead = true
				break
		if bullet.dead: continue
		if world_delta > 0 and RonkeCombatGeometry.segment_circle(bullet_start, bullet.pos, player.pos, 22.0 + bullet.radius):
			if passives.has("hand_mirror") and rng.randf() < 0.5:
				bullet.ally = true
				bullet.velocity = -bullet.velocity
				bullet.damage = rng.randf_range(20, 40)
			elif passives.has("lovers_quiver") and rng.randf() < 0.4:
				heal(1)
				bullet.dead = true
			else:
				hurt(bullet.damage, "projectile")
				bullet.dead = true
		if bullet.pos.y > HEIGHT + 20 or bullet.pos.y < 0 or bullet.pos.x < 0 or bullet.pos.x > WIDTH:
			bullet.dead = true
func _combat_interrupted() -> bool:
	if phase == "playing": return false
	_prune_balls()
	enemies = enemies.filter(func(enemy): return not enemy.dead)
	bullets = bullets.filter(func(bullet): return not bullet.dead)
	allies = allies.filter(func(ally): return not ally.dead)
	return true

func _update_enemies(delta: float, world_delta: float) -> void:
	for enemy in enemies:
		if phase != "playing":
			break
		if enemy.dead:
			continue
		enemy.flash = maxf(0.0, enemy.flash - delta)
		var status_delta = delta
		_tick_statuses(enemy, status_delta)
		if enemy.dead:
			continue
		var movement_delta = 0.0 if enemy.freeze > 0 or enemy.get("petrify", 0) > 0 else world_delta
		var step_speed: float = TILE / 0.4 if crew.id == "tactician" and not practice else enemy.speed
		if enemy.charm > 0:
			enemy.pos.y = maxf(20, enemy.pos.y - step_speed * movement_delta)
			enemy.charm_attack -= movement_delta
			if enemy.charm_attack <= 0:
				enemy.charm_attack = 0.75
				var target = nearest_enemy(enemy.pos, enemy.id, true)
				if not target.is_empty():
					bullets.append({"pos": enemy.pos, "velocity": (target.pos - enemy.pos).normalized() * 145.0, "radius": 5.0, "damage": 10.0, "dead": false, "ally": true})
			continue
		var blocked = allies.any(func(ally): return not ally.dead and ally.pos.distance_to(enemy.pos) <= ally.radius + enemy.width * 0.5)
		enemy.pos.y += (0.0 if blocked else 1.0) * step_speed * movement_delta * (0.5 if passives.has("hand_fan") and absf(enemy.pos.x - player.pos.x) <= TILE * 0.5 else 1.0) * (0.5 if enemy.get("strong_slow", 0) > 0 else 0.7 if enemy.slow > 0 else 1.0)
		if enemy.kind == "boss":
			if movement_delta > 0:
				enemy.pos.x = 300 + sin(world_time * 0.65) * 140
			if enemy.boss_phase == 1 and enemy.hp <= enemy.max_hp * 0.5:
				enemy.boss_phase = 2
				emit("boss_phase", {"pos": enemy.pos, "guardian": enemy.guardian})
		if enemy.pos.y + enemy.width / 2.0 > HEIGHT - 120:
			breach_count += 1
			if enemy.kind == "boss":
				player.hp = 0.0
				finish(false, "guardian_breach")
			else:
				hurt(10.0, "breach")
			enemy.dead = true
			emit("breach", {"pos": enemy.pos})
			continue
		if enemy.kind not in ["prism", "boss", "miniboss"]:
			continue
		if enemy.freeze > 0 or enemy.get("petrify", 0) > 0:
			continue
		if crew.id == "tiptoer" and enemy.kind not in ["boss", "miniboss"]:
			enemy.charging = false
			continue
		enemy.fire -= world_delta
		var windup = attack_windup(enemy)
		if enemy.fire <= windup and not enemy.charging:
			enemy.charging = true
			enemy.attack_phase = enemy.boss_phase
			enemy.attack_pattern = "root_spread" if enemy.guardian == "rootheart" and enemy.volley % 2 == 0 else "root_aim" if enemy.guardian == "rootheart" else "gate_fan"
			enemy.attack_angle = PI / 2 if enemy.attack_pattern == "root_spread" else (player.pos - enemy.pos).angle() + (rng.randf() - 0.5) * 0.12
			enemy.blind_miss = enemy.blind > 0 and rng.randf() < 0.5
			if enemy.blind_miss:
				enemy.attack_angle += (0.65 if rng.randf() < 0.5 else -0.65)
			emit("windup", {"pos": enemy.pos})
		if enemy.fire <= 0:
			if enemy.get("lovestruck", 0) > 0:
				var p = effect_parameters(enemy, "lovestruck", "lovestruck")
				if rng.randf() < float(p.chance): heal(p.heal)
			for direction in attack_directions(enemy):
				bullets.append({"pos": enemy.pos, "velocity": direction * 145.0, "radius": 7.0 if enemy.kind == "boss" else 5.0,
					"damage": (5.0 if enemy.weak > 0 else 10.0) * float(enemy.get("attack_scale", 1.0)), "dead": false, "ally": false})
			enemy.volley += 1
			enemy.fire = (1.7 if enemy.boss_phase == 2 else 1.9) if enemy.guardian == "rootheart" else 1.5 if enemy.kind == "boss" else 4.5
			enemy.charging = false

func attack_windup(enemy: Dictionary) -> float:
	return 0.95 if enemy.guardian == "rootheart" else BOSS_WINDUP if enemy.kind == "boss" else PRISM_WINDUP

func attack_directions(enemy: Dictionary) -> Array[Vector2]:
	# A volley snapshots phase/pattern at charge start. Crossing half health
	# cannot change already-displayed lanes before the projectiles are released.
	var result: Array[Vector2] = []
	var count = 1
	var spacing = 0.21
	if enemy.kind == "boss":
		var enraged: bool = enemy.attack_phase == 2
		match enemy.attack_pattern:
			"root_spread":
				count = 7 if enraged else 5
				spacing = 0.20 if enraged else 0.24
			"root_aim":
				count = 5 if enraged else 3
				spacing = 0.17
			_:
				count = 5 if enraged else 3
				spacing = 0.16 if enraged else 0.21
	for i in range(count):
		result.append(Vector2.from_angle(enemy.attack_angle + (i - (count - 1) / 2.0) * spacing))
	return result

func _update_ball(ball: Dictionary, delta: float) -> void:
	if ball.dead or delta < 0 or not is_finite(delta): return
	var travel: float = minf(2400.0, ball.velocity.length() + 165.0 * delta) * delta
	var segments = maxi(1, ceili(travel / maxf(1.0, ball.radius)))
	for _i in range(segments):
		if ball.dead or phase != "playing": break
		ball.motion_from = float(_i) / segments
		ball.motion_to = float(_i + 1) / segments
		_move_ball_segment(ball, delta / segments)
		if not ball.dead and ball.air_time <= 0: _record_ball_trail(ball)

func _move_ball_segment(ball: Dictionary, delta: float) -> void:
	if is_finite(float(ball.life)):
		ball.life -= delta
		if ball.life <= 0:
			return_ball(ball)
			return
	RonkeEvolvedEffects.tick_ball(self, ball, delta)
	ball.shield_cooldown = maxf(0, ball.shield_cooldown - delta)
	ball.previous = ball.pos
	if ball.air_time > 0:
		var airborne_delta: float = minf(delta, ball.air_time)
		ball.air_time = maxf(0, ball.air_time - delta)
		delta -= airborne_delta
		var progress = 1.0 - ball.air_time / maxf(ball.air_duration, 0.001)
		ball.pos = ball.lob_from.lerp(ball.lob_target, progress)
		if ball.air_time > 0:
			return
		ball.pos = ball.lob_target
		ball.previous = ball.pos
		ball.trail = [ball.pos]
	if ball.orbit:
		ball.orbit_time += delta
		ball.pos = (player.pos + Vector2(cos(ball.orbit_time * 9 + ball.angle) * 46, sin(ball.orbit_time * 9 + ball.angle) * 30)).clamp(Vector2(WALL_LEFT + ball.radius, WALL_TOP + ball.radius), Vector2(WALL_RIGHT - ball.radius, WALL_BOTTOM - ball.radius))
		if ball.orbit_time >= float(character_profile.orbit_seconds):
			return_ball(ball, true)
			return
	elif ball.returning:
		var toward: Vector2 = player.pos - ball.pos
		ball.velocity = toward.normalized() * 900.0
		if toward.length() <= 24.0 + 900.0 * delta:
			return_ball(ball, true)
			return
		ball.pos += ball.velocity * delta
	else:
		if crew.id == "physicist":
			ball.velocity.y -= float(character_profile.gravity) * delta
		# Speed is bounded for numerical stability; casts still use 120 Hz substeps.
		ball.velocity = ball.velocity.limit_length(2400.0)
		ball.pos += ball.velocity * delta
		if ball.pos.x < WALL_LEFT + ball.radius:
			ball.pos.x = WALL_LEFT + ball.radius
			ball.velocity.x = absf(ball.velocity.x)
			wall(ball)
			if ball.dead: return
		elif ball.pos.x > WALL_RIGHT - ball.radius:
			ball.pos.x = WALL_RIGHT - ball.radius
			ball.velocity.x = -absf(ball.velocity.x)
			wall(ball)
			if ball.dead: return
		if ball.pos.y < WALL_TOP + ball.radius:
			ball.far_wall = true
			if ball.element == "drill": ball.pierce = 0
			if crew.id == "tunneller":
				ball.pos.y = WALL_BOTTOM - ball.radius
				ball.previous = ball.pos
				ball.trail = [ball.pos]
				ball.contacts = []
				ball.wraps += 1
			elif crew.id == "repentant":
				ball.pos.y = WALL_TOP + ball.radius
				wall(ball)
				ball.returning = true
				ball.hits.clear()
			else:
				ball.pos.y = WALL_TOP + ball.radius
				ball.velocity.y = absf(ball.velocity.y)
				wall(ball)
		if ball.dead: return
		var shield_y: float = player.pos.y - 32
		if crew.id == "shieldbearer" and ball.velocity.y > 0 and ball.shield_cooldown <= 0 and absf(ball.pos.x - player.pos.x) <= 58 and ball.previous.y <= shield_y + ball.radius and ball.pos.y >= shield_y - ball.radius:
			ball.pos.y = shield_y - ball.radius - 1
			ball.velocity.y = -absf(ball.velocity.y)
			ball.shield_catches += 1
			ball.shield = true
			ball.shield_cooldown = 0.08
			_bounce_bonus(ball)
			RonkeEvolvedEffects.on_bounce(self, ball)
			emit("shield", {"pos": ball.pos})
		if crew.id == "carouser" and ball.velocity.y > 0 and ball.pos.distance_to(player.pos) < 80:
			ball.orbit = true
			ball.orbit_time = 0.0
			ball.angle = (ball.pos - player.pos).angle()
		elif ball.velocity.y > 0 and ball.pos.distance_to(player.pos) < 24 + (TILE if passives.has("magnet") else 0):
			return_ball(ball, true)
			return
		if ball.pos.y > WALL_BOTTOM - ball.radius:
			if crew.id == "flagellant":
				ball.pos.y = WALL_BOTTOM - ball.radius
				ball.velocity.y = -absf(ball.velocity.y)
				wall(ball)
				if ball.dead: return
			elif crew.id == "tunneller":
				ball.pos.y = WALL_TOP + ball.radius
				ball.previous = ball.pos
				ball.trail = [ball.pos]
				ball.contacts = []
				ball.wraps += 1
			else:
				return_ball(ball)
				return
	_intercept_ball_projectiles(ball)
	if ball.manual_recall:
		return
	var contacts: Array = []
	var current_contacts: Array = []
	var bounds = Rect2(ball.previous, ball.pos - ball.previous).abs().grow(ball.radius)
	for enemy in enemies:
		if enemy.dead or enemy.get("pending_death", false) or (enemy.charm > 0 and ball.element != "succubus"): continue
		if not bounds.intersects(Rect2(enemy.pos - Vector2.ONE * enemy.width * 0.5, Vector2.ONE * enemy.width), true): continue
		var collision = RonkeCombatGeometry.sweep_circle_box(ball.previous, ball.pos, ball.radius, enemy.pos, enemy.width * 0.5)
		if collision.is_empty(): continue
		if RonkeCombatGeometry.circle_box_overlap(ball.pos, ball.radius, enemy.pos, enemy.width * 0.5): current_contacts.append(enemy.id)
		if ball.contacts.has(enemy.id) and RonkeCombatGeometry.circle_box_overlap(ball.previous, ball.radius, enemy.pos, enemy.width * 0.5): continue
		contacts.append({"enemy": enemy, "collision": collision})
	contacts.sort_custom(func(a, b): return a.collision.fraction < b.collision.fraction)
	for contact in contacts:
		var enemy: Dictionary = contact.enemy
		if enemy.dead or ball.dead: continue
		if ball.hits.size() >= 64: ball.hits.clear()
		ball.hits[enemy.id] = time
		hit(enemy, ball)
		if ball.dead: break
		if ball.element == "warp": break
		if ball.element == "assassin" and ball.velocity.y < 0: continue
		if ball.returning or ball.embedded_pierce or ball.pierce < 0 or ball.orbit: continue
		if ball.pierce > 0:
			ball.pierce -= 1
			continue
		var normal: Vector2 = contact.collision.normal
		if ball.velocity.dot(normal) < 0:
			ball.velocity = ball.velocity.bounce(normal)
			_bounce_bonus(ball)
			RonkeEvolvedEffects.on_bounce(self, ball)
		ball.pos = contact.collision.pos + normal * 0.01
		break
	ball.contacts = current_contacts

func _intercept_ball_projectiles(ball: Dictionary) -> void:
	if ball.dead or ball.manual_recall or ball.air_time > 0: return
	for bullet in bullets:
		if bullet.dead or bullet.get("ally", false) or bullet.get("unblockable", false): continue
		var start: Vector2 = bullet.get("previous", bullet.pos)
		var bullet_from = start.lerp(bullet.pos, float(ball.get("motion_from", 0.0)))
		var bullet_to = start.lerp(bullet.pos, float(ball.get("motion_to", 1.0)))
		var contact = RonkeCombatGeometry.moving_circles(ball.previous, ball.pos, bullet_from, bullet_to, ball.radius + bullet.radius)
		if contact.is_empty(): continue
		bullet.dead = true
		ball.pos = ball.previous.lerp(ball.pos, contact.fraction)
		var normal: Vector2 = contact.normal
		if ball.velocity.dot(normal) < 0: ball.velocity = ball.velocity.bounce(normal)
		_bounce_bonus(ball)
		RonkeEvolvedEffects.on_bounce(self, ball)
		emit("shield", {"pos": ball.pos})

func _record_ball_trail(ball: Dictionary, force: bool = false) -> void:
	if ball.air_time > 0: return
	if not ball.has("trail"): ball.trail = [ball.pos]
	var points: Array = ball.trail
	if points.is_empty() or force or ball.pos.distance_to(points.back()) >= 2.0:
		points.append(ball.pos)
	while points.size() > 8: points.pop_front()
	while points.size() > 2 and _trail_length(points) > 32.0: points.pop_front()

func _trail_length(points: Array) -> float:
	var distance = 0.0
	for i in range(1, points.size()): distance += points[i - 1].distance_to(points[i])
	return distance

func _bounce_bonus(ball: Dictionary) -> void:
	if crew.id == "repentant":
		ball.damage *= 1.05
	if ball.element in ["flesh", "fleshy_baby"]:
		ball.velocity *= 1.0 + float(ball.parameters.get("bounce_speed", 0.25))


func shoot(aim: Vector2, full_volley: bool = false) -> void:
	if not available or phase != "playing":
		return
	_prune_balls()
	var ready = ready_specials()
	var all_specials = full_volley or crew.id == "spendthrift"
	var selected: Array = ready if all_specials else ([ready[shot_count % ready.size()]] if not ready.is_empty() else [])
	var origin: Vector2 = player.pos + Vector2(0, -28)
	if crew.id == "shade":
		origin.y = 35
	var target: Vector2 = aim
	target.y = maxf(100, aim.y) if crew.id == "shade" else minf(origin.y - 35, aim.y)
	var angle = (target - origin).angle()
	if crew.id == "itchy_finger":
		angle += rng.randf_range(-0.12, 0.12)
	var fired = false
	for i in range(selected.size()):
		var element: String = selected[i]
		var fan_angle = angle + (i - (selected.size() - 1) * 0.5) * 0.18 if all_specials else angle
		var copies = 2 if crew.id in ["cohabitants", "falconer"] else maxi(int(stats.instances), elements.size()) if crew.id == "empty_nester" else 1
		if crew.id == "empty_nester":
			copies = maxi(0, copies - _active_special_count())
		if copies <= 0 or balls.size() + copies > MAX_BALLS:
			continue
		next_id += 1
		var group_id = next_id
		launch_groups[group_id] = {"element": element, "remaining": 0}
		special_inflight[element] = int(special_inflight.get(element, 0)) + 1
		special_cooldowns[element] = ball_cooldown(element)
		var launched_copies: Array = []
		for copy in range(copies):
			var source = falcons[copy] if crew.id == "falconer" else origin
			var direction = Vector2.from_angle(fan_angle)
			if crew.id == "falconer":
				direction = (target - source).normalized()
			elif crew.id == "cohabitants" and copy == 1:
				direction.x = -direction.x
			elif crew.id == "empty_nester":
				direction = Vector2.from_angle(fan_angle + (copy - (copies - 1) * 0.5) * 0.06)
			add_ball(source, direction, element, 0.5 if crew.id == "cohabitants" else 1.0, false, group_id)
			var launched: Dictionary = balls.back()
			launched_copies.append(launched)
			if crew.id == "juggler":
				launched.air_time = 0.55
				launched.air_duration = 0.55
				launched.lob_from = source
				launched.lob_target = Vector2(clampf(aim.x, 45, WIDTH - 45), clampf(aim.y, 80, HEIGHT - 220))
		for launched in launched_copies: RonkeEvolvedEffects.on_launch(self, launched)
		fired = true
	var babies = player.ammo if full_volley or crew.id == "spendthrift" else mini(1, player.ammo)
	if crew.id not in ["empty_nester", "makeshift_sisyphus"]:
		for i in range(babies):
			var copies = 2 if crew.id in ["cohabitants", "falconer"] else 1
			if balls.size() + copies > MAX_BALLS:
				break
			player.ammo -= 1
			for copy in range(copies):
				var source: Vector2 = falcons[copy] if crew.id == "falconer" else origin
				var direction = Vector2.from_angle(angle + (i - (babies - 1) * 0.5) * 0.07)
				if crew.id == "cohabitants" and copy == 1:
					direction.x = -direction.x
				if crew.id == "falconer":
					direction = (target - source).normalized()
				add_ball(source, direction, "baby", 0.5 if crew.id == "cohabitants" else 1.0, copy == 0)
				if crew.id == "juggler":
					var launched: Dictionary = balls.back()
					launched.air_time = 0.55
					launched.air_duration = 0.55
					launched.lob_from = source
					launched.lob_target = Vector2(clampf(aim.x, 45, WIDTH - 45), clampf(aim.y, 80, HEIGHT - 220))
			fired = true
	if fired:
		player.shoot = 0.21
		shot_count += 1
		emit("shot", {"pos": origin, "element": str(selected[0]) if not selected.is_empty() else "baby"})

func _prune_balls() -> void:
	balls = balls.filter(func(ball): return not ball.dead)

func add_ball(pos: Vector2, direction: Vector2, element: String, multiplier: float = 1.0, refundable: bool = true, group_id: int = 0) -> Dictionary:
	_prune_balls()
	if not pos.is_finite() or not direction.is_finite() or balls.size() >= MAX_BALLS :
		rejected_spawns.ball += 1
		return {}
	next_id += 1
	var parameters = RonkeBallRules.parameters(element, int(element_levels.get(element, 1)))
	var speed = 560.0 * float(parameters.get("speed", 2.0 if element in ["iron_pellet", "sniper_pellet"] else 1.0))
	var power = float(parameters.get("impact", 2.0 if element == "iron_pellet" else 0.5 if element == "fleshy_baby" else 3.0 if element == "stone_pellet" else 1.0))
	var impact = 15.0 * stats.damage * multiplier * power
	var ball = {"id": next_id, "pos": pos, "previous": pos, "velocity": direction.normalized() * speed,
		"radius": RonkeBallRules.geometry(element, TILE), "element": element, "parameters": parameters, "level": int(element_levels.get(element, 1)), "damage": impact, "launch_damage": impact,
		"pierce": -1 if element in ["ghost", "wind", "wraith", "noxious", "sandstorm", "soul_sucker", "erosion", "sniper", "sniper_pellet", "drill"] else 0, "embedded_pierce": crew.id == "embedded",
		"life": INF, "refundable": refundable, "group": group_id, "wraps": 0, "shield": false, "shield_catches": 0,
		"shield_cooldown": 0.0, "orbit": false, "orbit_time": 0.0, "angle": 0.0, "returning": false, "manual_recall": false,
		"air_time": 0.0, "air_duration": 0.0, "lob_from": pos, "lob_target": pos,
		"trail": [pos], "hits": {}, "contacts": [], "bounces": 0, "child": element in ["baby", "fleshy_baby", "iron_pellet", "stone_pellet", "sniper_pellet"], "clone_depth": 0, "stone_scale": power, "next_hit_bonus": 0.0,
		"pulse": float(parameters.get("interval", 1.0)), "far_wall": false, "fragile": element in ["iron_pellet", "stone_pellet", "sniper_pellet"], "dead": false}
	balls.append(ball)
	if group_id > 0 and launch_groups.has(group_id): launch_groups[group_id].remaining += 1
	return ball

func wall(ball: Dictionary) -> void:
	_record_ball_trail(ball, true)
	bounces += 1
	ball.bounces += 1
	ball.embedded_pierce = false
	if ball.fragile:
		return_ball(ball)
		return
	_bounce_bonus(ball)
	RonkeEvolvedEffects.on_bounce(self, ball, true)
	if stats.bounce > 0:
		ball.next_hit_bonus += stats.bounce
	if passives.has("wagon_wheel"):
		ball.next_hit_bonus = maxf(ball.next_hit_bonus, 0.30 * int(passive_levels.get("wagon_wheel", 1)))
	emit("bounce", {"pos": ball.pos, "color": RonkeData.orb_color(ball.element)})

func return_ball(ball: Dictionary, caught: bool = false) -> void:
	if ball.dead:
		return
	ball.dead = true
	if caught and not ball.child and passives.has("bottled_tornado"):
		for _i in range(rng.randi_range(1, 3)): spawn_baby(player.pos, Vector2.from_angle(rng.randf() * TAU))
	var group_id: int = ball.get("group", 0)
	if group_id > 0 and launch_groups.has(group_id):
		launch_groups[group_id].remaining -= 1
		if launch_groups[group_id].remaining <= 0:
			var element: String = launch_groups[group_id].element
			special_inflight[element] = maxi(0, int(special_inflight.get(element, 0)) - 1)
			launch_groups.erase(group_id)
	elif ball.refundable:
		player.ammo = mini(player.capacity, player.ammo + 1)

func hit(enemy: Dictionary, ball: Dictionary) -> void:
	if enemy.dead or ball.dead:
		return
	if enemy.charm > 0:
		if ball.element == "succubus": heal(1)
		return
	hit_depth += 1
	if ball.element == "maggot":
		enemy.infested = true
		remember_effect(enemy, "maggot", ball.parameters)
	if ball.element == "zombie":
		enemy.zombie_infected = true
		remember_effect(enemy, "zombie", ball.parameters)
	if enemy.has("curse_hits"):
		enemy.curse_hits -= 1
		if enemy.curse_hits <= 0:
			var burst: float = enemy.curse_power
			enemy.erase("curse_hits")
			damage(enemy, burst, false, "status")
	if enemy.bleed_stacks > 0:
		damage(enemy, float(enemy.bleed_stacks) * status_multiplier(), false, "status")
	var value: float = ball.damage * (1.0 + ball.shield_catches) * (1.0 + ball.next_hit_bonus)
	ball.next_hit_bonus = 0.0
	if ball.element == "stone":
		value *= ball.stone_scale / float(ball.parameters.get("impact", 3.0))
		ball.stone_scale = maxf(float(ball.parameters.get("floor", 0.5)), ball.stone_scale * (1.0 - float(ball.parameters.get("erosion", 0.4))))
	if ball.element == "steel":
		value *= float(ball.get("steel_scale", 2.0)) / float(ball.parameters.get("impact", 2.0))
		ball.steel_scale = minf(float(ball.parameters.get("ceiling", 3.0)), float(ball.get("steel_scale", 2.0)) + float(ball.parameters.get("growth", 0.1)))
	if ball.element == "assassin" and ball.velocity.y > 0: value *= 1.0 + float(ball.parameters.get("back_bonus", 0.3))
	if ball.element == "drill" and not ball.far_wall: value *= 1.0 + float(ball.parameters.get("impact_bonus", 0.5))
	if passives.has("war_horn") and ball.child: value *= 1.2
	if passives.has("platinum_dumbbell") and not ball.far_wall: value *= 1.12
	if passives.has("silver_bullet") and ball.bounces == 0: value *= 1.2
	var crit: bool = rng.randf() < stats.crit
	if crit:
		value *= 2.0
	if crew.id != "makeshift_sisyphus":
		damage(enemy, value, crit, "impact")
	RonkeBallEffects.on_hit(self, enemy, ball, value)
	RonkeEvolvedEffects.on_hit(self, enemy, ball)
	if ball.fragile and ball.element != "sniper_pellet": return_ball(ball)
	hit_depth -= 1
	_flush_deaths()
	emit("hit", {"pos": ball.pos, "color": RonkeData.orb_color(ball.element), "crit": crit})

func damage(enemy: Dictionary, value: float, crit: bool = false, category: String = "impact") -> void:
	if enemy.dead or enemy.get("pending_death", false) or value <= 0:
		return
	if category == "impact" and crew.id == "makeshift_sisyphus":
		return
	var vulnerability: float = 1.25 if enemy.freeze > 0 or enemy.get("frostburn", 0) > 0 else 1.0
	var final_value = value * vulnerability * (1.0 + 0.1 * int(enemy.get("radiation_stacks", 0)))
	enemy.hp -= final_value
	enemy.flash = 0.08
	emit("damage", {"pos": enemy.pos, "value": roundi(final_value), "crit": crit})
	if enemy.hp <= 0:
		kill(enemy)

func splash(pos: Vector2, radius: float, value: float) -> void:
	for enemy in enemies:
		if not enemy.dead and enemy.charm <= 0 and enemy.pos.distance_to(pos) < radius + enemy.width * 0.3:
			damage(enemy, value * area_multiplier(), false, "area")
	emit("splash", {"pos": pos, "radius": radius})

func _flush_deaths() -> void:
	if hit_depth > 0: return
	var deaths = pending_deaths
	pending_deaths = []
	for enemy in deaths:
		enemy.pending_death = false
		kill(enemy)

func kill(enemy: Dictionary) -> void:
	if enemy.dead or enemy.get("pending_death", false): return
	if hit_depth > 0:
		enemy.pending_death = true
		pending_deaths.append(enemy)
		return
	if enemy.dead:
		return
	enemy.dead = true
	if enemy.get("infested", false):
		for _i in range(rng.randi_range(int(effect_parameters(enemy, "maggot", "maggot").count_min), int(effect_parameters(enemy, "maggot", "maggot").count_max))): spawn_baby(enemy.pos, Vector2.from_angle(rng.randf() * TAU))
	if enemy.get("zombie_infected", false) and enemy.kind not in ["boss", "miniboss"] and rng.randf() < float(effect_parameters(enemy, "zombie", "zombie").chance):
		spawn_ally(enemy)
	kills += 1
	if enemy.kind == "boss":
		guardians_defeated += 1
	combo += 1
	combo_time = 1.8
	best_combo = maxi(best_combo, combo)
	surge = clampf(surge + (30 if enemy.kind == "boss" else 5), 0, 100)
	if practice:
		emit("kill", {"pos": enemy.pos, "kind": enemy.kind})
		return
	xp += 12 if enemy.kind == "boss" else 3 if enemy.kind == "granite" else 2
	emit("kill", {"pos": enemy.pos, "kind": enemy.kind})
	check_level()

func check_level() -> void:
	if phase != "playing" or xp < xp_needed:
		return
	xp -= xp_needed
	level += 1
	xp_needed = 8 + level * 4
	phase = "upgrade"
	upgrade_clock = 0.0
	choices = get_choices()
	emit("level", {"level": level})

func get_choices() -> Array:
	var pool: Array = []
	for upgrade in RonkeData.all().upgrades:
		if upgrade.has("element"):
			var element: String = upgrade.element
			if elements.has(element):
				if int(element_levels.get(element, 1)) < 3:
					var leveled: Dictionary = upgrade.duplicate()
					leveled.name = "%s / Level %d" % [upgrade.name, int(element_levels.get(element, 1)) + 1]
					leveled.description = RonkeBallRules.upgrade_description(element, int(element_levels.get(element, 1)))
					leveled.kind = "BALL LEVEL"
					leveled.level_ball = true
					pool.append(leveled)
			elif not upgrade.get("level_only", false) and elements.size() < special_slots:
				pool.append(upgrade.duplicate())
		else:
			if upgrade.id != "capacity" or player.capacity > 0:
				pool.append(upgrade.duplicate())
	for id in RonkeData.all().passives:
		var data: Dictionary = RonkeData.all().passives[id]
		if (passives.has(id) and int(passive_levels.get(id, 1)) < int(data.max_level)) or (not passives.has(id) and passives.size() < passive_slots):
			pool.append({"id": "passive_" + id, "passive": id, "name": data.name, "description": data.description, "kind": "PASSIVE", "icon": "+"})
	var evolutions: Array = []
	var offered_evolutions: Dictionary = {}
	for recipe in RonkeData.all().fusions:
		var ready = true
		for ingredient in recipe.ingredients:
			if not elements.has(ingredient) or int(element_levels.get(ingredient, 1)) < 3:
				ready = false
		if ready and not elements.has(recipe.id) and not offered_evolutions.has(recipe.id):
			offered_evolutions[recipe.id] = true
			evolutions.append({"id": "fusion_" + recipe.id, "name": recipe.name, "description": RonkeData.all().elements[recipe.id].description,
				"icon": "*", "kind": "EVOLUTION", "fusion": recipe.id, "ingredients": recipe.ingredients.duplicate()})
	for i in range(pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var item = pool[i]
		pool[i] = pool[j]
		pool[j] = item
	evolutions.sort_custom(func(a, b): return a.ingredients.size() > b.ingredients.size())
	for i in range(evolutions.size() - 1, -1, -1):
		pool.push_front(evolutions[i])
	return pool.slice(0, 3)

func choose_upgrade(index: int) -> bool:
	if phase != "upgrade" or index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	match choice.id:
		"power": stats.damage *= 1.22
		"haste": stats.interval = maxf(0.08, stats.interval * 0.82)
		"capacity":
			player.capacity += 2
			player.ammo = mini(maxi(0, player.capacity - _refundable_count()), player.ammo + 2)
		"vitality":
			player.max_hp += 20.0
			player.hp = minf(player.max_hp, player.hp + 30)
		"ricochet": stats.bounce += 0.1
		"speed":
			stats.speed = minf(440, stats.speed * 1.15)
			player.dash_cd = maxf(0, player.dash_cd - 0.75)
	if choice.has("element"):
		if elements.has(choice.element):
			element_levels[choice.element] = mini(3, int(element_levels.get(choice.element, 1)) + 1)
		elif elements.size() < special_slots:
			elements.append(choice.element)
			element_levels[choice.element] = 1
	if choice.has("passive"):
		var id: String = choice.passive
		if passives.has(id):
			passive_levels[id] = int(passive_levels.get(id, 1)) + 1
		elif passives.size() < passive_slots:
			passives.append(id)
			passive_levels[id] = 1
		if id == "protective_charm":
			protective_charges += 1
	if choice.has("fusion"):
		for fusion in RonkeData.all().fusions:
			if fusion.id == choice.fusion and fusion.ingredients.all(func(id): return elements.has(id) and int(element_levels.get(id, 1)) >= 3):
				for ingredient in fusion.ingredients:
					elements.erase(ingredient)
					element_levels.erase(ingredient)
				elements.append(fusion.id)
				element_levels[fusion.id] = 1
				break
	picks.append(choice.name)
	choices = []
	phase = "playing"
	emit("upgrade", {"name": choice.name})
	check_level()
	return true

func hurt(value: float, source: String = "impact") -> void:
	if practice or value <= 0 or player.invincible > 0 or phase in ["victory", "defeat"]:
		return
	if passives.has("eye_of_the_beholder") and rng.randf() < 0.1:
		emit("shield", {"pos": player.pos})
		return
	if protective_charges > 0:
		protective_charges -= 1
		protective_recharge = 60.0
		emit("shield", {"pos": player.pos})
		return
	if passives.has("crown_of_thorns") and source in ["impact", "breach"]:
		var close = enemies.filter(func(enemy): return not enemy.dead and enemy.kind not in ["boss", "miniboss"])
		close.sort_custom(func(a, b): return a.pos.distance_squared_to(player.pos) < b.pos.distance_squared_to(player.pos))
		for enemy in close.slice(0, 2):
			kill(enemy)
	if passives.has("breastplate"): value *= 0.9
	damage_taken += minf(player.hp, value)
	player.hp = maxf(0, player.hp - value)
	player.hurt = 0.4
	player.invincible = 0.85
	emit("hurt", {"pos": player.pos, "value": value})
	if player.hp <= 0:
		finish(false, source)

func finish(win: bool, reason: String = "defeated") -> void:
	if phase in ["victory", "defeat"]:
		return
	phase = "victory" if win else "defeat"
	end_reason = "victory" if win else reason
	reward = 0 if practice else floori(kills * 0.45 + wave * 2 + (30 if win else 0))
	emit("end", {"win": win, "reward": reward})

func report() -> Dictionary:
	return {"crew": crew.id, "world": world, "wave": wave, "time": time,
		"kills": kills, "guardians": guardians_defeated, "reward": reward,
		"shots": shot_count, "dashes": dash_count, "surges": surge_count,
		"breaches": breach_count, "damage_taken": damage_taken, "combo": best_combo,
		"bounces": bounces, "win": phase == "victory", "reason": end_reason,
		"elements": elements.duplicate(), "picks": picks.duplicate()}

func nearest_threat() -> Dictionary:
	var result: Dictionary = {}
	var furthest = -10000.0
	for enemy in enemies:
		if not enemy.dead and enemy.pos.y > furthest:
			result = enemy
			furthest = enemy.pos.y
	return result

func ready_specials() -> Array:
	var ready: Array = []
	for element in elements:
		if (crew.id == "empty_nester" and _active_special_count() < maxi(int(stats.instances), elements.size())) or (crew.id != "empty_nester" and int(special_inflight.get(element, 0)) == 0 and float(special_cooldowns.get(element, 0)) <= 0):
			ready.append(element)
	return ready

func can_shoot() -> bool:
	return available and phase == "playing" and balls.size() < MAX_BALLS and (player.ammo > 0 or not ready_specials().is_empty())

func _active_special_count() -> int:
	var count = 0
	for ball in balls:
		if not ball.dead and ball.group > 0:
			count += 1
	return count

func ball_cooldown(element: String) -> float:
	return 0.0 if crew.id == "empty_nester" else float(RonkeBallRules.parameters(element, int(element_levels.get(element, 1))).get("cooldown", 0.0))

func _refundable_count() -> int:
	return balls.filter(func(ball): return not ball.dead and ball.refundable).size()

func recall_balls() -> void:
	for ball in balls:
		if not ball.dead:
			ball.orbit = false
			ball.air_time = 0.0
			ball.returning = true
			ball.manual_recall = true
	emit("recall", {"pos": player.pos})

func spawn_baby(pos: Vector2, direction: Vector2) -> void:
	add_ball(pos, direction, "baby", 1.0, false)

func area_multiplier() -> float:
	return stats.damage * stats.area * (1.2 if passives.has("magic_staff") else 1.0) * (4.0 if crew.id == "makeshift_sisyphus" else 1.0)

func status_multiplier() -> float:
	return stats.status * (4.0 if crew.id == "makeshift_sisyphus" else 1.0)

func heal(value: float) -> void:
	var previous: float = player.hp
	player.hp = minf(player.max_hp, player.hp + maxf(0.0, value))
	if player.hp > previous and passives.has("bandage_roll"):
		for _i in range(rng.randi_range(1, 2)): spawn_baby(player.pos, Vector2.from_angle(rng.randf() * TAU))

func apply_status(enemy: Dictionary, kind: String, duration: float, dps: float = 0.0, limit: int = 1, parameters: Dictionary = {}) -> void:
	if enemy.dead:
		return
	if kind in ["burn", "poison", "disease", "venom", "frostburn", "darkflame", "radiation"]:
		if not enemy.statuses.has(kind):
			enemy.statuses[kind] = []
		var stacks: Array = enemy.statuses[kind]
		if stacks.size() >= limit:
			stacks.pop_front()
		while stacks.size() >= maxi(1, limit): stacks.pop_front()
		stacks.append({"life": duration, "dps": dps * status_multiplier(), "parameters": parameters.duplicate(true)})
		enemy[kind + "_stacks"] = stacks.size()
		enemy[kind] = duration
	else:
		enemy[kind] = maxf(float(enemy.get(kind, 0.0)), duration)
		if kind == "charm":
			enemy.charging = false

func _tick_statuses(enemy: Dictionary, delta: float) -> void:
	for key in ["strong_slow", "freeze", "blind", "charm", "slow", "weak", "berserk", "lovestruck", "petrify"]:
		enemy[key] = maxf(0, float(enemy.get(key, 0)) - delta)
	for kind in ["burn", "poison", "disease", "venom", "frostburn", "darkflame", "radiation"]:
		var stacks: Array = enemy.statuses.get(kind, [])
		var damage_value = 0.0
		for stack in stacks:
			var tick = minf(delta, stack.life)
			damage_value += tick * stack.dps
			stack.life -= delta
			if kind == "darkflame" and stack.life <= 0:
				var source: Dictionary = stack.get("parameters", {})
				damage_value += rng.randf_range(source.get("burst_low", 1), source.get("burst_high", 100)) * status_multiplier()
		stacks = stacks.filter(func(stack): return stack.life > 0)
		enemy.statuses[kind] = stacks
		enemy[kind + "_stacks"] = stacks.size()
		enemy[kind] = 0.0
		for stack in stacks:
			enemy[kind] = maxf(enemy[kind], stack.life)
		if damage_value > 0:
			damage(enemy, damage_value, false, "status")
		if enemy.dead:
			return

	if enemy.has("tumor"):
		enemy.tumor -= delta
		if enemy.tumor <= 0:
			kill(enemy)
			return
	enemy.effect_clock = float(enemy.get("effect_clock", 1.0)) - delta
	if enemy.effect_clock > 0: return
	enemy.effect_clock += 1.0
	if enemy.get("leech", false):
		var p = effect_parameters(enemy, "leech", "leech")
		enemy.bleed_stacks = mini(int(p.limit), enemy.bleed_stacks + int(p.stacks))
	if enemy.get("berserk", 0) > 0:
		var p = effect_parameters(enemy, "berserk", "berserk")
		for target in RonkeEvolvedEffects.targets(self, enemy.pos, TILE * 1.5):
			if target.id != enemy.id: damage(target, rng.randf_range(p.low, p.high) * status_multiplier(), false, "status")
	if enemy.get("incubus", false) and enemy.charm > 0:
		var p = effect_parameters(enemy, "incubus", "incubus")
		for target in RonkeEvolvedEffects.targets(self, enemy.pos, TILE * 2): RonkeEvolvedEffects.curse(self, target, p.curse_hits, p.curse_low, p.curse_high)
	if enemy.get("disease", 0) > 0:
		var active: Array = enemy.statuses.get("disease", [])
		var p: Dictionary = active.back().get("parameters", {}) if not active.is_empty() else {}
		if p.is_empty(): p = RonkeBallRules.parameters("virus")
		for target in RonkeEvolvedEffects.targets(self, enemy.pos, TILE * 2):
			if target.id != enemy.id and target.get("disease", 0) <= 0 and rng.randf() < float(p.chance): apply_status(target, "disease", p.duration, rng.randf_range(p.low, p.high), p.limit, p)
	if enemy.get("rod", false):
		var p = effect_parameters(enemy, "rod", "lightning_rod")
		enemy.rod_clock = float(enemy.get("rod_clock", 0.0)) - 1.0
		if enemy.rod_clock <= 0:
			enemy.rod_clock = p.interval
			for target in RonkeEvolvedEffects.targets(self, enemy.pos, TILE * p.radius).slice(0, p.targets): damage(target, rng.randf_range(p.low, p.high) * area_multiplier(), false, "area")

func nearest_enemy(pos: Vector2, exclude_id: int = -1, exclude_charmed: bool = false) -> Dictionary:
	var nearest: Dictionary = {}
	var distance = INF
	for enemy in enemies:
		if enemy.dead or enemy.id == exclude_id or (exclude_charmed and enemy.charm > 0):
			continue
		var candidate: float = enemy.pos.distance_squared_to(pos)
		if candidate < distance:
			distance = candidate
			nearest = enemy
	return nearest

func add_hazard(kind: String, pos: Vector2, radius: float, duration: float, power: float = 0.0, parameters: Dictionary = {}) -> void:
	hazards = hazards.filter(func(hazard): return hazard.life > 0)
	if hazards.size() >= MAX_HAZARDS:
		rejected_spawns.hazard += 1
		return
	hazards.append({"kind": kind, "pos": pos, "radius": radius, "life": duration, "power": power, "pulse": 0.0, "parameters": parameters.duplicate(true)})

func _update_hazards(delta: float) -> void:
	if delta <= 0: return
	for hazard in hazards.duplicate():
		if phase != "playing": break
		var tick: float = minf(delta, hazard.life)
		hazard.life -= delta
		var p: Dictionary = hazard.parameters
		if p.is_empty(): p = RonkeBallRules.parameters(hazard.kind)
		if hazard.kind == "delayed_bomb":
			if hazard.life <= 0:
				splash(hazard.pos, hazard.radius, hazard.power)
				add_hazard("time_snare", hazard.pos, hazard.radius, p.get("snare_duration", 2.0))
			continue
		hazard.pulse -= delta
		for enemy in RonkeEvolvedEffects.targets(self, hazard.pos, hazard.radius):
			match hazard.kind:
				"time_snare": apply_status(enemy, "freeze", FIXED_STEP * 2)
				"landslide", "armageddon": damage(enemy, hazard.power * tick * area_multiplier(), false, "area")
				"magma", "swamp", "glacier":
					damage(enemy, rng.randf_range(p.aura_low, p.aura_high) * tick * area_multiplier(), false, "area")
					if hazard.pulse <= 0:
						damage(enemy, rng.randf_range(p.low, p.high) * area_multiplier(), false, "area")
						if hazard.kind == "magma": apply_status(enemy, "burn", p.duration, rng.randf_range(p.burn_low, p.burn_high), p.limit)
						elif hazard.kind == "swamp":
							apply_status(enemy, "strong_slow", p.duration)
							apply_status(enemy, "poison", 6.0, rng.randf_range(p.poison_low, p.poison_high), p.limit)
						else: apply_status(enemy, "freeze", p.duration)
		if hazard.pulse <= 0: hazard.pulse = 1.0
	# Flicker pulses independently of projectile collision.
	if elements.has("flicker"):
		var p = RonkeBallRules.parameters("flicker", int(element_levels.get("flicker", 1)))
		var timer: float = float(aura_clocks.get("flicker", 0.0)) - delta
		if timer <= 0:
			timer = p.interval
			for enemy in enemies:
				if not enemy.dead and enemy.charm <= 0:
					damage(enemy, rng.randf_range(p.low, p.high) * area_multiplier(), false, "area")
			emit("pulse", {"pos": player.pos})
		aura_clocks["flicker"] = timer
	hazards = hazards.filter(func(hazard): return hazard.life > 0)

func spawn_child(pos: Vector2, element: String) -> void:
	add_ball(pos, Vector2.from_angle(rng.randf() * TAU), element, 1.0, false)

func clone_ball(ball: Dictionary, enemy: Dictionary, limit: int) -> void:
	_prune_balls()
	if ball.clone_depth >= limit: return
	if balls.size() >= MAX_BALLS:
		rejected_spawns.ball += 1
		return
	ball.clone_depth += 1
	var clone: Dictionary = ball.duplicate(true)
	next_id += 1
	clone.id = next_id
	clone.refundable = false
	clone.group = 0
	clone.velocity = ball.velocity.rotated(0.3)
	clone.hits[enemy.id] = time
	clone.contacts = [enemy.id]
	clone.trail = [clone.pos]
	balls.append(clone)

func spawn_seeker(pos: Vector2, kind: String, parameters: Dictionary = {}) -> void:
	seekers = seekers.filter(func(seeker): return seeker.life > 0)
	if seekers.size() >= MAX_SEEKERS:
		rejected_spawns.seeker += 1
		return
	var candidates = enemies.filter(func(e): return not e.dead and e.charm <= 0)
	if candidates.is_empty(): return
	if kind == "lightning_bug": candidates.sort_custom(func(a, b): return a.hp > b.hp)
	var target: Dictionary = candidates[0] if kind == "lightning_bug" else candidates[rng.randi_range(0, candidates.size() - 1)]
	seekers.append({"pos": pos, "kind": kind, "target": target.id, "life": 5.0, "parameters": parameters.duplicate(true)})

func _update_seekers(delta: float) -> void:
	if delta <= 0: return
	for seeker in seekers:
		if phase != "playing": break
		seeker.life -= delta
		var found = enemies.filter(func(e): return not e.dead and e.charm <= 0 and e.id == seeker.target)
		var target: Dictionary = found[0] if not found.is_empty() else nearest_enemy(seeker.pos, -1, true)
		if target.is_empty():
			seeker.life = 0
			continue
		seeker.target = target.id
		var offset: Vector2 = target.pos - seeker.pos
		seeker.pos += offset.limit_length(420.0 * delta)
		if offset.length() > target.width * 0.5 + 420.0 * delta: continue
		var p: Dictionary = seeker.parameters
		if p.is_empty(): p = RonkeBallRules.parameters("mosquito_kingdom" if seeker.kind == "royal_mosquito" else "nosferatu" if seeker.kind == "bat" else "fireworks" if seeker.kind == "firework" else "lightning_bug" if seeker.kind == "lightning_bug" else "mosquito_king")
		var power = rng.randf_range(p.low, p.high)
		if seeker.kind == "lightning_bug":
			var nearby = RonkeEvolvedEffects.targets(self, target.pos, TILE * p.radius)
			for victim in nearby.slice(0, p.targets): damage(victim, rng.randf_range(p.low, p.high) * area_multiplier(), false, "area")
		else:
			# A seeking creature is a summon attack, not an area explosion.
			damage(target, power * stats.damage, false, "summon")
			if target.dead and seeker.kind in ["mosquito", "royal_mosquito"]: heal(p.heal)
			if seeker.kind == "firework": apply_status(target, "burn", p.duration, rng.randf_range(p.burn_low, p.burn_high), p.limit)
			elif seeker.kind == "bat": spawn_child(seeker.pos, "vampire_lord")
		emit("chain", {"pos": seeker.pos, "end": target.pos})
		seeker.life = 0
	seekers = seekers.filter(func(s): return s.life > 0)

func remember_effect(enemy: Dictionary, kind: String, parameters: Dictionary) -> void:
	if not enemy.has("effect_parameters"): enemy.effect_parameters = {}
	enemy.effect_parameters[kind] = parameters.duplicate(true)

func effect_parameters(enemy: Dictionary, kind: String, element: String) -> Dictionary:
	return enemy.get("effect_parameters", {}).get(kind, RonkeBallRules.parameters(element))

func spawn_ally(enemy: Dictionary) -> void:
	allies = allies.filter(func(ally): return not ally.dead)
	if allies.size() >= MAX_ALLIES:
		rejected_spawns.ally += 1
		return
	next_id += 1
	allies.append({"id": next_id, "pos": enemy.pos, "radius": enemy.width * 0.35, "hp": enemy.max_hp, "max_hp": enemy.max_hp,
		"damage": 20.0 * stats.damage, "speed": 35.0, "attack_clock": 0.0, "hurt_clock": 0.0, "dead": false})
	emit("ally_spawn", {"pos": enemy.pos})

func _update_allies(delta: float, movement_delta: float) -> void:
	if delta <= 0: return
	for ally in allies:
		if phase != "playing": break
		if ally.dead: continue
		ally.attack_clock = maxf(0, ally.attack_clock - delta)
		ally.hurt_clock = maxf(0, ally.hurt_clock - movement_delta)
		var target = nearest_enemy(ally.pos, -1, true)
		if target.is_empty() or target.pos.distance_to(ally.pos) > ally.radius + target.width * 0.5 + 2:
			ally.pos.y -= ally.speed * movement_delta
		else:
			if ally.attack_clock <= 0:
				damage(target, ally.damage, false, "summon")
				ally.attack_clock = 1.0
				emit("chain", {"pos": ally.pos, "end": target.pos})
			if not target.dead and ally.hurt_clock <= 0 and movement_delta > 0:
				ally.hp -= 10.0 * float(target.get("attack_scale", 1.0))
				ally.hurt_clock = 1.0
		ally.dead = ally.hp <= 0 or ally.pos.y < 20
	allies = allies.filter(func(ally): return not ally.dead)

func _automatic_upgrade_index() -> int:
	if choices.is_empty():
		return 0
	if crew.id == "cogitator":
		return rng.randi_range(0, choices.size() - 1)
	var best = 0
	var score = -INF
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var weight = 2.0 if choice.has("fusion") else 1.0
		if choice.id == "vitality" and player.hp < player.max_hp * 0.6:
			weight += 5.0
		if choice.get("level_ball", false):
			weight += 1.0
		weight += rng.randf() * 0.5
		if weight > score:
			score = weight
			best = i
	return best

func _radical_input() -> Dictionary:
	var target = nearest_threat()
	var aim: Vector2 = target.pos if not target.is_empty() else Vector2(300, 100)
	var best_x: float = player.pos.x
	var best_score = -INF
	for x in [55.0, 125.0, 195.0, 265.0, 335.0, 405.0, 475.0, 545.0]:
		var position = Vector2(x, player.pos.y)
		var score = -absf(x - aim.x) * 0.08 - absf(x - player.pos.x) * 0.05
		for bullet in bullets:
			if bullet.dead or bullet.get("ally", false):
				continue
			var next: Vector2 = bullet.pos + bullet.velocity * 0.45
			var risk: float = position.distance_to(next)
			score -= 1500.0 / maxf(10, risk)
		for enemy in enemies:
			if not enemy.dead and enemy.pos.distance_to(position) < 110:
				score -= 30
		if score > best_score:
			best_score = score
			best_x = x
	var movement = Vector2(clampf((best_x - player.pos.x) / 30, -1, 1), 0)
	var imminent = false
	for bullet in bullets:
		if not bullet.get("ally", false) and not bullet.dead and (bullet.pos + bullet.velocity * 0.18).distance_to(player.pos) < 45:
			imminent = true
	return {"move": movement, "aim": aim, "shoot": true, "dash": imminent and player.dash_cd <= 0,
		"surge": surge >= 100 and (imminent or enemies.size() >= 6 or player.hp < player.max_hp * 0.5),
		"recall": balls.size() >= MAX_BALLS - 8 or (ready_specials().is_empty() and player.ammo <= 0 and fmod(time, 5.0) < 0.02)}
