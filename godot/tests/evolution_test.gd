extends SceneTree

var failures: Array[String] = []
var checks = 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("EVOLUTION: " + message)
func fixture(element: String) -> RonkeRun:
	var run = RonkeRun.new("warrior", 0, 5522)
	run.enemies.clear()
	run.elements = [element]
	run.element_levels = {element: 1}
	run.stats.crit = 0
	for pos in [Vector2(300, 220), Vector2(350, 220), Vector2(300, 270), Vector2(350, 270)]:
		run._add_enemy(pos, 40, 1000000, "moss", 0)
	run.events.clear()
	run.add_ball(Vector2(300, 220), Vector2.UP, element, 1, false)
	return run
func strike(run: RonkeRun, times: int = 1) -> void:
	for _i in range(times): run.hit(run.enemies[0], run.balls[0])
func _run() -> void:
	_test_catalogue()
	_test_statuses()
	_test_launch_and_movement()
	_test_children()
	_test_area_and_timers()
	if failures.is_empty():
		print("PASS: evolved catalogue / ", checks, " checks")
		quit()
	else:
		print("FAIL: ", failures.size(), " / ", checks)
		quit(1)
func _test_catalogue() -> void:
	var count = 0
	var reachable: Dictionary = {}
	for id in RonkeData.all().elements:
		if RonkeData.all().elements[id].get("tier") == "base": reachable[id] = true
	for _i in range(5):
		for recipe in RonkeData.all().fusions:
			if recipe.ingredients.all(func(id): return reachable.has(id)): reachable[recipe.id] = true
	for id in RonkeData.all().elements:
		if RonkeData.all().elements[id].get("tier") != "evolved": continue
		count += 1
		check(reachable.has(id), "Reachable recipe chain: " + id)
		var run = fixture(id)
		RonkeEvolvedEffects.on_launch(run, run.balls[0])
		strike(run)
		for _tick in range(30): run.advance(1.0 / 60.0)
		check(run.balls.size() <= run.MAX_BALLS and run.seekers.size() <= 64 and run.hazards.size() <= 64, "Bounded entities: " + id)
		check(run.balls.all(func(b): return b.pos.is_finite() and b.velocity.is_finite()), "Finite simulation: " + id)
	check(count == 69, "All 69 named evolved balls")
	for recipe in RonkeData.all().fusions:
		var run = RonkeRun.new("ballbearer")
		run.elements = recipe.ingredients.duplicate()
		for id in run.elements: run.element_levels[id] = 3
		var matching = run.get_choices().filter(func(c): return c.get("fusion", "") == recipe.id)
		# Four-component recipes are offered ahead of competing smaller pairs.
		if recipe.id == "elemental":
			check(not matching.is_empty() and matching[0].ingredients.size() == 4, "Four-component Elemental readiness")
		else:
			check(not matching.is_empty(), "Offer recipe: " + recipe.id + str(recipe.ingredients))
			if not matching.is_empty():
				run.phase = "upgrade"
				run.choices = matching
				run.choose_upgrade(0)
				check(run.elements == [recipe.id] and run.element_levels[recipe.id] == 1, "Consume ingredients: " + recipe.id)
	var run = fixture("warrior")
	run.elements = ["bleed"]
	for _i in range(20):
		check(run.get_choices().all(func(c): return not c.get("level_only", false) or run.elements.has(c.get("element", ""))), "Evolved balls cannot drop as new base balls")
