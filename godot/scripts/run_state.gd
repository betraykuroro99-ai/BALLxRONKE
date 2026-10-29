class_name RonkeRun
extends RefCounted

const WIDTH = 600.0
const HEIGHT = 820.0
const LAST_WAVE = 10

var crew: Dictionary
var world: int
var rng = RandomNumberGenerator.new()
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

func _init(crew_id: String = "warrior", world_index: int = 0, run_seed: int = 1, meta: Dictionary = {}) -> void:
	crew = RonkeData.crew(crew_id)
	world = clampi(world_index, 0, 2)
	rng.seed = run_seed
	var health = (65 if crew_id == "tiptoer" else 140 if crew_id == "shieldbearer" else 100) + clampi(int(meta.get("vitality", 0)), 0, 3) * 10
	var capacity = (5 if crew_id == "hoary_hoarder" else 16 if crew_id == "ballbearer" else 9) + clampi(int(meta.get("reserves", 0)), 0, 3)
	player = {"pos": Vector2(300, 750), "hp": float(health), "max_hp": float(health), "ammo": capacity, "capacity": capacity,
		"hurt": 0.0, "shoot": 0.0, "dash": 0.0, "dash_cd": 0.0, "moving": false, "invincible": 0.0, "dash_direction": Vector2.RIGHT}
	var bonus = 1.15 if crew_id == "warrior" else 1.65 if crew_id == "hoary_hoarder" else 1.2 if crew_id == "cogitator" else 1.0
	stats = {"damage": bonus * (1.0 + clampi(int(meta.get("power", 0)), 0, 3) * 0.05),
		"interval": 0.17 if crew_id == "itchy_finger" else 0.28, "speed": 250.0, "bounce": 0.0}
	elements = [crew.element]
	element_levels[crew.element] = 1
	spawn_wave()

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
	delta = clampf(delta, 0.0, 0.1)
	if phase == "upgrade":
		if crew.id in ["cogitator", "radical"]:
			upgrade_clock += delta
			if upgrade_clock >= 0.9:
				choose_upgrade(0)
		return
	if phase != "playing":
		return
	var steps = maxi(1, ceili(delta * 120.0))
	for _i in range(steps):
		if phase != "playing":
			break
		_step(delta / steps, input)

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
		"speed": speed, "fire": 2.0 + rng.randf() * 4.0, "charging": false, "attack_angle": 0.0, "burn": 0.0, "poison": 0.0, "slow": 0.0, "weak": 0.0, "flash": 0.0, "dead": false})

func _step(delta: float, input: Dictionary) -> void:
	time += delta
	wave_clock += delta
	combo_time -= delta
	if combo_time <= 0.0:
		combo = 0
	for key in ["hurt", "shoot", "invincible", "dash_cd", "dash"]:
		player[key] = maxf(0.0, float(player[key]) - delta)
	surge_time = maxf(0.0, surge_time - delta)
	turn_time = maxf(0.0, turn_time - delta)
	var movement: Vector2 = input.get("move", Vector2.ZERO)
	movement = movement.limit_length()
	var aim: Vector2 = input.get("aim", Vector2(300, 100))
	player.moving = movement.length() > 0.05
	if input.get("dash", false) and player.dash_cd <= 0.0:
		player.dash = 0.18
		player.dash_cd = 3.5
		player.invincible = maxf(player.invincible, 0.25)
		player.dash_direction = movement.normalized() if movement.length() > 0.05 else Vector2(signf(aim.x - player.pos.x), 0)
		if player.dash_direction == Vector2.ZERO:
			player.dash_direction = Vector2.RIGHT
		emit("dash", {"pos": player.pos})
	var motion: Vector2 = player.dash_direction if player.dash > 0.0 else movement
	var position: Vector2 = player.pos + motion * stats.speed * (3.0 if player.dash > 0.0 else 1.0) * delta
	player.pos = Vector2(clampf(position.x, 25, WIDTH - 25), clampf(position.y, HEIGHT - 190, HEIGHT - 32))
	if input.get("surge", false) and surge >= 100.0:
		surge = 0.0
		surge_time = 4.0
		player.invincible = 1.2
		player.hp = minf(player.max_hp, player.hp + 6.0)
		for i in range(16):
			var angle = -PI + i / 16.0 * TAU
			add_ball(player.pos, Vector2.from_angle(angle), elements[i % elements.size()], 1.5, false)
		emit("surge", {"pos": player.pos})
	shot_clock -= delta
	if (input.get("shoot", false) or crew.id == "radical") and shot_clock <= 0.0 and player.ammo > 0 and balls.size() < 90:
		shoot(aim)
		shot_clock = maxf(0.08, stats.interval)
	var world_delta = delta * (0.55 if surge_time > 0.0 else 1.0) * (0.0 if crew.id == "tactician" and turn_time <= 0.0 else 1.0)
	_update_enemies(delta, world_delta)
	for bullet in bullets:
		bullet.pos += bullet.velocity * world_delta
		if bullet.pos.distance_to(player.pos) < 22.0 + bullet.radius:
			hurt(bullet.damage)
			bullet.dead = true
		if bullet.pos.y > HEIGHT + 20 or bullet.pos.y < 0 or bullet.pos.x < 0 or bullet.pos.x > WIDTH:
			bullet.dead = true
	for ball in balls.duplicate():
		if ball.dead:
			continue
		ball.life -= delta
		if ball.life <= 0.0:
			return_ball(ball)
			continue
		_update_ball(ball, delta)
	balls = balls.filter(func(ball): return not ball.dead)
	enemies = enemies.filter(func(enemy): return not enemy.dead)
	bullets = bullets.filter(func(bullet): return not bullet.dead)
	if phase != "playing":
		return
	if enemies.is_empty():
		clear_clock += delta
		if clear_clock > 1.6:
			if wave == LAST_WAVE:
				finish(true)
			else:
				spawn_wave()
	elif wave_clock > 17.0 and wave < LAST_WAVE and enemies.size() < 46:
		spawn_wave()

