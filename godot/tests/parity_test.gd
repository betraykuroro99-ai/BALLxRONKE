extends SceneTree

var failures: Array[String] = []
var checks = 0

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("PARITY: " + message)

func fixture(id: String = "warrior", kind: String = "moss", pos: Vector2 = Vector2(300, 220)) -> RonkeRun:
	var run = RonkeRun.new(id, 0, 4242)
	run.enemies.clear()
	run.events.clear()
	run._add_enemy(pos, 40, 1000000, kind, 0)
	run.stats.crit = 0.0
	return run

func _run() -> void:
	_test_loadouts()
	_test_balls()
	_test_statuses()
	_test_characters()
	_test_turns()
	_test_defenses()
	if failures.is_empty():
		print("PASS: reference-mechanic parity / ", checks, " checks")
		quit(0)
	else:
		print("FAIL: ", failures.size(), " parity assertions / ", checks)
		quit(1)

func _test_loadouts() -> void:
	var starters = {"warrior": "bleed", "itchy_finger": "fire", "repentant": "frost", "cohabitants": "brood", "cogitator": "laser", "embedded": "poison", "shade": "dark", "shieldbearer": "iron", "spendthrift": "vampire", "juggler": "lightning", "empty_nester": "ghost", "flagellant": "egg", "makeshift_sisyphus": "earth", "physicist": "light", "tactician": "iron", "radical": "wind", "falconer": "lightning", "carouser": "charm", "tunneller": "earth", "tiptoer": "laser_h", "ballbearer": "stone"}
	for id in starters:
		var run = RonkeRun.new(id)
		check(run.elements == [starters[id]], "Starter " + id)
		check(run.available, "Available " + id)
	var base_count = 0
	for value in RonkeData.all().elements.values():
		if value.get("tier") == "base":
			base_count += 1
	check(base_count == 21, "All 21 base-ball types")
	var run = RonkeRun.new("hoary_hoarder")
	check(run.elements.is_empty() and run.special_slots == 2 and run.passive_slots == 10 and run.player.capacity == 9, "Hoarder inventory trade-off, not ammo buff")
	run = RonkeRun.new("ballbearer")
	check(run.special_slots == 10 and run.passive_slots == 0 and run.player.capacity == 9, "Ballbearer inventory trade-off, not ammo buff")
	for choice in run.get_choices():
		check(not choice.has("passive"), "Ballbearer cannot obtain passive items")
	run = RonkeRun.new("false_messiah")
	run.advance(0.1, {"shoot": true})
	check(not run.available and run.phase == "unavailable" and run.balls.is_empty(), "False Messiah disabled without an offline substitute")
	check(RonkeSave.sanitize({"last_crew": "false_messiah"}).last_crew == "warrior", "Disabled saved runner falls back safely")
	run = fixture("cohabitants")
	run.shoot(Vector2(330, 100))
	var specials = run.balls.filter(func(ball): return ball.group > 0)
	check(specials.size() == 2 and is_equal_approx(specials[0].damage, 7.5) and is_equal_approx(specials[1].damage, 7.5), "Cohabitants mirrored half damage")
	check(is_equal_approx(specials[0].velocity.x, -specials[1].velocity.x), "Cohabitants mirrored trajectories")
	run.return_ball(specials[0])
	check(not run.ready_specials().has("brood"), "First mirrored return does not reload special")
	run.return_ball(specials[1])
	check(run.ready_specials().has("brood"), "Both mirrored returns reload special")
	run = fixture("spendthrift")
	run.elements = ["vampire", "fire", "ghost"]
	run.shoot(Vector2(300, 100))
	var types: Array = []
	for ball in run.balls:
		if ball.group > 0:
			types.append(ball.element)
	check(types == run.elements and run.player.ammo == 0, "Spendthrift fires available collection and baby volley")
	run = fixture("empty_nester")
	run.shoot(Vector2(300, 100))
	check(run.balls.size() > 1 and run.balls.all(func(ball): return ball.element == "ghost"), "Empty Nester special copies, no normal babies")
	check(run.balls.size() <= run.special_slots, "Empty Nester concurrent special budget")
	run = fixture()
	run.elements = ["fire", "poison"]
	run.element_levels = {"fire": 1, "poison": 1}
	check(run.get_choices().all(func(choice): return not choice.has("fusion")), "Evolution requires levelled ingredients")
	run.element_levels = {"fire": 3, "poison": 3}
	check(run.get_choices()[0].get("fusion") == "brimstone", "Correct Burn/Poison evolution")

