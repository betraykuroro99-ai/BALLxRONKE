extends SceneTree
var failures: Array[String] = []
var checks = 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("DEFENSE: " + message)
func fixture(items: Array) -> RonkeRun:
	var run = RonkeRun.new()
	run.passives = items
	run.enemies.clear()
	run._add_enemy(Vector2(300, 650), 40, 100000, "moss", 0)
	return run
func _run() -> void:
	var run = fixture(["breastplate"])
	run.hurt(10)
	check(run.player.hp == 91 and run.damage_taken == 9, "Breastplate reduces actual and reported damage")
	run = fixture(["protective_charm"])
	run.protective_charges = 1
	run.hurt(10)
	check(run.protective_charges == 0 and run.player.hp == 100, "Protective Charm absorbs one hit")
	run.practice = true
	for _i in range(599): run.advance(0.1)
	check(run.protective_charges == 0, "Charm cannot recharge before sixty seconds")
	run.advance(0.1)
	run.advance(0.1)
	check(run.protective_charges == 1, "Charm recharges after sixty seconds")
	run = fixture(["crown_of_thorns"])
	run.hurt(1, "projectile")
	check(not run.enemies[0].dead, "Crown does not trigger on distant projectile damage")
	run._add_enemy(Vector2(100, 200), 40, 100000, "moss", 0)
	run.player.invincible = 0
	run.hurt(1, "impact")
	check(run.enemies[0].dead, "Crown triggers on close combat")
	check(run.enemies[1].dead, "Crown destroys second nearest enemy even when farther away")
	for item in ["hand_mirror", "lovers_quiver"]:
		run = fixture([item])
		run.player.hp = 50
		var success = false
		for _i in range(60):
			run.player.invincible = 0
			run.player.hp = 50
			run.bullets = [{"pos": run.player.pos, "velocity": Vector2.DOWN * 100, "radius": 5, "damage": 1, "dead": false}]
			run.advance(0.01)
			if item == "hand_mirror" and not run.bullets.is_empty() and run.bullets[0].get("ally", false):
				success = true
				check(run.bullets[0].velocity.y < 0 and run.bullets[0].damage >= 20 and run.player.hp == 50, "Mirror reverses projectile and prevents its hit")
				break
			elif item == "lovers_quiver" and run.player.hp == 51:
				success = true
				break
		check(success, "Defensive projectile proc: " + item)
	run = fixture(["bandage_roll"])
	run.heal(1)
	check(run.balls.is_empty(), "Full-health healing does not create babies")
	run.player.hp = 90
	run.heal(1)
	check(run.balls.size() in [1, 2], "Actual healing releases Bandage Roll babies")
	run = fixture(["bottled_tornado"])
	run.add_ball(Vector2(300, 400), Vector2.UP, "dark", 1, false)
	run.return_ball(run.balls[0])
	check(run.balls.size() == 1, "Self destruction is not a catch")
	var caught = run.add_ball(Vector2(300, 400), Vector2.UP, "fire", 1, false)
	run.return_ball(caught, true)
	check(run.balls.filter(func(b): return b.element == "baby").size() in [1, 2, 3], "Special catch releases Tornado babies")
	run = fixture(["magnet"])
	run.add_ball(run.player.pos + Vector2(65, 0), Vector2.DOWN, "baby")
	run._update_ball(run.balls[0], 0.001)
	check(run.balls[0].dead, "Magnet extends catch distance")
	run = fixture(["magic_staff"])
	check(is_equal_approx(run.area_multiplier(), 1.2), "Magic Staff changes area damage only")
	var hoarder = RonkeRun.new("hoary_hoarder")
	for id in RonkeData.all().passives.keys().slice(0, 10):
		hoarder.passives.append(id)
		hoarder.passive_levels[id] = 1
	for _i in range(50):
		check(hoarder.get_choices().all(func(c): return not c.has("passive")), "Full Hoarder cannot exceed ten passive slots")
	var run2 = fixture([])
	run2.elements = ["succubus"]
	run2.player.hp = 90
	run2.enemies[0].charm = 9
	run2.add_ball(run2.enemies[0].pos, Vector2.UP, "succubus", 1, false)
	var hp: float = run2.enemies[0].hp
	run2._update_ball(run2.balls[0], 0.001)
	check(run2.player.hp == 91 and run2.enemies[0].hp == hp, "Succubus collides with charmed ally to heal without hurting it")
	if failures.is_empty():
		print("PASS: defenses and equipment / ", checks, " checks")
		quit()
	else:
		print("FAIL: ", failures.size(), " / ", checks)
		quit(1)