func _update_enemies(delta: float, world_delta: float) -> void:
	for enemy in enemies:
		if enemy.dead:
			continue
		for key in ["flash", "burn", "poison", "slow", "weak"]:
			enemy[key] = maxf(0.0, float(enemy[key]) - delta)
		if enemy.burn > 0.0 or enemy.poison > 0.0:
			enemy.hp -= ((4.0 if enemy.burn > 0.0 else 0.0) + (3.5 if enemy.poison > 0.0 else 0.0)) * stats.damage * delta
			if enemy.hp <= 0.0:
				kill(enemy)
				continue
		enemy.pos.y += enemy.speed * world_delta * (0.35 if enemy.slow > 0.0 else 1.0)
		if enemy.kind == "boss":
			enemy.pos.x = 300 + sin(time * 0.65) * 140
		if enemy.pos.y + enemy.width / 2.0 > HEIGHT - 120:
			if enemy.kind == "boss":
				player.hp = 0.0
				finish(false)
			else:
				hurt(10.0)
			enemy.dead = true
			emit("breach", {"pos": enemy.pos})
			continue
		if enemy.kind in ["prism", "boss"]:
			enemy.fire -= world_delta
			var windup = BOSS_WINDUP if enemy.kind == "boss" else PRISM_WINDUP
			if enemy.fire <= windup and not enemy.charging:
				enemy.charging = true
				# Lock the angle when the warning begins. Dodging during the windup
				# works because the released volley follows the displayed lanes.
				enemy.attack_angle = (player.pos - enemy.pos).angle() + (rng.randf() - 0.5) * (0.6 if crew.id == "tiptoer" else 0.12)
				emit("windup", {"pos": enemy.pos})
			if enemy.fire <= 0.0:
				for direction in attack_directions(enemy):
					bullets.append({"pos": enemy.pos, "velocity": direction * 145.0, "radius": 7.0 if enemy.kind == "boss" else 5.0,
						"damage": 5.0 if enemy.weak > 0.0 else 10.0, "dead": false})
				enemy.fire = 1.5 if enemy.kind == "boss" else 4.5
				enemy.charging = false

func attack_directions(enemy: Dictionary) -> Array[Vector2]:
	# One shared definition keeps warnings and projectiles aligned.
	var result: Array[Vector2] = []
	var count = 3 if enemy.kind == "boss" else 1
	for i in range(count):
		result.append(Vector2.from_angle(enemy.attack_angle + (i - (count - 1) / 2.0) * 0.21))
	return result