func _test_statuses() -> void:
	var run = fixture("leech")
	strike(run)
	run._tick_statuses(run.enemies[0], 1.0)
	check(run.enemies[0].bleed_stacks == 2, "Leech adds bleed over time")
	run = fixture("hemorrhage")
	run.enemies[0].bleed_stacks = 9
	strike(run)
	check(run.enemies[0].bleed_stacks == 0 and run.enemies[0].hp < 810000, "Hemorrhage threshold consumes stacks for health damage")
	run = fixture("vampire_lord")
	run.player.hp = 40
	run.enemies[0].bleed_stacks = 7
	strike(run)
	check(run.enemies[0].bleed_stacks == 0 and run.player.hp == 41, "Vampire Lord threshold heals")
	for id in ["virus", "venom", "frozen_flame", "banished_flame"]:
		run = fixture(id)
		strike(run)
		var before: float = run.enemies[0].hp
		run._tick_statuses(run.enemies[0], 0.5)
		check(run.enemies[0].hp < before, "Independent timed damage: " + id)
	run = fixture("phantom")
	strike(run)
	check(run.enemies[0].curse_hits == 5, "Curse arms on impact")
	strike(run, 5)
	check(run.enemies[0].hp < 999800, "Curse bursts after subsequent hits")
	for id in ["heart_swallower", "soul_sucker"]:
		run = fixture(id)
		strike(run)
		check(run.enemies[0].sapped and run.enemies[0].attack_scale == 0.8, "Sap lowers attack: " + id)
		run.player.hp = 20
		strike(run, 100)
		check(run.player.hp == 20, "Sap does not reroll lifesteal: " + id)
	run = fixture("tumor")
	strike(run)
	run._tick_statuses(run.enemies[0], 39.9)
	check(not run.enemies[0].dead, "Tumor waits forty seconds")
	run._tick_statuses(run.enemies[0], 0.11)
	check(run.enemies[0].dead, "Tumor executes ordinary enemy")
	run = fixture("tumor")
	run.enemies[0].kind = "boss"
	strike(run)
	check(not run.enemies[0].has("tumor"), "Tumor excludes bosses")
	run = fixture("lovestruck")
	strike(run)
	check(run.enemies[0].lovestruck == 20, "Lovestruck duration")
	run = fixture("incubus")
	for _i in range(300): strike(run)
	check(run.enemies[0].get("incubus", false) and run.enemies[0].charm > 0, "Incubus charms and marks aura")
	run._tick_statuses(run.enemies[0], 1.0)
	check(run.enemies[1].has("curse_hits"), "Charmed Incubus target spreads curse")
	run = fixture("berserk")
	for _i in range(30): strike(run)
	var hp: float = run.enemies[1].hp
	run._tick_statuses(run.enemies[0], 1.0)
	check(run.enemies[1].hp < hp, "Berserk damages adjacent enemies")
func _test_launch_and_movement() -> void:
	var run = fixture("timestop")
	RonkeEvolvedEffects.on_launch(run, run.balls[0])
	check(run.timestop_left == 5 and run.ball_cooldown("timestop") == 30, "Timestop launch and reload")
	run.bullets.append({"pos": Vector2(100, 100), "velocity": Vector2.DOWN * 100, "radius": 5, "damage": 10, "dead": false})
	run.advance(0.1)
	check(run.bullets[0].pos == Vector2(100, 100), "Timestop freezes hostile projectiles")
	run = fixture("banshee")
	RonkeEvolvedEffects.on_launch(run, run.balls[0])
	check(run.enemies.all(func(e): return e.get("curse_hits", 0) == 6), "Banshee launch curses whole field")
	run = fixture("petrify")
	RonkeEvolvedEffects.on_launch(run, run.balls[0])
	check(run.enemies[0].get("petrify", 0) == 1.5 and run.enemies[0].hp < 1000000, "Petrify launch sightline")
	run = fixture("warp")
	var pos: Vector2 = run.balls[0].pos
	strike(run)
	check(run.balls[0].pos != pos and is_equal_approx(run.balls[0].velocity.length(), 588), "Warp teleports and accelerates")
	run = fixture("steel")
	check(run.balls[0].damage == 30 and run.balls[0].velocity.length() == 280, "Steel slow double-impact launch")
	strike(run, 20)
	check(is_equal_approx(run.balls[0].steel_scale, 3), "Steel growth cap")
	run = fixture("drill")
	check(run.balls[0].pierce < 0, "Drill pierces before far wall")
	run.balls[0].pos = Vector2(100, 20)
	run._update_ball(run.balls[0], 0.01)
	check(run.balls[0].far_wall and run.balls[0].pierce == 0, "Drill ends special piercing at far wall")
	run = fixture("black_hole")
	strike(run)
	check(run.enemies[0].dead and run.balls[0].dead and run.ball_cooldown("black_hole") == 7, "Black Hole execution and self destruction")
	run = fixture("black_hole")
	run.enemies[0].kind = "boss"
	strike(run)
	check(not run.enemies[0].dead, "Black Hole cannot execute bosses")
