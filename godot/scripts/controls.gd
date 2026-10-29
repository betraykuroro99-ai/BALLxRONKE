class_name RonkeControls
extends RefCounted

static func configure() -> void:
	var key_actions = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"dash": [KEY_SHIFT], "surge": [KEY_E], "pause_run": [KEY_P, KEY_ESCAPE], "fire": [KEY_SPACE]}
	for action in key_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in key_actions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var axes = {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0], "fire": [JOY_AXIS_TRIGGER_RIGHT, 1.0]}
	for action in axes:
		var event = InputEventJoypadMotion.new()
		event.axis = axes[action][0]
		event.axis_value = axes[action][1]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	for pair in [["dash", JOY_BUTTON_A], ["surge", JOY_BUTTON_X], ["pause_run", JOY_BUTTON_START]]:
		var event = InputEventJoypadButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)