func _update_ball(ball: Dictionary, delta: float) -> void:
	if ball.orbit:
		ball.orbit_time += delta
		ball.pos = player.pos + Vector2(cos(ball.orbit_time * 9 + ball.angle) * 46, sin(ball.orbit_time * 9 + ball.angle) * 30)
		if ball.orbit_time > 1.1:
			return_ball(ball)
			return
	else:
		if crew.id == "physicist":
			ball.velocity.y -= 165.0 * delta
		ball.velocity = ball.velocity.limit_length(880.0)
		ball.pos += ball.velocity * delta
		if ball.pos.x < 16 + ball.radius:
			ball.pos.x = 16 + ball.radius
			ball.velocity.x = absf(ball.velocity.x)
			wall(ball)
		elif ball.pos.x > WIDTH - 16 - ball.radius:
			ball.pos.x = WIDTH - 16 - ball.radius
			ball.velocity.x = -absf(ball.velocity.x)
			wall(ball)
		if ball.pos.y < 22 + ball.radius:
			if crew.id == "tunneller" and ball.wraps < 2:
				ball.pos.y = HEIGHT - 45
				ball.wraps += 1
			else:
				ball.pos.y = 22 + ball.radius
				ball.velocity.y = absf(ball.velocity.y)
				wall(ball)
		if crew.id == "shieldbearer" and not ball.shield and ball.velocity.y > 0 and ball.pos.distance_to(player.pos) < 78:
			ball.shield = true
			ball.velocity.y = -absf(ball.velocity.y)
			ball.damage *= 2.0
			emit("shield", {"pos": ball.pos})
		if crew.id == "carouser" and ball.velocity.y > 0 and ball.pos.distance_to(player.pos) < 80:
			ball.orbit = true
			ball.orbit_time = 0.0
			ball.angle = (ball.pos - player.pos).angle()
		if ball.pos.y > HEIGHT - 16:
			if crew.id == "flagellant":
				ball.pos.y = HEIGHT - 17
				ball.velocity.y = -absf(ball.velocity.y)
				wall(ball)
			elif crew.id == "tunneller" and ball.wraps < 2:
				ball.pos.y = 35
				ball.wraps += 1
			else:
				return_ball(ball)
				return
	for enemy in enemies:
		if enemy.dead or ball.dead or float(ball.hits.get(enemy.id, -10.0)) > time - 0.16:
			continue
		var half = enemy.width / 2.0
		var closest = Vector2(clampf(ball.pos.x, enemy.pos.x - half, enemy.pos.x + half), clampf(ball.pos.y, enemy.pos.y - half, enemy.pos.y + half))
		var distance: Vector2 = ball.pos - closest
		if distance.length_squared() > ball.radius * ball.radius:
			continue
		ball.hits[enemy.id] = time
		hit(enemy, ball)
		if ball.pierce > 0:
			ball.pierce -= 1
			continue
		if ball.orbit:
			continue
		var normal = distance.normalized()
		if normal == Vector2.ZERO:
			var sides = [[ball.pos.x - enemy.pos.x + half, Vector2.LEFT], [enemy.pos.x + half - ball.pos.x, Vector2.RIGHT],
				[ball.pos.y - enemy.pos.y + half, Vector2.UP], [enemy.pos.y + half - ball.pos.y, Vector2.DOWN]]
			sides.sort_custom(func(a, b): return a[0] < b[0])
			normal = sides[0][1]
		var dot: float = ball.velocity.dot(normal)
		if dot < 0.0:
			ball.velocity -= 2.0 * dot * normal
		if normal.x != 0:
			ball.pos.x = enemy.pos.x + signf(normal.x) * (half + ball.radius + 1)
		if normal.y != 0:
			ball.pos.y = enemy.pos.y + signf(normal.y) * (half + ball.radius + 1)

