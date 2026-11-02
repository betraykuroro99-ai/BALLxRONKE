extends SceneTree
var failures: Array[String] = []
var checks = 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("STABILITY: " + message)
func fixture(id: String = "warrior") -> RonkeRun:
	var run = RonkeRun.new(id, 0, 7799, {}, true)
	run.enemies.clear()
	run.balls.clear()
	run.events.clear()
	run.stats.crit = 0
	run._add_enemy(Vector2(300, 220), 40, 1000000, "moss", 0)
	return run
func _run() -> void:
	_test_levels()
	_test_offers_and_ammo()
	_test_death_order()
	_test_characters()
	_test_geometry()
	_test_clocks()
	_test_allies()
	_test_limits()
	if failures.is_empty():
		print("PASS: stability and interaction regression / ", checks, " checks")
		quit()
	else:
		print("FAIL: ", failures.size(), " / ", checks)
		quit(1)
func _test_levels() -> void:
	for id in RonkeData.all().ball_rules:
		var data: Dictionary = RonkeData.all().ball_rules[id]
		check(data.levels.size() == 3, "Three explicit parameter levels: " + id)
		for level in range(1, 4):
			var run = fixture()
			run.element_levels[id] = level
			var ball = run.add_ball(Vector2(300, 220), Vector2.UP, id, 1, false)
			check(ball.level == level and ball.parameters == data.levels[level - 1], "Launch snapshots rules: " + id + str(level))
			RonkeEvolvedEffects.on_launch(run, ball)
			run.hit(run.enemies[0], ball)
			run._tick_statuses(run.enemies[0], 0.1)
			run._update_hazards(0.1)
			run._update_seekers(0.1)
	var run = fixture()
	run.element_levels.fire = 1
	var old_ball = run.add_ball(Vector2(100, 300), Vector2.UP, "fire", 1, false)
	run.element_levels.fire = 3
	var new_ball = run.add_ball(Vector2(100, 300), Vector2.UP, "fire", 1, false)
	check(old_ball.parameters.duration == 3 and new_ball.parameters.duration == 5, "Flying balls retain their launch level after an upgrade")
	check(old_ball.damage == new_ball.damage, "No invented universal impact multiplier per ball level")
	run = fixture()
	run.element_levels.bleed = 3
	var ball = run.add_ball(Vector2(300, 220), Vector2.UP, "bleed", 1, false)
	run.hit(run.enemies[0], ball)
	check(run.enemies[0].bleed_stacks == 4, "Level-three Bleed adds four stacks")
	for _i in range(5): run.hit(run.enemies[0], ball)
	check(run.enemies[0].bleed_stacks == 14, "Level-three Bleed cap fourteen")
	run = fixture()
	run.element_levels.stone = 3
	ball = run.add_ball(Vector2(300, 220), Vector2.UP, "stone", 1, false)
	check(ball.damage == 60, "Level-three Stone starts at four-times impact")
	run.hit(run.enemies[0], ball)
	check(is_equal_approx(ball.stone_scale, 2.8), "Level-three Stone erosion is thirty percent")
	run.element_levels.black_hole = 3
	check(run.ball_cooldown("black_hole") == 5, "Level-three Black Hole reload")
	check(RonkeBallRules.parameters("mosquito_king", 3).heal == 2, "Level-three seeking kill heal")
func _test_offers_and_ammo() -> void:
	var run = fixture()
	run.elements = ["iron", "dark", "ghost"]
	run.element_levels = {"iron": 3, "dark": 3, "ghost": 3}
	var offers = run.get_choices()
	var names: Array = []
	for offer in offers:
		if offer.has("fusion"): names.append(offer.fusion)
	check(names.count("assassin") == 1, "Alternate recipes never duplicate the same evolution offer")
	run.player.ammo = 6
	for _i in range(3): run.add_ball(Vector2(100, 300), Vector2.UP, "baby", 1, true)
	run.phase = "upgrade"
	run.choices = [{"id": "capacity", "name": "capacity"}]
	run.choose_upgrade(0)
	check(run.player.capacity == 11 and run.player.ammo == 8 and run._refundable_count() == 3, "Capacity grants two charges without duplicating flying ammo")
	for ball in run.balls.duplicate(): run.return_ball(ball)
	check(run.player.ammo == 11, "Every owned baby refunds at most once")
	for ball in run.balls.duplicate(): run.return_ball(ball)
	check(run.player.ammo == 11, "Repeated return is idempotent")
