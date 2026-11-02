class_name RonkeBallEffects
extends RefCounted

static func on_hit(run, enemy: Dictionary, ball: Dictionary, _impact: float) -> void:
	var element: String = ball.element
	var p: Dictionary = ball.parameters
	match element:
		"bleed": enemy.bleed_stacks = mini(int(p.limit), enemy.bleed_stacks + int(p.stacks))
		"fire": run.apply_status(enemy, "burn", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
		"poison": run.apply_status(enemy, "poison", p.duration, run.rng.randf_range(p.low, p.high), p.limit)
		"frost":
			if run.rng.randf() < p.chance: run.apply_status(enemy, "freeze", p.duration)
		"light": run.apply_status(enemy, "blind", p.duration)
		"wind": run.apply_status(enemy, "slow", p.duration)
		"charm":
			if run.rng.randf() < p.chance: run.apply_status(enemy, "charm", p.duration)
		"vampire":
			if run.rng.randf() < p.chance: run.heal(p.heal)
		"brood":
			if run.rng.randf() < p.chance: run.spawn_baby(ball.pos, Vector2.from_angle(run.rng.randf() * TAU))
		"egg":
			for _i in range(run.rng.randi_range(p.count_min, p.count_max)): run.spawn_baby(ball.pos, Vector2.from_angle(run.rng.randf() * TAU))
			run.return_ball(ball)
		"dark": run.return_ball(ball)
		"cell": run.clone_ball(ball, enemy, p.divisions)
		"laser", "laser_h":
			for target in run.enemies:
				if target.dead or target.charm > 0: continue
				var distance = absf(target.pos.x - enemy.pos.x) if element == "laser" else absf(target.pos.y - enemy.pos.y)
				if distance <= run.TILE * 0.5 + target.width * 0.5: run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
			run.emit("beam", {"pos": enemy.pos, "horizontal": element == "laser_h"})
		"earth":
			for target in run.enemies:
				if not target.dead and target.charm <= 0 and absf(target.pos.x - enemy.pos.x) <= run.TILE * p.radius and absf(target.pos.y - enemy.pos.y) <= run.TILE * p.radius:
					run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
			run.emit("splash", {"pos": enemy.pos, "radius": run.TILE * p.radius})
		"lightning":
			var targets = run.enemies.filter(func(target): return not target.dead and target.charm <= 0 and target.id != enemy.id and target.pos.distance_to(enemy.pos) <= run.TILE * p.radius)
			targets.sort_custom(func(a, b): return a.pos.distance_squared_to(enemy.pos) < b.pos.distance_squared_to(enemy.pos))
			for target in targets.slice(0, p.targets):
				run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
				run.emit("chain", {"pos": enemy.pos, "end": target.pos})
		"time":
			run.add_hazard("time_snare", enemy.pos, run.TILE * p.radius, p.duration, 0, p)
			run.return_ball(ball)
		"blizzard":
			for target in run.enemies:
				if not target.dead and target.charm <= 0 and target.pos.distance_to(enemy.pos) <= run.TILE * p.radius:
					run.apply_status(target, "freeze", p.duration)
					run.damage(target, run.rng.randf_range(p.low, p.high) * run.area_multiplier(), false, "area")