func shoot(aim: Vector2) -> void:
	if crew.id == "radical":
		var target = nearest_threat()
		if not target.is_empty():
			aim = target.pos
	var origin: Vector2 = player.pos + Vector2(0, -22)
	if crew.id == "shade":
		origin.y = 35
		aim.y = maxf(100, aim.y)
	var direction = Vector2(aim.x - origin.x, maxf(20, aim.y - origin.y) if crew.id == "shade" else minf(-35, aim.y - origin.y)).normalized()
	var angle = direction.angle() + ((rng.randf() - 0.5) * 0.24 if crew.id == "itchy_finger" else 0.0)
	var element: String = elements[shot_count % elements.size()]
	player.ammo -= 1
	player.shoot = 0.21
	turn_time = 0.16
	shot_count += 1
	if crew.id == "juggler":
		origin = Vector2(clampf(aim.x, 45, WIDTH - 45), clampf(aim.y, 80, HEIGHT - 220))
		splash(origin, 60, 12 * stats.damage)
	if crew.id == "falconer":
		for x in [30.0, WIDTH - 30]:
			var pos = Vector2(x, player.pos.y - 35)
			var vector = Vector2(aim.x - x, minf(-35, aim.y - pos.y)).normalized()
			add_ball(pos, vector, element, 0.7, x == 30.0)
	else:
		add_ball(origin, Vector2.from_angle(angle), element, 0.6 if crew.id == "cohabitants" else 1.0)
		if crew.id == "cohabitants":
			add_ball(origin, Vector2(-cos(angle), sin(angle)), element, 0.6, false)
		if crew.id in ["spendthrift", "empty_nester"]:
			for offset in [-0.15, 0.15]:
				add_ball(origin, Vector2.from_angle(angle + offset), element, 0.7, false)
	emit("shot", {"pos": origin, "element": element})

func add_ball(pos: Vector2, direction: Vector2, element: String, multiplier: float = 1.0, refundable: bool = true) -> void:
	if balls.size() >= 96:
		return
	next_id += 1
	balls.append({"id": next_id, "pos": pos, "velocity": direction * (600.0 if crew.id == "itchy_finger" else 560.0),
		"radius": 5.5, "element": element, "damage": 15.0 * stats.damage * multiplier * (1 + (int(element_levels.get(element, 1)) - 1) * 0.15),
		"pierce": 2 if crew.id == "embedded" else 1 if element in ["laser", "ghost", "eclipse"] else 0,
		"life": 8.0, "refundable": refundable, "wraps": 0, "shield": false, "orbit": false, "orbit_time": 0.0, "angle": 0.0,
		"hits": {}, "bounces": 0, "child": not refundable, "dead": false})

func wall(ball: Dictionary) -> void:
	bounces += 1
	ball.bounces += 1
	ball.damage = minf(200, ball.damage * (1 + stats.bounce + (0.08 if crew.id == "repentant" else 0.0) + (0.04 if ball.element == "iron" else 0.0)))
	emit("bounce", {"pos": ball.pos, "color": RonkeData.orb_color(ball.element)})
	if ball.bounces > 28:
		return_ball(ball)

func return_ball(ball: Dictionary) -> void:
	if ball.dead:
		return
	ball.dead = true
	if ball.refundable:
		player.ammo = mini(player.capacity, player.ammo + 1)

func hit(enemy: Dictionary, ball: Dictionary) -> void:
	var element: String = ball.element
	var value: float = ball.damage
	var crit = rng.randf() < (0.25 if crew.id == "shade" else 0.18 if element in ["dark", "eclipse"] else 0.04)
	if crit:
		value *= 2.0
	if element == "light" and enemy.kind == "granite":
		value *= 1.6
	damage(enemy, 0.0 if crew.id == "makeshift_sisyphus" else value, crit)
	if element in ["fire", "toxic_sun"]:
		enemy.burn = 3.0
	if element in ["poison", "toxic_sun"]:
		enemy.poison = 4.0
	if element in ["frost", "stormglass"]:
		enemy.slow = 3.0
	if element == "wind":
		enemy.pos.y = maxf(30, enemy.pos.y - (3.0 if enemy.kind == "boss" else 14.0))
	if element == "charm":
		enemy.weak = 4.0
	if element == "vampire":
		player.hp = minf(player.max_hp, player.hp + 0.5)
	if element in ["earth", "egg", "toxic_sun", "eclipse"] or crew.id == "makeshift_sisyphus":
		splash(enemy.pos, 75 if crew.id == "makeshift_sisyphus" else 53, value * (3.0 if crew.id == "makeshift_sisyphus" else 1.1 if element == "toxic_sun" else 0.55))
	if element in ["lightning", "stormglass"]:
		var other: Dictionary = {}
		var closest = 125.0
		for target in enemies:
			var distance: float = target.pos.distance_to(enemy.pos)
			if target.id != enemy.id and not target.dead and distance < closest:
				closest = distance
				other = target
		if not other.is_empty():
			damage(other, value * 0.65)
			if element == "stormglass":
				other.slow = 2.0
			emit("chain", {"pos": enemy.pos, "end": other.pos})
	if element == "brood" and not ball.child and crew.id != "empty_nester":
		ball.child = true
		for offset in [-0.7, 0.7]:
			add_ball(ball.pos, Vector2.from_angle(ball.velocity.angle() + offset), "stone", 0.35, false)
	emit("hit", {"pos": ball.pos, "color": RonkeData.orb_color(element), "crit": crit})

