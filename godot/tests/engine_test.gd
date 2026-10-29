extends SceneTree

var failures: Array = []

func _init() -> void:
	call_deferred("_run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run_tests() -> void:
	RonkeSave.use_test_profile("engine")
	check(RonkeData.all().get("crew", []).size() == 23, "Expected 23 crew entries")
	for crew in RonkeData.all().crew:
		var run = RonkeRun.new(crew.id, 0, 4242)
		for tick in range(12000):
			if run.phase in ["victory", "defeat"]:
				break
			if run.phase == "upgrade":
				run.choose_upgrade(0)
			var enemy = run.nearest_threat()
			var target: Vector2 = enemy.pos if not enemy.is_empty() else Vector2(300, 100)
			run.advance(1.0 / 60.0, {"shoot": true, "aim": target, "move": Vector2(sin(tick / 160.0) * 0.5, 0), "surge": run.surge >= 100})
			for ball in run.balls:
				check(ball.pos.is_finite() and ball.velocity.is_finite(), "Invalid orb state: " + crew.id)
			run.drain_events()
		check(run.phase == "victory", "%s did not finish: %s, wave %d, kills %d" % [crew.id, run.phase, run.wave, run.kills])
		check(run.player.ammo >= 0 and run.balls.size() <= 96, "Invalid supply: " + crew.id)
		print("CREW ", crew.id, ": ", run.phase, " wave ", run.wave, " kills ", run.kills)
	_test_mechanics()
	_test_attack_warnings()
	_test_guardian_phases()
	_test_report()
	_test_save()
	_test_exports()
	if failures.is_empty():
		print("PASS: native Godot simulation, 23 full runs, mechanics, saves, and sprite resources.")
		quit(0)
	else:
		print("FAIL: ", failures.size(), " assertions")
		quit(1)

func _test_mechanics() -> void:
	var run = RonkeRun.new()
	run.xp = run.xp_needed
	run.check_level()
	var old_time = run.time
	run.advance(0.1, {"shoot": true})
	check(run.phase == "upgrade" and run.time == old_time, "Upgrade must freeze combat")
	check(not run.choose_upgrade(-1), "Invalid choice must be rejected")
	check(run.choose_upgrade(0) and run.phase == "playing", "Choice must resume combat")
	var automatic = RonkeRun.new("cogitator")
	automatic.xp = automatic.xp_needed
	automatic.check_level()
	for _i in range(11):
		automatic.advance(0.1)
	check(automatic.phase == "playing" and automatic.picks.size() == 1, "Automatic character chooses without player input")
	run = RonkeRun.new()
	run.elements = ["fire", "poison"]
	run.xp = run.xp_needed
	run.check_level()
	check(run.choices[0].get("fusion", "") == "toxic_sun", "Evolution must be offered")
	run.choose_upgrade(0)
	check(run.elements == ["toxic_sun"], "Evolution must replace its ingredients")
	run = RonkeRun.new()
	run.stats.bounce = 0.1
	run.add_ball(Vector2(580, 400), Vector2.RIGHT, "stone")
	var ball = run.balls[0]
	var value = ball.damage
	run.advance(1.0 / 60.0)
	check(ball.velocity.x < 0 and ball.damage > value, "Wall reflection/ricochet damage")
	run.player.ammo = 0
	ball.life = 0.001
	run.advance(0.01)
	check(run.player.ammo == 1, "Expired charge must return")
	run = RonkeRun.new()
	run.advance(1.0 / 60.0, {"dash": true, "move": Vector2.RIGHT})
	var hp = run.player.hp
	run.hurt(10)
	check(run.player.hp == hp, "Dash must grant invulnerability")
	run = RonkeRun.new()
	for _i in range(30000):
		if run.phase == "defeat":
			break
		run.advance(1.0 / 60.0)
	check(run.phase == "defeat", "Unanswered breaches must end the run")
	var reward = run.reward
	run.finish(true)
	check(run.phase == "defeat" and run.reward == reward, "Terminal state must be stable")
	for crew in RonkeData.all().crew:
		var path = "res://assets/crew/" + crew.id + ".png"
		var texture = load(path)
		check(texture is Texture2D and texture.get_width() == 1024 and texture.get_height() == 128, "Invalid sprite strip: " + crew.id)
		var frames = load("res://assets/animations/" + crew.id + ".tres")
		check(frames is SpriteFrames and frames.get_frame_count("walk") == 2 and frames.get_frame_count("throw") == 4, "Native animation resource: " + crew.id)
		var runner = load("res://scenes/runners/" + crew.id + ".tscn").instantiate()
		check(runner.get_node("AnimatedSprite2D").offset == Vector2(0, -56), "Native prefab anchor: " + crew.id)
		runner.free()

func _test_attack_warnings() -> void:
	for kind in ["prism", "boss"]:
		var run = RonkeRun.new()
		run.enemies.clear()
		run._add_enemy(Vector2(300, 200), 70, 500, kind, 0)
		var enemy: Dictionary = run.enemies[0]
		var duration = RonkeRun.BOSS_WINDUP if kind == "boss" else RonkeRun.PRISM_WINDUP
		enemy.fire = duration + 0.01
		run.drain_events()
		run._update_enemies(0.02, 0.02)
		check(enemy.charging and run.bullets.is_empty(), "Warning precedes volley: " + kind)
		check(run.drain_events().filter(func(e): return e.type == "windup").size() == 1, "One warning event: " + kind)
		var angle: float = enemy.attack_angle
		var preview = run.attack_directions(enemy)
		var remaining: float = enemy.fire
		run.player.pos.x = 80
		run._update_enemies(0.2, 0.0)
		check(enemy.fire == remaining and enemy.attack_angle == angle, "World freeze pauses warning: " + kind)
		run.phase = "upgrade"
		run.advance(0.1)
		check(enemy.fire == remaining, "Upgrade freezes warning: " + kind)
		run.phase = "playing"
		run._update_enemies(duration * 0.5, duration * 0.5)
		check(enemy.attack_angle == angle and run.bullets.is_empty(), "Warning locks aim without early fire: " + kind)
		run._update_enemies(duration * 0.5, duration * 0.5)
		check(run.bullets.size() == (3 if kind == "boss" else 1), "Expected volley size: " + kind)
		for i in range(run.bullets.size()):
			check(run.bullets[i].velocity.normalized().distance_to(preview[i]) < 0.0001, "Projectile follows warning lane: " + kind)
		check(not enemy.charging and enemy.fire > duration, "Warning resets after release: " + kind)
		# Destroying a charging shooter cancels its pending volley.
		run.bullets.clear()
		enemy.charging = true
		enemy.fire = 0.001
		run.kill(enemy)
		run._update_enemies(0.02, 0.02)
		check(run.bullets.is_empty(), "Destroyed shooter cannot release volley: " + kind)
	var breach = RonkeRun.new()
	breach.enemies.clear()
	breach._add_enemy(Vector2(300, 700), 50, 100, "prism", 0)
	breach.enemies[0].fire = 0
	breach._update_enemies(0.02, 0.02)
	check(breach.enemies[0].dead and breach.bullets.is_empty(), "Breached shooter cannot fire after removal")

func _test_guardian_phases() -> void:
	for world_index in range(3):
		for encounter in [5, 10]:
			var run = RonkeRun.new("warrior", world_index)
			run.enemies.clear()
			run.wave = encounter
			run._add_enemy(Vector2(300, 150), 110, 500, "boss", 0)
			var boss: Dictionary = run.enemies[0]
			var root = encounter == 10
			check(boss.guardian == ("rootheart" if root else "gatekeeper"), "Guardian identity comes from encounter, not HP")
			var windup = run.attack_windup(boss)
			boss.fire = windup + 0.01
			run.drain_events()
			run._update_enemies(0.02, 0.02)
			var preview = run.attack_directions(boss)
			check(preview.size() == (5 if root else 3), "Distinct first-phase volley sizes")
			boss.hp = boss.max_hp * 0.5
			run._update_enemies(0.01, 0.01)
			check(boss.boss_phase == 2 and boss.attack_phase == 1, "Phase transition preserves charging volley")
			check(run.drain_events().filter(func(e): return e.type == "boss_phase").size() == 1, "Single phase transition notification")
			for j in range(preview.size()):
				check(preview[j].distance_to(run.attack_directions(boss)[j]) < 0.0001, "Phase transition cannot change preview lanes")
			for _tick in range(12):
				if not run.bullets.is_empty():
					break
				run._update_enemies(0.1, 0.1)
			check(run.bullets.size() == preview.size(), "Charging volley retains its size at release")
			for j in range(run.bullets.size()):
				check(run.bullets[j].velocity.normalized().distance_to(preview[j]) < 0.0001, "Guardian volley follows every preview lane")
			check(run.drain_events().filter(func(e): return e.type == "boss_phase").is_empty(), "Phase notice is not repeated")
			for volley in [1, 2]:
				run.bullets.clear()
				boss.volley = volley
				boss.charging = false
				boss.fire = windup + 0.01
				run._update_enemies(0.02, 0.02)
				var expected = 7 if root and volley == 2 else 5
				check(run.attack_directions(boss).size() == expected and boss.attack_phase == 2, "Second phase widens future volleys")
				if root:
					check(boss.attack_pattern == ("root_aim" if volley == 1 else "root_spread"), "Rootheart alternates attack types")
					if volley == 2:
						check(absf(boss.attack_angle - PI / 2) < 0.0001, "Rootheart spread is centered downward")
				var lanes = run.attack_directions(boss)
				for _tick in range(12):
					if not run.bullets.is_empty():
						break
					run._update_enemies(0.1, 0.1)
				check(run.bullets.size() == expected, "Second-phase release matches preview size")
				for j in range(run.bullets.size()):
					check(run.bullets[j].velocity.normalized().distance_to(lanes[j]) < 0.0001, "Second-phase release follows warning")

func _test_report() -> void:
	var run = RonkeRun.new()
	run.enemies.clear()
	run.hurt(12, "projectile")
	run.hurt(100, "projectile")
	check(run.damage_taken == 12, "Blocked hits do not inflate damage taken")
	run.player.invincible = 0
	run.player.hp = 5
	run.hurt(99, "projectile")
	check(run.report().reason == "projectile" and run.damage_taken == 17, "Report tracks fatal cause and actual health lost")
	var reason = run.end_reason
	run.finish(true)
	check(run.end_reason == reason and not run.report().win, "Terminal cause cannot be overwritten")
	var terminal = RonkeRun.new()
	terminal.enemies.clear()
	terminal.player.hp = 1
	terminal._add_enemy(Vector2(300, 200), 50, 1, "moss", 0)
	terminal.add_ball(Vector2(300, 200), Vector2.UP, "stone")
	terminal.bullets.append({"pos": terminal.player.pos, "velocity": Vector2.ZERO, "radius": 5, "damage": 10, "dead": false})
	terminal.advance(0.01)
	check(terminal.phase == "defeat" and terminal.kills == 0 and terminal.reward == 2, "Fatal hit stops same-step kills from changing the report or reward")
	for kind in ["moss", "boss"]:
		var breach = RonkeRun.new()
		breach.enemies.clear()
		breach.player.hp = 5
		breach._add_enemy(Vector2(300, 710), 50, 100, kind, 0)
		breach._update_enemies(0.02, 0.02)
		check(breach.report().reason == ("guardian_breach" if kind == "boss" else "breach") and breach.breach_count == 1, "Breach outcome is identified: " + kind)
	run = RonkeRun.new()
	run.enemies.clear()
	run.surge = 100
	for _i in range(2):
		run.advance(0.02, {"dash": true, "surge": true, "shoot": true, "aim": Vector2(300, 100)})
	check(run.dash_count == 1 and run.surge_count == 1 and run.shot_count == 1, "Report counts performed actions, not repeated inputs")
	run._add_enemy(Vector2(300, 100), 110, 500, "boss", 0)
	run.kill(run.enemies[0])
	run.kill(run.enemies[0])
	check(run.guardians_defeated == 1, "Guardian defeat is counted once")
	run.finish(false, "abandoned")
	var report = run.report()
	report.elements.append("fire")
	check(not run.elements.has("fire"), "Report does not expose mutable loadout state")
	var progress = RonkeSave.fresh()
	progress.last_run = run.report()
	check(RonkeSave.write_progress(progress) == OK, "Expedition report saves")
	var loaded = RonkeSave.load_progress().last_run
	check(loaded.reason == "abandoned" and loaded.guardians == 1 and loaded.shots == 1, "Expedition report survives reload")
	check(RonkeSave.sanitize({}).last_run.is_empty(), "Existing saves without reports remain compatible")
	check(RonkeSave.sanitize_report({"crew": "missing"}).is_empty(), "Unknown report runner is rejected")
	var bad = RonkeSave.sanitize_report({"crew": "warrior", "world": INF, "damage_taken": -2, "elements": ["missing", "fire", "fire"], "picks": [null, "Power"]})
	check(bad.world == 0 and bad.damage_taken == 0 and bad.elements == ["fire"] and bad.picks == ["Power"], "Malformed report fields are validated")

func _test_save() -> void:
	var raw = {"version": 1, "shards": -20, "last_crew": "missing", "meta": {"power": 100}, "world": "invalid"}
	var clean = RonkeSave.sanitize(raw)
	check(clean.shards == 0 and clean.meta.power == 3 and clean.last_crew == "warrior" and clean.world == 0, "Save input validation")
	check(RonkeSave.sanitize({"volume": -4, "shake": 8}).volume == 0 and RonkeSave.sanitize({"shake": 8}).shake == 1, "Feedback values clamp safely")
	check(RonkeSave.sanitize({"volume": "bad", "shake": NAN}).shake == 0.5, "Invalid feedback values use defaults")
	var save = RonkeSave.fresh()
	save.shards = 42
	check(RonkeSave.write_progress(save) == OK, "Save write")
	check(RonkeSave.load_progress().shards == 42, "Save round trip")
	save.shards = 43
	check(RonkeSave.write_progress(save) == OK, "Second save creates backup")
	var file = FileAccess.open(RonkeSave.active_path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	var fallback = RonkeSave.load_progress()
	check(fallback is Dictionary and fallback.shards == 42, "Corrupt-save recovery uses previous good save")

func _test_exports() -> void:
	var config = ConfigFile.new()
	check(config.load("res://export_presets.cfg") == OK, "Export presets load")
	for i in range(3):
		check(config.get_value("preset.%d" % i, "include_filter", "").contains("data/*.json"), "Export includes dynamic JSON data")
	check(config.get_value("preset.0", "platform", "") == "Windows Desktop", "Windows target")
	check(config.get_value("preset.1", "platform", "") == "Linux", "Linux target")
	check(config.get_value("preset.2", "platform", "") == "Android", "Android target")
	check(config.get_value("preset.2.options", "architectures/arm64-v8a", false), "ARM64 Android target")
	check(not config.get_value("preset.2.options", "permissions/internet", true), "No unnecessary Android network permission")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility", "Compatibility renderer")