func _test_death_order() -> void:
	for element in ["maggot", "egg", "mosquito_swarm", "fireworks", "bomb", "time", "voluptuous_egg_sac"]:
		var run = fixture()
		run.enemies[0].hp = 1
		var ball = run.add_ball(Vector2(300, 220), Vector2.UP, element, 1, false)
		run.hit(run.enemies[0], ball)
		check(run.kills == 1 and run.enemies[0].dead and run.pending_deaths.is_empty(), "One finalized lethal impact: " + element)
		if element in ["maggot", "egg", "voluptuous_egg_sac"]: check(run.balls.size() > 1, "Lethal hit still releases children: " + element)
		elif element in ["mosquito_swarm", "fireworks"]: check(not run.seekers.is_empty(), "Lethal hit still releases seekers: " + element)
		elif element == "bomb": check(ball.dead, "Bomb self-destructs on lethal impact")
		elif element == "time": check(run.hazards.size() == 1, "Time snare survives a lethal impact")
		run.kill(run.enemies[0])
		check(run.kills == 1, "Death event cannot run twice: " + element)
	var run = fixture()
	run.enemies[0].hp = 1
	run.enemies[0].bleed_stacks = 8
	var ball = run.add_ball(Vector2(300, 220), Vector2.UP, "egg", 1, false)
	run.hit(run.enemies[0], ball)
	check(ball.dead and run.balls.size() >= 3 and run.kills == 1, "A bleed-triggered death does not cancel Egg Sac impact effects")
func _test_characters() -> void:
	var run = fixture("empty_nester")
	run.shoot(Vector2(300, 100))
	check(run.balls.size() == 3, "Empty Nester starts with three live copies independent of equipment slots")
	run.return_ball(run.balls[0])
	run.shoot(Vector2(300, 100))
	check(run._active_special_count() == 3, "Empty Nester refills individual available instance slots")
	run.spawn_baby(Vector2(100, 300), Vector2.UP)
	check(run.balls.any(func(b): return b.element == "baby"), "Empty Nester permits babies generated by effects")
	run.elements = ["ghost", "fire", "iron"]
	run.recall_balls()
	for ball in run.balls.duplicate(): run.return_ball(ball)
	run.shoot(Vector2(300, 100))
	check(run._active_special_count() == 3, "Collecting extra ball types does not shrink Nester's instance pool")
	run = fixture("makeshift_sisyphus")
	var ball = run.add_ball(Vector2(300, 220), Vector2.UP, "erosion", 1, false)
	var hp: float = run.enemies[0].hp
	run.hit(run.enemies[0], ball)
	check(run.enemies[0].hp == hp, "Erosion's base health-percentage damage is not mislabeled as status damage")
	run = fixture()
	run.elements = ["cell"]
	run.shoot(Vector2(300, 100))
	var original: Dictionary = run.balls[0]
	run.clone_ball(original, run.enemies[0], 2)
	run.return_ball(original)
	check(run.ready_specials().has("cell"), "Spawned clones do not lock the original special reload")
	run = fixture()
	var parent = run.add_ball(Vector2(300, 220), Vector2.UP, "cell", 1, false)
	run.clone_ball(parent, run.enemies[0], 2)
	var child: Dictionary = run.balls.back()
	var health: float = run.enemies[0].hp
	run._update_ball(child, 0.001)
	check(run.enemies[0].hp == health, "New clone does not immediately hit its birth enemy again")
