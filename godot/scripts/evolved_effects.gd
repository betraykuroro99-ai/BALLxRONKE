class_name RonkeEvolvedEffects
extends RefCounted

# Independent event hooks keep launch, impact, bounce and timed abilities distinct.
# All damage routes through the run's impact/area/status rules.
static func targets(run, pos: Vector2, radius: float) -> Array:
	return run.enemies.filter(func(e): return not e.dead and e.charm <= 0 and e.pos.distance_to(pos) <= radius)

static func curse(run, enemy: Dictionary, hits: int, low: float, high: float) -> void:
	if not enemy.dead and not enemy.has("curse_hits"):
		enemy.curse_hits = hits
		enemy.curse_power = run.rng.randf_range(low, high) * run.status_multiplier()

static func on_launch(run, ball: Dictionary) -> void:
	var p: Dictionary = ball.parameters
	match ball.element:
		"timestop":
			run.timestop_left = maxf(run.timestop_left, p.duration)
			for enemy in run.enemies:
				run.apply_status(enemy, "freeze", p.duration)
		"banshee":
			for enemy in run.enemies:
				curse(run, enemy, p.hits, p.low, p.high)
		"petrify":
			for enemy in run.enemies:
				var offset: Vector2 = enemy.pos - ball.pos
				if offset.dot(ball.velocity.normalized()) >= 0 and absf(offset.cross(ball.velocity.normalized())) <= run.TILE:
					run.apply_status(enemy, "petrify", p.duration)
					run.damage(enemy, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")

static func beam(run, enemy: Dictionary, ball: Dictionary, low: float, high: float, mode: String, status: String = "") -> void:
	for target in run.enemies:
		if target.dead or target.charm > 0:
			continue
		var p: Dictionary = ball.parameters
		var offset: Vector2 = target.pos - enemy.pos
		var width: float = (run.TILE + target.width) * 0.5
		var inside: bool = absf(offset.x) <= width
		if mode == "horizontal": inside = absf(offset.y) <= width
		elif mode == "cross": inside = absf(offset.x) <= width or absf(offset.y) <= width
		elif mode == "diagonal": inside = minf(absf(offset.x - offset.y), absf(offset.x + offset.y)) <= width
		elif mode == "direction": inside = absf(offset.cross(ball.velocity.normalized())) <= width
		if not inside: continue
		run.damage(target, run.rng.randf_range(low, high) * run.area_multiplier(), false, "area")
		if status == "radiation": run.apply_status(target, "radiation", p.get("duration", 15.0), 0, p.get("limit", 5))
		elif status == "blind": run.apply_status(target, "blind", p.duration)
		elif status == "freeze" and run.rng.randf() < p.chance: run.apply_status(target, "freeze", p.duration)
	run.emit("beam", {"pos": enemy.pos, "horizontal": mode == "horizontal", "mode": mode, "direction": ball.velocity.normalized()})

static func on_hit(run, enemy: Dictionary, ball: Dictionary) -> void:
	var p: Dictionary = ball.parameters
	match ball.element:
		"vampire_lord", "hemorrhage":
			enemy.bleed_stacks += int(p.stacks)
			var threshold: int = p.threshold
			if enemy.bleed_stacks >= threshold:
				enemy.bleed_stacks = 0
				if ball.element == "vampire_lord": run.heal(p.heal)
				else: run.damage(enemy, enemy.hp * p.percent * run.status_multiplier(), false, "status")
		"leech":
			enemy.leech = true
			run.remember_effect(enemy, "leech", p)
		"virus": run.apply_status(enemy, "disease", p.duration, run.rng.randf_range(p.low, p.high), p.limit, p)
		"venom":
			run.apply_status(enemy, "venom", p.duration, run.rng.randf_range(p.low, p.high), p.limit, p)
			run.apply_status(enemy, "slow", p.duration)
		"berserk":
			if run.rng.randf() < p.chance:
				run.apply_status(enemy, "berserk", p.duration)
				run.remember_effect(enemy, "berserk", p)
		"sacrifice":
			enemy.bleed_stacks = mini(int(p.limit), enemy.bleed_stacks + int(p.stacks))
			curse(run, enemy, p.hits, p.low, p.high)
		"phantom": curse(run, enemy, p.hits, p.low, p.high)
		"soul_sucker", "heart_swallower":
			if not enemy.get("sapped", false):
				enemy.sapped = true
				enemy.attack_scale = p.attack_scale
				if run.rng.randf() < p.chance: run.heal(p.heal)
		"maggot":
			enemy.infested = true
			run.remember_effect(enemy, "maggot", p)
		"spider_queen":
			if run.rng.randf() < p.chance: run.spawn_child(ball.pos, "egg")
		"mosquito_king", "mosquito_kingdom", "mosquito_swarm":
			var count = run.rng.randi_range(p.count_min, p.count_max)
			for _i in range(count):
				run.spawn_seeker(ball.pos, "royal_mosquito" if ball.element == "mosquito_kingdom" else "mosquito", p)
			if ball.element == "mosquito_swarm": run.return_ball(ball)
		"lightning_bug": run.spawn_seeker(ball.pos, "lightning_bug", p)
		"bomb", "nuclear_bomb":
			if ball.element == "nuclear_bomb":
				for target in run.enemies: run.apply_status(target, "radiation", INF, 0, 5)
			run.splash(enemy.pos, run.TILE * 2, run.rng.randf_range(p.low, p.high))
			run.return_ball(ball)
		"frozen_flame": run.apply_status(enemy, "frostburn", p.duration, run.rng.randf_range(p.low, p.high), p.limit, p)
		"banished_flame": run.apply_status(enemy, "darkflame", p.duration, run.rng.randf_range(p.low, p.high), p.limit, p)
		"fireworks":
			for _i in range(run.rng.randi_range(p.count_min, p.count_max)): run.spawn_seeker(ball.pos, "firework", p)
			run.return_ball(ball)
		"magma", "swamp", "glacier":
			run.splash(enemy.pos, run.TILE * 0.55, run.rng.randf_range(6, 12))
		"overgrowth":
			enemy.overgrowth = int(enemy.get("overgrowth", 0)) + 1
			if enemy.overgrowth >= int(p.threshold):
				enemy.overgrowth = 0
				for target in run.enemies:
					if not target.dead and absf(target.pos.x - enemy.pos.x) <= run.TILE * 1.5 and absf(target.pos.y - enemy.pos.y) <= run.TILE * 1.5:
						run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
		"radiation_beam": beam(run, enemy, ball, p.low, p.high, "direction", "radiation")
		"freeze_ray": beam(run, enemy, ball, p.low, p.high, "direction", "freeze")
		"laser_beam": beam(run, enemy, ball, p.low, p.high, "direction", "blind")
		"holy_laser": beam(run, enemy, ball, p.low, p.high, "cross")
		"x_ray": beam(run, enemy, ball, p.low, p.high, "diagonal", "radiation")
		"voluptuous_egg_sac":
			for _i in range(run.rng.randi_range(p.count_min, p.count_max)): run.spawn_child(ball.pos, "egg")
			run.return_ball(ball)
		"succubus", "incubus":
			if ball.element == "succubus" and enemy.charm > 0: run.heal(1)
			if run.rng.randf() < p.chance:
				run.apply_status(enemy, "charm", p.duration)
				if ball.element == "incubus":
					enemy.incubus = true
					run.remember_effect(enemy, "incubus", p)
		"lovestruck":
			run.apply_status(enemy, "lovestruck", p.duration)
			run.remember_effect(enemy, "lovestruck", p)
		"noxious":
			for target in targets(run, enemy.pos, run.TILE * 2):
				for _i in range(int(p.stacks)): run.apply_status(target, "poison", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
		"landslide", "armageddon":
			run.add_hazard(ball.element, enemy.pos, run.TILE * p.radius, p.duration, run.rng.randf_range(p.low, p.high), p)
			run.return_ball(ball)
		"lightning_rod":
			enemy.rod = true
			run.remember_effect(enemy, "rod", p)
		"black_hole":
			if enemy.kind not in ["boss", "miniboss"]: run.kill(enemy)
			run.return_ball(ball)
		"flash":
			for target in run.enemies:
				run.apply_status(target, "blind", p.duration)
				run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
		"wraith": run.apply_status(enemy, "freeze", p.duration)
		"timestop": run.return_ball(ball)
		"erosion": run.damage(enemy, maxf(0, enemy.hp) * p.percent, false, "impact")
		"warp":
			ball.pos = Vector2(run.rng.randf_range(35, run.WIDTH - 35), run.rng.randf_range(45, run.HEIGHT - 170))
			ball.previous = ball.pos
			ball.trail = [ball.pos]
			ball.contacts = []
			ball.velocity *= 1.0 + p.speed_gain
		"reaper":
			if enemy.kind not in ["boss", "miniboss"] and run.rng.randf() < p.chance:
				run.kill(enemy)
				run.heal(p.heal)
		"tumor":
			if enemy.kind not in ["boss", "miniboss"] and not enemy.has("tumor"): enemy.tumor = p.duration
		"zombie": enemy.zombie_infected = true
		"offspring": run.clone_ball(ball, enemy, p.divisions)
		"elemental":
			var effect = ["burn", "slow", "freeze"][run.rng.randi_range(0, 2)]
			for target in targets(run, enemy.pos, run.TILE * 2): run.apply_status(target, effect, p.duration, run.rng.randf_range(p.low, p.high) if effect == "burn" else 0, p.limit)

static func on_bounce(run, ball: Dictionary, wall_hit: bool = false) -> void:
	var p: Dictionary = ball.parameters
	if ball.element == "nosferatu": run.spawn_seeker(ball.pos, "bat", p)
	if wall_hit and ball.element in ["shotgun", "sniper"]:
		for _i in range(run.rng.randi_range(p.count_min, p.count_max)):
			run.spawn_child(ball.pos, "sniper_pellet" if ball.element == "sniper" else "iron_pellet")

static func tick_ball(run, ball: Dictionary, delta: float) -> void:
	if ball.manual_recall or ball.air_time > 0: return
	var element: String = ball.element
	var p: Dictionary = ball.parameters
	if element == "laser_cutter":
		for enemy in run.enemies:
			var offset: Vector2 = enemy.pos - ball.pos
			if not enemy.dead and enemy.charm <= 0 and offset.dot(ball.velocity.normalized()) >= 0 and absf(offset.cross(ball.velocity.normalized())) <= enemy.width * 0.5 + 8:
				run.damage(enemy, run.rng.randf_range(p.low, p.high) * delta * run.area_multiplier(), false, "area")
		if float(ball.get("beam_clock", 0.0)) <= 0:
			run.emit("beam", {"pos": ball.pos, "horizontal": false, "mode": "ray", "direction": ball.velocity.normalized()})
			ball.beam_clock = 0.12
		ball.beam_clock -= delta
	var interval: float = p.get("interval", 1.0)
	ball.pulse -= delta
	if ball.pulse > 0: return
	ball.pulse += interval
	match element:
		"flesh_mound": run.spawn_child(ball.pos, "fleshy_baby")
		"catapult":
			for _i in range(run.rng.randi_range(p.count_min, p.count_max)): run.spawn_child(ball.pos, "stone_pellet")
		"magma", "swamp", "glacier": run.add_hazard(element, ball.pos, run.TILE * 0.55, p.patch_life, 0, p)
		"time_bomb": run.add_hazard("delayed_bomb", ball.pos, run.TILE * p.radius, p.delay, run.rng.randf_range(p.low, p.high), p)
		"inferno", "brimstone", "sandstorm", "storm", "sun", "satan":
			var nearby = targets(run, ball.pos, run.TILE * 2)
			if element in ["sun", "satan"]: nearby = targets(run, Vector2.ZERO, INF)
			for enemy in nearby:
				match element:
					"inferno": run.apply_status(enemy, "burn", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
					"brimstone":
						run.apply_status(enemy, "burn", p.burn_duration, run.rng.randf_range(p.low, p.high), p.limit)
						run.apply_status(enemy, "poison", p.poison_duration, run.rng.randf_range(p.poison_low, p.poison_high), p.limit)
					"sandstorm":
						run.damage(enemy, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
						run.apply_status(enemy, "blind", p.duration)
					"storm": run.damage(enemy, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
					"sun":
						run.apply_status(enemy, "blind", 1.1)
						run.apply_status(enemy, "burn", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
					"satan":
						run.apply_status(enemy, "burn", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
						run.apply_status(enemy, "berserk", 1.1)
						run.remember_effect(enemy, "berserk", {"low": p.berserk_low, "high": p.berserk_high})