func _test_balls() -> void:
	var run = fixture()
	for id in ["stone", "iron", "dark", "flesh", "wind", "ghost"]:
		run.add_ball(Vector2(300, 220), Vector2.UP, id)
	var stone: Dictionary = run.balls[0]
	check(stone.damage == 45, "Stone starts at triple base damage")
	run.hit(run.enemies[0], stone)
	check(is_equal_approx(stone.stone_scale, 1.8), "Stone erodes 40 percent")
	for _i in range(10):
		run.hit(run.enemies[0], stone)
	check(is_equal_approx(stone.stone_scale, 0.5), "Stone minimum half base damage")
	check(run.balls[1].damage == 30 and is_equal_approx(run.balls[1].velocity.length(), 336), "Iron double damage and 40 percent slower")
	run.wall(run.balls[1])
	check(run.balls[1].damage == 30, "Iron has no invented bounce-damage perk")
	run.hit(run.enemies[0], run.balls[2])
	check(run.balls[2].dead and run.balls[2].damage == 45 and run.ball_cooldown("dark") == 3, "Dark triple impact, destruction and cooldown")
	run.wall(run.balls[3])
	check(is_equal_approx(run.balls[3].velocity.length(), 700), "Flesh gains 25 percent speed per bounce")
	check(run.balls[4].damage == 11.25 and run.balls[4].pierce == -1 and run.balls[5].pierce == -1, "Wind damage penalty and unlimited Wind/Ghost piercing")
	for horizontal in [false, true]:
		run = fixture()
		run._add_enemy(Vector2(300, 290), 40, 1000, "moss", 0)
		run._add_enemy(Vector2(370, 220), 40, 1000, "moss", 0)
		run.add_ball(Vector2(300, 220), Vector2.UP, "laser_h" if horizontal else "laser")
		run.hit(run.enemies[0], run.balls[0])
		check((run.enemies[2].hp < 1000) == horizontal and (run.enemies[1].hp < 1000) != horizontal, "Laser row/column discrimination")
	run = fixture()
	run._add_enemy(Vector2(380, 300), 40, 1000, "moss", 0)
	run.add_ball(Vector2(300, 220), Vector2.UP, "earth")
	run.hit(run.enemies[0], run.balls[0])
	check(run.enemies[1].hp < 1000, "Earthquake includes tile-square corners")
	run = fixture()
	for x in [240, 270, 330, 360]:
		run._add_enemy(Vector2(x, 250), 20, 1000, "moss", 0)
	run.add_ball(Vector2(300, 220), Vector2.UP, "lightning")
	run.hit(run.enemies[0], run.balls[0])
	check(run.enemies.slice(1).filter(func(enemy): return enemy.hp < 1000).size() == 3, "Lightning selects at most three additional targets")
	run = fixture()
	run.add_ball(Vector2(300, 220), Vector2.UP, "egg")
	run.hit(run.enemies[0], run.balls[0])
	check(run.balls[0].dead and run.balls.size() >= 3 and run.balls.size() <= 5, "Egg breaks into two to four babies")
	run = fixture()
	run.add_ball(Vector2(300, 220), Vector2.UP, "cell")
	run.hit(run.enemies[0], run.balls[0])
	run.hit(run.enemies[0], run.balls[0])
	run.hit(run.enemies[0], run.balls[0])
	check(run.balls.size() == 3 and run.balls[0].clone_depth == 2, "Cell limits each lineage to two divisions")
	run = fixture()
	run.add_ball(Vector2(300, 220), Vector2.UP, "time")
	run.hit(run.enemies[0], run.balls[0])
	run._update_hazards(0.1)
	check(run.balls[0].dead and run.hazards.size() == 1 and run.enemies[0].freeze > 0, "Time creates a freezing snare")
	check(is_equal_approx(run.hazards[0].life, 1.9), "Time snare has two-second lifetime")