func _test_geometry() -> void:
	var hit = RonkeCombatGeometry.sweep_circle_box(Vector2(0, 100), Vector2(500, 100), 4, Vector2(250, 100), 0.5)
	check(not hit.is_empty() and hit.normal == Vector2.LEFT, "Swept collision catches a thin enemy at high speed")
	hit = RonkeCombatGeometry.sweep_circle_box(Vector2(130, 130), Vector2(126, 126), 5, Vector2(100, 100), 20)
	check(hit.is_empty(), "Rounded-corner sweep avoids an expanded-box false hit")
	for crew in ["warrior", "repentant", "physicist", "tunneller", "flagellant"]:
		var run = fixture(crew)
		run.enemies[0].width = 1
		var ball = run.add_ball(Vector2(100, 220), Vector2.RIGHT, "baby", 1, false)
		ball.velocity = Vector2.RIGHT * 2400
		var hp: float = run.enemies[0].hp
		run._update_ball(ball, 0.1)
		check(run.enemies[0].hp < hp, "Fast ball cannot tunnel through thin target: " + crew)
	var run = fixture()
	run.enemies[0].pos = Vector2(300, 400)
	run._add_enemy(Vector2(300, 200), 40, 1000000, "moss", 0)
	var ball = run.add_ball(Vector2(300, 100), Vector2.DOWN, "dark", 1, false)
	ball.velocity = Vector2.DOWN * 2400
	run._update_ball(ball, 0.2)
	check(run.enemies[1].hp < 1000000 and run.enemies[0].hp == 1000000, "Nearest swept contact wins regardless of enemy-array order")
	run = fixture()
	ball = run.add_ball(Vector2(300, 220), Vector2.RIGHT, "ghost", 1, false)
	run._update_ball(ball, 0.001)
	var hp: float = run.enemies[0].hp
	run._update_ball(ball, 0.001)
	check(run.enemies[0].hp == hp, "Piercing contact does not repeatedly hit while remaining inside the same enemy")
	check(is_equal_approx(RonkeBallRules.geometry("baby", 58), 4) and is_equal_approx(RonkeBallRules.geometry("fire", 58), 5.5), "Collision sizes remain explicit and tile-relative")
func _test_clocks() -> void:
	var results: Array = []
	for fps in [30, 60, 120, 144]:
		var run = fixture()
		run.add_ball(Vector2(100, 500), Vector2(0.4, -1), "ghost", 1, false)
		for _i in range(fps * 2): run.advance(1.0 / fps)
		results.append({"time": run.time, "pos": run.balls[0].pos})
	for result in results:
		check(is_equal_approx(result.time, 2) and result.pos.distance_to(results[0].pos) < 0.001, "Fixed simulation is invariant across frame rates")
	var run = fixture()
	run.advance(1.0 / 240, {"dash": true, "move": Vector2.RIGHT})
	check(run.dash_count == 0, "Input pulse waits for the next simulation step")
	run.advance(1.0 / 240, {"move": Vector2.RIGHT})
	check(run.dash_count == 1, "Input pulse survives a frame without a simulation step")
	run = fixture("tactician")
	run.practice = false
	run.turn_phase = "aim"
	run.apply_status(run.enemies[0], "poison", 6, 3, 5)
	run.special_cooldowns.iron = 1
	run.add_hazard("landslide", Vector2(300, 220), 100, 5, 10)
	var hp: float = run.enemies[0].hp
	run.advance(0.1)
	check(run.enemies[0].hp == hp and run.special_cooldowns.iron == 1 and run.hazards[0].life == 5, "Tactician aim pauses field status, reload and hazard clocks together")
	run.turn_phase = "enemy"
	run.enemy_turn_left = 0.4
	run.advance(0.1)
	check(run.enemies[0].hp < hp and run.special_cooldowns.iron < 1 and run.hazards[0].life < 5, "Tactician enemy phase advances field clocks")
	run = fixture()
	run.timestop_left = 1
	run.bullets.append({"pos": Vector2(100, 100), "velocity": Vector2.DOWN * 1000, "radius": 5, "damage": 10, "dead": false})
	run.advance(0.1)
	check(run.bullets[0].pos == Vector2(100, 100), "Time stop freezes hostile projectiles")
	run = fixture()
	run.practice = false
	run.xp = run.xp_needed - 2
	run.enemies[0].hp = 1
	run.add_ball(run.enemies[0].pos, Vector2.UP, "baby", 1, false)
	run._add_enemy(Vector2(100, 300), 40, 1000000, "moss", 0)
	var second: Dictionary = run.enemies.back()
	run.add_ball(second.pos, Vector2.UP, "baby", 1, false)
	run.advance(1.0 / 60.0)
	check(run.phase == "upgrade" and second.hp == 1000000, "A level-up stops later ball updates at the completed hit boundary")
	var before: float = run.time
	run.advance(0.1)
	check(run.time == before and second.hp == 1000000, "Upgrade pause stops all simulation clocks and damage")
