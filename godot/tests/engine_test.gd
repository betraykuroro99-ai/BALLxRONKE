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

func _test_save() -> void:
	var raw = {"version": 1, "shards": -20, "last_crew": "missing", "meta": {"power": 100}, "world": "invalid"}
	var clean = RonkeSave.sanitize(raw)
	check(clean.shards == 0 and clean.meta.power == 3 and clean.last_crew == "warrior" and clean.world == 0, "Save input validation")
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