func _test_statuses() -> void:
	var run = fixture()
	run.add_ball(Vector2(300, 220), Vector2.UP, "bleed")
	run.hit(run.enemies[0], run.balls[0])
	var hp: float = run.enemies[0].hp
	run.hit(run.enemies[0], run.balls[0])
	check(is_equal_approx(hp - run.enemies[0].hp, 17) and run.enemies[0].bleed_stacks == 4, "Bleed adds two stacks and triggers existing stacks on hit")
	for _i in range(8):
		run.hit(run.enemies[0], run.balls[0])
	check(run.enemies[0].bleed_stacks == 8, "Bleed stack limit")
	for _i in range(8):
		run.apply_status(run.enemies[0], "burn", 3, 6, 3)
		run.apply_status(run.enemies[0], "poison", 6, 2, 5)
	check(run.enemies[0].burn_stacks == 3 and run.enemies[0].poison_stacks == 5, "Burn/Poison stack limits")
	hp = run.enemies[0].hp
	run._tick_statuses(run.enemies[0], 1.0)
	check(is_equal_approx(hp - run.enemies[0].hp, 28), "Stacked status DPS")
	run = fixture("warrior", "prism")
	run.enemies[0].speed = 10
	run.enemies[0].fire = 0.01
	run.apply_status(run.enemies[0], "freeze", 5)
	var y: float = run.enemies[0].pos.y
	run._update_enemies(0.1, 0.1)
	check(run.enemies[0].pos.y == y and run.bullets.is_empty(), "Freeze stops movement and firing")
	hp = run.enemies[0].hp
	run.damage(run.enemies[0], 10)
	check(is_equal_approx(hp - run.enemies[0].hp, 12.5), "Frozen vulnerability adds 25 percent")
	run = fixture("warrior", "prism")
	run._add_enemy(Vector2(350, 220), 40, 1000, "moss", 0)
	run.apply_status(run.enemies[0], "charm", 5)
	run.enemies[0].speed = 10
	run._update_enemies(0.1, 0.1)
	check(run.enemies[0].pos.y < 220 and run.bullets.size() == 1 and run.bullets[0].ally, "Charmed enemy reverses and attacks enemies")
	run = fixture()
	run.player.hp = 10
	run.add_ball(Vector2(300, 220), Vector2.UP, "vampire")
	var proc_count = 0
	for _i in range(2000):
		run.player.hp = 10
		run.hit(run.enemies[0], run.balls[0])
		if run.player.hp == 11:
			proc_count += 1
	check(proc_count >= 50 and proc_count <= 140, "Vampire uses approximately 4.5 percent healing procs, not guaranteed healing")
	run = fixture("makeshift_sisyphus")
	hp = run.enemies[0].hp
	run.damage(run.enemies[0], 20)
	check(run.enemies[0].hp == hp, "Sisyphus suppresses impact damage")
	run.apply_status(run.enemies[0], "poison", 6, 2, 5)
	run._tick_statuses(run.enemies[0], 1)
	check(is_equal_approx(hp - run.enemies[0].hp, 8), "Sisyphus quadruples status damage")
	hp = run.enemies[0].hp
	run.splash(run.enemies[0].pos, 60, 10)
	check(is_equal_approx(hp - run.enemies[0].hp, 40), "Sisyphus quadruples area damage")
	run.spawn_baby(Vector2(300, 220), Vector2.UP)
	check(run.balls.size() == 1 and not run.balls[0].refundable, "Sisyphus permits effect-generated babies without ordinary ammo")
	hp = run.enemies[0].hp
	run.hit(run.enemies[0], run.balls[0])
	check(run.enemies[0].hp == hp, "Sisyphus effect-generated baby has no direct damage")