func _test_allies() -> void:
	var run = fixture()
	var enemy: Dictionary = run.enemies[0]
	enemy.zombie_infected = true
	run.remember_effect(enemy, "zombie", {"chance": 1.0})
	run.kill(enemy)
	check(run.allies.size() == 1 and run.hazards.is_empty(), "Zombie death creates a piece, not a temporary damage area")
	var ally: Dictionary = run.allies[0]
	var pos: Vector2 = ally.pos
	run._update_allies(0.1, 0.1)
	check(ally.pos.y < pos.y, "Zombie moves up the field")
	run._add_enemy(ally.pos + Vector2(0, -ally.radius), 40, 1000, "moss", 30)
	var target: Dictionary = run.enemies.back()
	var hp: float = target.hp
	run._update_allies(0.1, 0.1)
	check(target.hp < hp and ally.hp < ally.max_hp, "Zombie exchanges actual melee damage")
	var y: float = target.pos.y
	run._update_enemies(0.1, 0.1)
	check(target.pos.y == y, "Zombie piece blocks enemy movement")
	run.bullets.append({"pos": ally.pos, "velocity": Vector2.DOWN, "radius": 5, "damage": ally.hp + 1, "dead": false})
	run.advance(0.01)
	check(ally.dead, "Hostile projectiles can kill a zombie piece")
func _test_limits() -> void:
	var run = fixture()
	for _i in range(run.MAX_BALLS): run.add_ball(Vector2(50, 200), Vector2.UP, "baby", 1, false)
	var ammo: int = run.player.ammo
	run.shoot(Vector2(300, 100))
	check(run.player.ammo == ammo and run.launch_groups.is_empty() and run.special_inflight.is_empty(), "A full ball limit does not charge ammo or lock an unlaunched special")
	var ball: Dictionary = run.balls[0]
	run.clone_ball(ball, run.enemies[0], 2)
	check(ball.clone_depth == 0 and run.balls.size() == run.MAX_BALLS, "Rejected clone does not spend a division or overflow")
	run.return_ball(ball)
	check(not run.add_ball(Vector2(50, 200), Vector2.UP, "fire", 1, false).is_empty(), "Dead ball frees capacity immediately")
	for _i in range(run.MAX_HAZARDS): run.add_hazard("time_snare", Vector2(100, 100), 30, 5)
	var original: Dictionary = run.hazards[0]
	run.add_hazard("landslide", Vector2(100, 100), 30, 5)
	check(run.hazards.size() == run.MAX_HAZARDS and run.hazards[0] == original and run.rejected_spawns.hazard == 1, "Hazard cap rejects new effects without erasing existing effects")
	for _i in range(run.MAX_SEEKERS + 1): run.spawn_seeker(Vector2(100, 100), "mosquito")
	check(run.seekers.size() == run.MAX_SEEKERS and run.rejected_spawns.seeker == 1, "Seeking attacks are bounded and admission failures counted")
	for _i in range(run.MAX_ALLIES + 1): run.spawn_ally(run.enemies[0])
	check(run.allies.size() == run.MAX_ALLIES and run.rejected_spawns.ally == 1, "Ally pieces have a safe admission limit")