func damage(enemy: Dictionary, value: float, crit: bool = false) -> void:
	if enemy.dead or value <= 0:
		return
	enemy.hp -= value
	enemy.flash = 0.08
	emit("damage", {"pos": enemy.pos, "value": roundi(value), "crit": crit})
	if enemy.hp <= 0:
		kill(enemy)

func splash(pos: Vector2, radius: float, value: float) -> void:
	for enemy in enemies:
		if not enemy.dead and enemy.pos.distance_to(pos) < radius + enemy.width * 0.3:
			damage(enemy, value)
	emit("splash", {"pos": pos, "radius": radius})

func kill(enemy: Dictionary) -> void:
	if enemy.dead:
		return
	enemy.dead = true
	kills += 1
	combo += 1
	combo_time = 1.8
	best_combo = maxi(best_combo, combo)
	surge = clampf(surge + (30 if enemy.kind == "boss" else 5), 0, 100)
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
		if not upgrade.has("element") or not elements.has(upgrade.element):
			pool.append(upgrade.duplicate())
	var evolution: Dictionary = {}
	for fusion in RonkeData.all().fusions:
		if elements.has(fusion.ingredients[0]) and elements.has(fusion.ingredients[1]) and not elements.has(fusion.id):
			evolution = {"id": "fusion_" + fusion.id, "name": fusion.name, "description": RonkeData.all().elements[fusion.id].description,
				"icon": "*", "kind": "EVOLUTION", "fusion": fusion.id}
			break
	for i in range(pool.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var item = pool[i]
		pool[i] = pool[j]
		pool[j] = item
	if not evolution.is_empty():
		pool.push_front(evolution)
	return pool.slice(0, 4 if crew.id == "false_messiah" and level % 3 == 0 else 3)

func choose_upgrade(index: int) -> bool:
	if phase != "upgrade" or index < 0 or index >= choices.size():
		return false
	var choice: Dictionary = choices[index]
	match choice.id:
		"power": stats.damage *= 1.22
		"haste": stats.interval = maxf(0.08, stats.interval * 0.82)
		"capacity":
			player.capacity += 2
			player.ammo = player.capacity
		"vitality":
			player.max_hp += 20.0
			player.hp = minf(player.max_hp, player.hp + 30)
		"ricochet": stats.bounce += 0.1
		"speed":
			stats.speed = minf(440, stats.speed * 1.15)
			player.dash_cd = maxf(0, player.dash_cd - 0.75)
	if choice.has("element"):
		elements.append(choice.element)
		element_levels[choice.element] = 1
	if choice.has("fusion"):
		for fusion in RonkeData.all().fusions:
			if fusion.id == choice.fusion:
				for ingredient in fusion.ingredients:
					elements.erase(ingredient)
				elements.append(fusion.id)
				element_levels[fusion.id] = 2
	picks.append(choice.name)
	choices = []
	phase = "playing"
	emit("upgrade", {"name": choice.name})
	check_level()
	return true

func hurt(value: float) -> void:
	if player.invincible > 0 or phase in ["victory", "defeat"]:
		return
	player.hp = maxf(0, player.hp - value)
	player.hurt = 0.4
	player.invincible = 0.85
	emit("hurt", {"pos": player.pos, "value": value})
	if player.hp <= 0:
		finish(false)

func finish(win: bool) -> void:
	if phase in ["victory", "defeat"]:
		return
	phase = "victory" if win else "defeat"
	reward = floori(kills * 0.45 + wave * 2 + (30 if win else 0))
	emit("end", {"win": win, "reward": reward})

func nearest_threat() -> Dictionary:
	var result: Dictionary = {}
	var furthest = -10000.0
	for enemy in enemies:
		if not enemy.dead and enemy.pos.y > furthest:
			result = enemy
			furthest = enemy.pos.y
	return result