func _test_characters() -> void:
	var run = fixture("repentant")
	run.add_ball(Vector2(300, 192), Vector2.DOWN, "baby")
	var ball: Dictionary = run.balls[0]
	var initial: float = ball.damage
	run._update_ball(ball, 0.01)
	check(is_equal_approx(ball.damage, initial * 1.05), "Repentant enemy bounce adds five percent")
	ball.pos = Vector2(300, 20)
	ball.velocity = Vector2.UP * 560
	run._update_ball(ball, 0.01)
	check(ball.returning, "Repentant far wall starts piercing recall")
	run = fixture("embedded")
	run.add_ball(Vector2(100, 400), Vector2.UP, "poison")
	check(run.balls[0].embedded_pierce, "Embedded starts with unbounded enemy piercing")
	run.wall(run.balls[0])
	check(not run.balls[0].embedded_pierce, "Embedded piercing ends at a wall")
	run = fixture("itchy_finger")
	run.advance(0.1, {})
	check(run.shot_count > 0 and is_equal_approx(run.stats.interval, 0.14), "Itchy Finger forces double-rate firing")
	run = fixture("shade")
	run.stats.crit = RonkeRun.new("shade").stats.crit
	run.shoot(Vector2(300, 220))
	check(run.balls[0].pos.y == 35 and is_equal_approx(run.stats.crit, 0.1), "Shade rear launch and ten-percent base crit")
	run = fixture("juggler")
	run.shoot(Vector2(300, 220))
	ball = run.balls[0]
	var hp: float = run.enemies[0].hp
	run._update_ball(ball, 0.5)
	check(run.enemies[0].hp == hp and ball.air_time > 0, "Juggler cannot collide before landing")
	run._update_ball(ball, 0.06)
	check(ball.air_time == 0 and run.enemies[0].hp < hp, "Juggler lands then damages targets")
	run = fixture("physicist")
	run.add_ball(Vector2(100, 400), Vector2.RIGHT, "light")
	run._update_ball(run.balls[0], 0.1)
	check(run.balls[0].velocity.y < 0, "Physicist gravity points upward")
	run = fixture("falconer")
	run.shoot(Vector2(300, 220))
	var specials = run.balls.filter(func(b): return b.group > 0)
	check(specials.size() == 2 and specials[0].pos.x == 30 and specials[1].pos.x == 570 and specials[0].damage == 15, "Falconer twin origins without invented damage penalty")
	run = fixture("carouser")
	run.add_ball(Vector2(300, 690), Vector2.DOWN, "charm")
	run._update_ball(run.balls[0], 0.01)
	check(run.balls[0].orbit, "Carouser catches return trajectory into orbit")
	for id in ["tunneller", "flagellant"]:
		run = fixture(id)
		run.add_ball(Vector2(100, 810), Vector2.DOWN, "baby")
		ball = run.balls[0]
		for _i in range(40):
			ball.pos = Vector2(100, 810)
			ball.velocity = Vector2.DOWN * 560
			run._update_ball(ball, 0.01)
		check(not ball.dead and (ball.wraps >= 40 if id == "tunneller" else ball.velocity.y < 0), "No two-wrap/28-bounce forced return for " + id)
	run = fixture("tiptoer", "prism")
	run.enemies[0].fire = 0
	run._update_enemies(0.1, 0.1)
	check(run.bullets.is_empty() and not run.enemies[0].charging, "Tiptoer is undetected by ordinary shooters")
	for kind in ["boss", "miniboss"]:
		run = fixture("tiptoer", kind)
		run.enemies[0].fire = 0
		run._update_enemies(0.1, 0.1)
		check(not run.bullets.is_empty(), "Tiptoer detection exception for " + kind)
	run = fixture("radical")
	run.bullets.append({"pos": Vector2(300, 600), "velocity": Vector2(0, 300), "radius": 5, "damage": 10, "dead": false})
	run.advance(0.1, {"move": Vector2.RIGHT})
	check(run.player.pos.x < 300, "Radical chooses avoidance movement instead of relying on player input")

func _test_turns() -> void:
	var run = fixture("tactician")
	run.enemies[0].speed = 10
	var y: float = run.enemies[0].pos.y
	run.advance(0.1)
	check(run.turn_phase == "aim" and run.enemies[0].pos.y == y, "Tactician aim freezes enemies")
	run.advance(0.1, {"shoot": true, "aim": Vector2(300, 220)})
	check(run.turn_phase == "volley" and run.enemies[0].pos.y == y and run.player.ammo == 0, "Tactician launches full volley while enemies remain frozen")
	var x: float = run.player.pos.x
	run.advance(0.1, {"move": Vector2.RIGHT})
	check(run.player.pos.x == x, "Tactician cannot move during volley")
	run.recall_balls()
	for _i in range(160):
		run.advance(1.0 / 120, {"move": Vector2.RIGHT})
		if run.turn_phase == "aim":
			break
	check(run.turn_phase == "aim" and run.enemies[0].pos.y > y, "Volley return leads to enemy turn then player aim")

func _test_defenses() -> void:
	var run = fixture("shieldbearer")
	run.add_ball(Vector2(300, 700), Vector2.DOWN, "baby")
	var ball: Dictionary = run.balls[0]
	for _i in range(2):
		ball.pos = Vector2(300, 700)
		ball.velocity = Vector2.DOWN * 560
		ball.shield_cooldown = 0
		run._update_ball(ball, 0.04)
	check(ball.shield_catches == 2 and ball.velocity.y < 0, "Shield catches repeatedly with a frontal collider")
	run = fixture()
	run.add_ball(Vector2(100, 400), Vector2.UP, "baby")
	run.bullets.append({"pos": Vector2(100, 394), "velocity": Vector2.DOWN * 100, "radius": 5, "damage": 10, "dead": false})
	run._update_ball(run.balls[0], 0.001)
	check(run.bullets[0].dead, "Friendly balls intercept blockable hostile shots")
	run.protective_charges = 1
	var hp: float = run.player.hp
	run.hurt(10)
	check(run.player.hp == hp and run.protective_charges == 0, "Protective Charm blocks damage once")
