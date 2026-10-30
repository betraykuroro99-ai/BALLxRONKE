extends SceneTree

var failures: Array = []

func _init() -> void:
	call_deferred("_run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run_tests() -> void:
	RonkeSave.use_test_profile("ui")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	check(scene.ready_done and scene.home_view.visible, "Home scene starts")
	check(scene.sound.tones.size() == 15 and scene.sound.voices.size() == 10, "Combat cues use a bounded voice pool")
	for stream in scene.sound.tones.values():
		check(not stream.data.is_empty() and stream.mix_rate == 22050, "Synthesized cue contains PCM data")
	scene.sound.muted = false
	scene.sound.play_event("wave", {"boss": true})
	check(scene.sound.last_played.has("boss"), "Guardian events select warning cue")
	scene.sound.play_event("end", {"win": true})
	check(scene.sound.last_played.has("victory"), "Victory selects its own cue")
	scene.sound.muted = true
	scene.sound.stop_all()
	check(scene.home_grid.size.x <= scene.size.x + 1, "Home fits the viewport")
	check(scene.start_button.get_global_rect().end.y <= scene.home_view.get_global_rect().end.y + 1, "Start button is visible without scrolling")
	scene.open_crew()
	await process_frame
	var cards: Array = []
	for button in scene.modal_content.find_children("*", "Button", true, false):
		if button.custom_minimum_size.y == 180:
			cards.append(button)
	check(cards.size() == 23, "Crew picker contains all 23 runners")
	cards[4].pressed.emit()
	check(scene.selected == "cogitator" and scene.modal_kind == "", "Crew button selects correct runner")
	scene.open_feedback()
	await process_frame
	check(scene.modal_kind == "feedback", "Feedback settings open from home")
	var feedback_controls = scene.modal_content.find_children("*", "Control", true, false).filter(func(b): return b.focus_mode != Control.FOCUS_NONE and b.is_visible_in_tree())
	check(feedback_controls.filter(func(b): return b is HSlider).size() == 2, "Both feedback sliders accept keyboard focus")
	for slider in scene.modal_content.find_children("*", "HSlider", true, false):
		if slider.get_meta("preference") == "shake":
			slider.value = 0
		else:
			slider.value = 0.4
	check(scene.progress.shake == 0 and scene.arena.shake_strength == 0, "Motion can be disabled")
	check(absf(RonkeSave.load_progress().volume - 0.4) < 0.001, "Volume setting persists")
	for toggle in scene.modal_content.find_children("*", "CheckButton", true, false):
		if toggle.has_meta("preference"):
			toggle.button_pressed = false
	check(not scene.arena.effects and not scene.arena.damage_numbers, "Performance preferences apply immediately")
	for option in scene.modal_content.find_children("*", "OptionButton", true, false):
		if option.get_meta("preference", "") == "frame_limit":
			option.select(0)
			option.item_selected.emit(0)
	check(Engine.max_fps == 30 and RonkeSave.load_progress().frame_limit == 30, "Frame limit applies and persists")
	for option in scene.modal_content.find_children("*", "OptionButton", true, false):
		if option.get_meta("preference", "") == "frame_limit":
			option.select(1)
			option.item_selected.emit(1)
	check(Engine.max_fps == 60, "Default frame limit restores")
	scene._close_modal()
	scene._select_crew("warrior")
	scene.start_button.pressed.emit()
	await process_frame
	check(scene.model != null and scene.game_view.visible and not scene.home_view.visible, "Start button enters native game")
	check(scene.arena.texture.get_width() == 1024, "Live arena uses real sprite texture")
	scene.arena.push_event({"type": "hit", "pos": Vector2(300, 300)})
	scene.arena.push_event({"type": "damage", "pos": Vector2(300, 300), "value": 10, "crit": false})
	check(scene.arena.particles.is_empty() and scene.arena.labels.is_empty(), "Disabled effects and numbers do not allocate feedback")
	scene.arena.push_event({"type": "wave", "wave": 5, "boss": true})
	check(scene.arena.banner == "GUARDIAN AHEAD", "Essential guardian cue survives reduced effects")
	scene.arena.configure_presentation(true, true)
	scene.arena.push_event({"type": "hit", "pos": Vector2(300, 300)})
	scene.arena.push_event({"type": "damage", "pos": Vector2(300, 300), "value": 10, "crit": false})
	check(not scene.arena.particles.is_empty() and not scene.arena.labels.is_empty(), "Feedback can be restored during a run")
	scene.arena.configure_presentation(false, false)
	check(scene.arena.particles.is_empty() and scene.arena.labels.is_empty(), "Reducing feedback clears already-active effects")
	scene.arena.configure_presentation(true, true)
	var key = InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(Input.is_action_pressed("move_right"), "Physical keyboard binding reaches input map")
	key.pressed = false
	Input.parse_input_event(key)
	await process_frame
	check(not Input.is_action_pressed("move_right"), "Keyboard release clears movement")
	scene.auto_button.pressed.emit()
	check(not scene.arena.auto_fire and scene.arena.has_focus(), "Auto toggle restores gameplay keyboard focus")
	scene.auto_button.pressed.emit()
	for _i in range(4):
		await process_frame
	check(scene.arena.size.x > 0 and scene.arena.size.y > 0, "Arena is laid out")
	check(scene.arena.draw_count > 0 and scene.arena.floor_texture is Texture2D and scene.arena.enemy_texture is Texture2D, "Illustrated arena executes its native draw path")
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(200, 100) * scene.arena.size / Vector2(600, 820)
	scene.arena._gui_input(motion)
	check(scene.arena.aim.distance_to(Vector2(200, 100)) < 0.01, "Mouse aim accounts for arena scaling")
	check(absf(scene.arena.size.x / scene.arena.size.y - 600.0 / 820.0) < 0.01, "Arena aspect ratio is preserved")
	check(scene.arena.get_global_rect().end.y <= scene.size.y + 1, "Desktop arena stays inside the viewport")
	scene.pause_run()
	var old_time = scene.model.time
	await process_frame
	check(scene.paused and scene.modal_kind == "pause" and scene.model.time == old_time, "Pause freezes combat")
	check(scene.arena.focus_mode == Control.FOCUS_NONE and scene.start_button.focus_mode == Control.FOCUS_NONE, "Modal blocks focus on background controls")
	scene.open_feedback(true)
	await process_frame
	check(scene.paused and scene.model.time == old_time, "Feedback settings keep combat paused")
	for toggle in scene.modal_content.find_children("*", "CheckButton", true, false):
		if toggle.get_meta("preference", "") == "effects":
			toggle.button_pressed = true
	check(scene.paused and scene.arena.effects, "Changing effects in settings keeps combat paused")
	scene.arena.push_event({"type": "hurt", "pos": Vector2(300, 700)})
	scene.arena._process(0.01)
	check(scene.arena.shake_offset == Vector2.ZERO and scene.arena.hurt_flash > 0, "Zero shake retains damage warning")
	scene.arena.shake_strength = 1.0
	scene.arena.active = true
	scene.arena._process(0.01)
	check(scene.arena.shake_offset.length() > 0 and scene.arena.shake_offset.length() <= 8.5, "Impact motion stays bounded")
	scene.arena.shake_strength = 0
	scene._close_modal()
	check(not scene.paused, "Resume unpauses")
	check(scene.arena.focus_mode == Control.FOCUS_ALL, "Closing modal restores gameplay focus")
	scene.model.xp = scene.model.xp_needed
	scene.model.check_level()
	await process_frame
	check(scene.modal_kind == "upgrade", "Level-up opens upgrade choices")
	var choices: Array = []
	for button in scene.modal_content.find_children("*", "Button", true, false):
		if button.has_meta("upgrade_index"):
			choices.append(button)
	check(choices.size() == 3, "Three upgrade buttons")
	choices[1].pressed.emit()
	check(scene.model.phase == "playing" and scene.modal_kind == "", "Choice button resumes the run")
	check(scene.model.picks.size() == 1, "Exactly one upgrade applied")
	# Separate touch IDs must permit movement and aiming at the same time.
	scene.arena.active = true
	scene.arena.handle_touch(0, true, Vector2(80, 750))
	scene.arena.drag_touch(0, Vector2(120, 750))
	scene.arena.handle_touch(1, true, Vector2(420, 200))
	var input = scene.arena.collect_input()
	check(input.move.x > 0.9 and input.aim.distance_to(Vector2(420, 200)) < 0.01, "Multi-touch movement and aiming")
	scene.arena.handle_touch(1, false, Vector2.ZERO)
	check(scene.arena.touch_move.x > 0.9, "Releasing aim does not cancel movement")
	scene.arena.handle_touch(0, false, Vector2.ZERO)
	check(scene.arena.touch_move == Vector2.ZERO, "Releasing movement resets stick")
	scene.arena.handle_touch(2, true, Vector2(530, 750))
	check(scene.arena.collect_input().dash, "Touch dash queues the action")
	scene.model.surge = 100
	scene.arena.handle_touch(3, true, Vector2(530, 640))
	check(scene.arena.collect_input().surge, "Touch surge queues the action")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.paused, "Focus loss pauses the run")
	scene._close_modal()
	scene.model.finish(false)
	await process_frame
	check(scene.modal_kind == "result" and scene.settled, "Defeat shows result and banks progress")
	check(scene.progress.last_run.crew == scene.model.crew.id and scene.progress.last_run.wave == scene.model.wave, "Settlement records the latest expedition")
	check(scene.modal_content.find_children("*", "Label", true, false).any(func(label): return label.text == "FINAL ORBIT"), "Results include final loadout")
	var shards = scene.progress.shards
	scene._settle()
	check(scene.progress.shards == shards, "Rewards bank once")
	scene._return_home()
	check(scene.model == null and scene.home_view.visible, "Return to home works")
	scene.open_camp()
	scene.open_last_report()
	await process_frame
	check(scene.modal_kind == "journal" and scene.progress.shards == shards, "Saved report reopens without banking rewards again")
	check(scene.modal_content.get_global_rect().size.x <= scene.size.x, "Report fits viewport width")
	scene._close_modal()
	scene.progress.shards = 100
	var old_rank = scene.progress.meta.power
	if old_rank < 3:
		scene.open_camp()
		scene._buy_meta("power")
		check(scene.progress.meta.power == old_rank + 1 and scene.progress.shards < 100, "Camp purchase spends currency and increases rank")
	scene._close_modal()
	scene._select_crew("cogitator")
	scene.start_run()
	scene.model.xp = scene.model.xp_needed
	scene.model.check_level()
	scene._process(0.1)
	check(scene.modal_kind == "upgrade", "Automatic runner still shows the upgrade event")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	for _i in range(11):
		scene._process(0.1)
	check(scene.paused and scene.model.picks.is_empty() and scene.model.phase == "upgrade", "Automatic upgrade stays suspended while unfocused")
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for _i in range(11):
		scene._process(0.1)
	check(scene.model.picks.size() == 1 and scene.modal_kind == "" and not scene.paused, "Automatic upgrade closes modal and resumes gameplay")
	scene._return_home()
	# Check both orientations in the real Godot layout engine.
	root.size = Vector2i(600, 1000)
	for _i in range(5):
		await process_frame
	check(scene.compact and scene.home_grid.columns == 1 and scene.header_grid.columns == 3, "Portrait menu adapts")
	check(scene.header_grid.size.x <= scene.size.x + 1, "Portrait header fits")
	scene.start_run()
	for _i in range(5):
		await process_frame
	check(not scene.left_panel.visible and not scene.right_panel.visible, "Portrait hides side panels")
	check(scene.arena.get_global_rect().end.x <= scene.size.x + 1, "Portrait arena fits")
	root.size = Vector2i(1280, 800)
	for _i in range(5):
		await process_frame
	check(not scene.compact and scene.header_grid.columns == 6, "Desktop layout restores")
	scene.model.enemies.clear()
	scene.model.clear_clock = 0.4
	var transition_draws = scene.arena.draw_count
	for _i in range(3):
		await process_frame
	check(scene.arena.draw_count > transition_draws, "Wave transition countdown draws natively")
	for world_index in range(3):
		scene._return_home()
		scene.world = world_index
		scene.start_run()
		scene.model.enemies.clear()
		scene.model.wave = 4 if world_index < 2 else 9
		scene.model.spawn_wave()
		for enemy in scene.model.enemies:
			if enemy.kind in ["boss", "prism"]:
				enemy.charging = true
				enemy.attack_angle = PI / 2
				enemy.fire = 0.4
				if enemy.kind == "boss":
					enemy.boss_phase = 2
					enemy.attack_phase = 2
					enemy.attack_pattern = "root_spread" if enemy.guardian == "rootheart" else "gate_fan"
					scene.arena.push_event({"type": "boss_phase", "guardian": enemy.guardian, "pos": enemy.pos})
			if enemy.kind != "boss":
				enemy.pos.y = 635
		scene.arena.effects = false
		var prior_draws = scene.arena.draw_count
		for _i in range(4):
			await process_frame
		check(scene.arena.draw_count > prior_draws, "Warnings render with optional effects disabled")
		check(scene.arena.floor_texture is Texture2D and scene.arena.draw_count > 0, "Biome and boss art draw paths: " + str(world_index))
	scene._return_home()
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: native menu/run/upgrade/pause/result/camp flow, sprites, multi-touch, focus handling, portrait and desktop layouts.")
		quit(0)
	else:
		print("FAIL: ", failures.size(), " UI assertions")
		quit(1)