func _test_children() -> void:
	var run = fixture("offspring")
	strike(run, 8)
	check(run.balls.size() == 5 and run.balls[0].clone_depth == 4, "Offspring four clone generations")
	run = fixture("voluptuous_egg_sac")
	strike(run)
	check(run.balls[0].dead and run.balls.size() in [3, 4] and run.balls[1].element == "egg", "Voluptuous Egg Sac children")
	run = fixture("maggot")
	run.enemies[0].hp = 1
	strike(run)
	check(run.balls.size() in [2, 3], "Maggot lethal first impact releases babies")
	for id in ["shotgun", "sniper"]:
		run = fixture(id)
		run.wall(run.balls[0])
		check(run.balls.size() >= 4 and run.balls.size() <= 8, "Wall pellet fan: " + id)
		check(run.balls[1].fragile, "Pellet ownership: " + id)
		run.wall(run.balls[1])
		check(run.balls[1].dead, "Pellets die at wall: " + id)
	for id in ["mosquito_king", "mosquito_swarm", "mosquito_kingdom", "lightning_bug", "fireworks"]:
		run = fixture(id)
		strike(run)
		check(not run.seekers.is_empty(), "Seeking attack spawns: " + id)
		run._update_seekers(1.0)
		check(run.enemies.any(func(e): return e.hp < 999985), "Seeking attack lands: " + id)
	run = fixture("nosferatu")
	run.wall(run.balls[0])
	check(run.seekers.size() == 1 and run.seekers[0].kind == "bat", "Nosferatu bounce spawns one bat")
	run._update_seekers(1.0)
	check(run.balls.any(func(b): return b.element == "vampire_lord"), "Bat converts to Vampire Lord")
func _test_area_and_timers() -> void:
	for id in ["bomb", "nuclear_bomb", "holy_laser", "x_ray", "laser_beam", "radiation_beam", "flash"]:
		var run = fixture(id)
		strike(run)
		check(run.enemies.slice(1).any(func(e): return e.hp < 1000000), "Area effect reaches another target: " + id)
		if id == "nuclear_bomb": check(run.enemies[3].radiation_stacks == 1 and is_inf(run.enemies[3].radiation), "Nuclear radiation affects field permanently")
	for id in ["landslide", "armageddon"]:
		var run = fixture(id)
		strike(run)
		check(run.balls[0].dead and run.hazards.size() == 1 and run.hazards[0].life == 5, "Lingering impact: " + id)
		var hp: float = run.enemies[1].hp
		run._update_hazards(0.1)
		check(run.enemies[1].hp < hp, "Lingering area damage: " + id)
	for id in ["inferno", "brimstone", "sun", "satan", "sandstorm", "storm", "magma", "swamp", "glacier", "catapult", "flesh_mound", "time_bomb"]:
		var run = fixture(id)
		RonkeEvolvedEffects.tick_ball(run, run.balls[0], 3.1 if id == "time_bomb" else 1.6)
		check(not run.hazards.is_empty() or run.balls.size() > 1 or run.enemies.any(func(e): return e.hp < 1000000 or e.burn > 0), "Timer action: " + id)
	var run = fixture("time_bomb")
	RonkeEvolvedEffects.tick_ball(run, run.balls[0], 3.1)
	var hp: float = run.enemies[1].hp
	run._update_hazards(1.0)
	check(run.enemies[1].hp == hp, "Time bomb waits before detonation")
	run._update_hazards(1.1)
	check(run.enemies[1].hp < hp, "Time bomb delayed explosion")
