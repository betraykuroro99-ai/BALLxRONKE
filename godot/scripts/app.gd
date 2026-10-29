extends Control

const BG = Color("0c191b")
const PANEL = Color("182f2c")
const LINE = Color("52604a")
const CREAM = Color("f3eedf")
const MUTED = Color("9aafa0")
const GOLD = Color("e6ba7a")
const GREEN = Color("a3c6a7")
var progress: Dictionary
var selected = "warrior"
var world = 0
var model: RonkeRun
var paused = false
var settled = false
var background_upgrade_pause = false
var compact = false
var touch_device = false
var modal_kind = ""
var modal_dismissible = true
var modal_previous_pause = false
var modal_focus_modes: Dictionary = {}
var root_margin: MarginContainer
var header_grid: GridContainer
var home_view: ScrollContainer
var home_grid: GridContainer
var game_view: HBoxContainer
var left_panel: VBoxContainer
var left_scroll: ScrollContainer
var right_panel: VBoxContainer
var arena: RonkeArena
var sound: RonkeSound
var modal_layer: ColorRect
var modal_panel: PanelContainer
var modal_content: VBoxContainer
var shard_label: Label
var runner_name: Label
var runner_role: Label
var runner_tagline: Label
var runner_perk: Label
var runner_image: TextureRect
var runner_orb: Label
var start_button: Button
var volume_button: Button
var depth_label: Label
var stats_label: Label
var health_label: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var xp_label: Label
var ammo_label: Label
var orbit_label: RichTextLabel
var picks_label: Label
var surge_button: Button
var mobile_surge_button: Button
var surge_bar: ProgressBar
var auto_button: Button
var status_label: Label
var status_time = 0.0
var hud_clock = 0.0
var bold_font: Font
var ready_done = false

func _ready() -> void:
	RonkeControls.configure()
	if OS.get_cmdline_user_args().has("--qa-profile"):
		RonkeSave.use_test_profile("smoke")
	progress = RonkeSave.load_progress()
	selected = progress.last_crew
	world = progress.world
	touch_device = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile-ui")
	bold_font = load("res://assets/fonts/Display.ttf")
	_build_theme()
	sound = RonkeSound.new()
	add_child(sound)
	sound.muted = progress.muted
	sound.volume = progress.volume
	_build_interface()
	arena.shake_strength = progress.shake
	resized.connect(_responsive_layout)
	get_tree().root.size_changed.connect(_window_changed)
	ready_done = true
	if OS.get_cmdline_user_args().has("--mobile-ui") and not OS.has_feature("mobile"):
		get_tree().root.size = Vector2i(600, 1000)
	_window_changed()
	_select_crew(selected)
	start_button.grab_focus()
	if OS.get_cmdline_user_args().has("--verify-pack"):
		_verify_pack_resources()
		return
	if OS.get_cmdline_user_args().has("--start-run"):
		start_run()
		print("SMOKE: native run started")

func _style(color: Color, border: Color = LINE, radius: int = 10, padding: int = 16) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.shadow_color = Color(0.01, 0.025, 0.02, 0.32)
	result.shadow_size = 5
	result.shadow_offset = Vector2(0, 3)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = padding
	result.content_margin_bottom = padding
	return result

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 19
	theme.set_font("font", "Button", bold_font)
	theme.set_font("font", "OptionButton", bold_font)
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_stylebox("normal", "Button", _style(Color("263d34"), LINE, 5, 12))
	theme.set_stylebox("hover", "Button", _style(Color("38503c"), GOLD, 5, 12))
	theme.set_stylebox("pressed", "Button", _style(Color("1d322b"), GOLD, 5, 12))
	theme.set_stylebox("disabled", "Button", _style(Color("192c23"), LINE, 7, 12))
	var focus = _style(Color.TRANSPARENT, GOLD, 7, 0)
	focus.set_border_width_all(3)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_stylebox("panel", "PanelContainer", _style(PANEL))
	theme.set_stylebox("normal", "OptionButton", _style(Color("233b2d"), LINE, 7, 12))
	theme.set_stylebox("hover", "OptionButton", _style(Color("304a34"), GREEN, 7, 12))
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_stylebox("panel", "PopupMenu", _style(PANEL, LINE, 6, 12))
	theme.set_stylebox("hover", "PopupMenu", _style(Color("354b37"), GOLD, 4, 6))
	theme.set_color("font_color", "PopupMenu", CREAM)
	theme.set_color("font_hover_color", "PopupMenu", GOLD)
	for kind in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", kind, _style(Color("102420"), Color.TRANSPARENT, 3, 0))
		theme.set_stylebox("grabber", kind, _style(Color("526448"), Color("74805b"), 3, 0))
		theme.set_stylebox("grabber_highlight", kind, _style(Color("82956c"), GOLD, 3, 0))
		theme.set_stylebox("grabber_pressed", kind, _style(GOLD, GOLD, 3, 0))

func _label(parent: Node, text: String, font_size: int = 19, color: Color = CREAM) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size >= 26:
		label.add_theme_font_override("font", bold_font)
		label.add_theme_color_override("font_shadow_color", Color(0.01, 0.025, 0.02, 0.65))
		label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, primary: bool = false) -> Button:
	var button = Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 50
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(key, BG)
		var gold_style = _style(GOLD, Color("8b6e42"), 5, 13)
		gold_style.border_width_bottom = 4
		button.add_theme_stylebox_override("normal", gold_style)
		button.add_theme_stylebox_override("hover", _style(Color("f1ce99"), CREAM, 7, 13))
		button.add_theme_stylebox_override("pressed", _style(Color("c8a060"), GOLD, 7, 13))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _vbox(parent: Node, gap: int = 14) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func _hbox(parent: Node, gap: int = 14) -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", gap)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box

func _panel(parent: Node) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return panel

func _bar(parent: Node, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 12
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("background", _style(Color("0b1b15"), Color.TRANSPARENT, 5, 0))
	bar.add_theme_stylebox_override("fill", _style(color, Color.TRANSPARENT, 5, 0))
	parent.add_child(bar)
	return bar

func _portrait(id: String, frame: int = 0) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = load("res://assets/crew/" + id + ".png")
	atlas.region = Rect2(frame * 128, 0, 128, 128)
	return atlas

func _build_interface() -> void:
	var background = ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	root_margin = MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		root_margin.add_theme_constant_override("margin_" + edge, 22)
	add_child(root_margin)
	var shell = _vbox(root_margin, 18)
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	header_grid = GridContainer.new()
	header_grid.columns = 6
	header_grid.add_theme_constant_override("h_separation", 12)
	header_grid.add_theme_constant_override("v_separation", 10)
	shell.add_child(header_grid)
	var header = header_grid
	header.custom_minimum_size.y = 58
	var brand = _button(header, "BALLxRONKE", _request_home)
	brand.icon = load("res://assets/icon.svg")
	brand.expand_icon = true
	brand.add_theme_constant_override("icon_max_width", 28)
	brand.add_theme_font_override("font", bold_font)
	brand.add_theme_font_size_override("font_size", 25)
	brand.size_flags_stretch_ratio = 1.7
	_button(header, "Crew", open_crew)
	_button(header, "Camp", open_camp)
	_button(header, "Help", open_help).size_flags_stretch_ratio = 0.4
	volume_button = _button(header, "Sound / Feel", open_feedback)
	volume_button.size_flags_stretch_ratio = 0.8
	shard_label = _label(header, "0 shards", 18, GOLD)
	shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var body = Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(body)
	_build_home(body)
	_build_game(body)
	status_label = _label(shell, "Native Godot prototype / PC + Android", 15, MUTED)
	status_label.custom_minimum_size.y = 22
	_build_modal()

func _build_home(body: Control) -> void:
	home_view = ScrollContainer.new()
	home_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_view.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	home_view.follow_focus = true
	body.add_child(home_view)
	var column = _vbox(home_view, 18)
	_label(column, "THE PIT IS CALLING", 15, GREEN)
	_label(column, "One more descent.", 43)
	home_grid = GridContainer.new()
	home_grid.columns = 2
	home_grid.add_theme_constant_override("h_separation", 20)
	home_grid.add_theme_constant_override("v_separation", 20)
	home_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(home_grid)
	var hero = PanelContainer.new()
	hero.custom_minimum_size = Vector2(420, 465)
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_grid.add_child(hero)
	var art = TextureRect.new()
	art.texture = load("res://assets/art/keyart.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(art)
	var shade = ColorRect.new()
	shade.color = Color(0.01, 0.05, 0.04, 0.43)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(shade)
	var margin = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 26)
	hero.add_child(margin)
	var text = _vbox(margin, 17)
	_label(text, "A GORILLA-POWERED ROGUELITE", 15, GREEN)
	_label(text, "SMALL BALL.\nBIG PROBLEM.", 62, GOLD)
	_label(text, "The world fell in.\nYou might as well follow it.", 22)
	start_button = _button(text, "Enter the pit / 10 waves", start_run, true)
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_child(spacer)
	_label(text, "BOUNCE.  EVOLVE.  DESCEND.", 15, GREEN)
	var runner = _panel(home_grid)
	runner.custom_minimum_size.x = 300
	var details = _vbox(runner, 12)
	_label(details, "YOUR RUNNER", 15, GREEN)
	runner_image = TextureRect.new()
	runner_image.custom_minimum_size = Vector2(240, 190)
	runner_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	runner_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(runner_image)
	runner_role = _label(details, "", 14, GREEN)
	runner_name = _label(details, "", 35)
	runner_tagline = _label(details, "", 17, MUTED)
	runner_perk = _label(details, "", 18)
	runner_orb = _label(details, "", 17, GOLD)
	_button(details, "Choose runner", open_crew)
	_button(details, "Start descent", start_run, true)
	var choice = _vbox(_panel(column), 10)
	_label(choice, "PICK YOUR DESCENT", 16, GREEN)
	var picker = OptionButton.new()
	picker.custom_minimum_size.y = 52
	for entry in RonkeData.all().worlds:
		picker.add_item(entry.name)
	picker.select(world)
	picker.item_selected.connect(func(index):
		world = index
		progress.world = index
		_save())
	choice.add_child(picker)
	_label(choice, "Three ruin themes. Ten waves and two guardians. Earn shards to improve your next run.", 17, MUTED)
	_label(column, "Progress saves on this device. No account or internet connection required.", 15, MUTED)

func _build_game(body: Control) -> void:
	game_view = HBoxContainer.new()
	game_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_view.add_theme_constant_override("separation", 22)
	game_view.visible = false
	body.add_child(game_view)
	left_scroll = ScrollContainer.new()
	left_scroll.custom_minimum_size.x = 210
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_view.add_child(left_scroll)
	left_panel = _vbox(left_scroll, 18)
	_button(left_panel, "Back to camp", _request_home)
	_label(left_panel, "CURRENT DEPTH", 15, GREEN)
	depth_label = _label(left_panel, "01 / 10", 52, GOLD)
	_label(left_panel, "Into the unknown.", 32)
	stats_label = _label(left_panel, "", 18, MUTED)
	_label(left_panel, "FIELD NOTE\n\nWalls are your friends.\nMost other things aren't.", 18, GREEN)
	_label(left_panel, "WASD / arrows: move\nPointer / right stick: aim\nShift / A: dash\nE / X: surge\nP / Start: pause", 16, MUTED)
	var center = _vbox(game_view, 10)
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hud = _hbox(center, 10)
	health_label = _label(hud, "VITALITY", 17)
	_button(hud, "Pause", pause_run).size_flags_stretch_ratio = 0.4
	health_bar = _bar(center, Color("e79b82"))
	var ratio = AspectRatioContainer.new()
	ratio.ratio = 600.0 / 820.0
	ratio.stretch_mode = AspectRatioContainer.STRETCH_FIT
	ratio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ratio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(ratio)
	arena = RonkeArena.new()
	ratio.add_child(arena)
	var bottom = _hbox(center, 10)
	xp_label = _label(bottom, "LV. 1", 17, GREEN)
	xp_label.size_flags_stretch_ratio = 0.45
	ammo_label = _label(bottom, "9 / 9 orbs", 17, GOLD)
	auto_button = _button(bottom, "Auto on", _toggle_auto)
	auto_button.size_flags_stretch_ratio = 0.65
	mobile_surge_button = _button(bottom, "Surge", func(): arena.pending_surge = true)
	mobile_surge_button.tooltip_text = "Rift Surge requires 100% charge"
	mobile_surge_button.size_flags_stretch_ratio = 0.65
	xp_bar = _bar(center, GREEN)
	right_panel = _vbox(game_view, 17)
	right_panel.custom_minimum_size.x = 240
	right_panel.size_flags_horizontal = Control.SIZE_FILL
	_label(right_panel, "YOUR ORBIT", 18, GREEN)
	orbit_label = RichTextLabel.new()
	orbit_label.bbcode_enabled = true
	orbit_label.fit_content = true
	orbit_label.scroll_active = false
	orbit_label.custom_minimum_size.x = 220
	orbit_label.add_theme_font_override("bold_font", bold_font)
	orbit_label.add_theme_font_size_override("normal_font_size", 17)
	orbit_label.add_theme_font_size_override("bold_font_size", 21)
	right_panel.add_child(orbit_label)
	var surge_column = _vbox(_panel(right_panel), 12)
	_label(surge_column, "RIFT SURGE", 15, GOLD)
	_label(surge_column, "Let it all out.", 29)
	_label(surge_column, "Defeat enemies to charge a burst of orbs and a brief shield.", 17, MUTED)
	surge_bar = _bar(surge_column, GOLD)
	surge_button = _button(surge_column, "Charging", func(): arena.pending_surge = true, true)
	_label(right_panel, "THIS RUN'S UPGRADES", 15, GREEN)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_panel.add_child(scroll)
	picks_label = _label(scroll, "A fresh start.", 16, MUTED)

func _build_modal() -> void:
	modal_layer = ColorRect.new()
	modal_layer.color = Color(0.015, 0.04, 0.03, 0.94)
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.visible = false
	add_child(modal_layer)
	modal_panel = PanelContainer.new()
	modal_layer.add_child(modal_panel)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	modal_panel.add_child(scroll)
	modal_content = _vbox(scroll, 18)

func _window_changed() -> void:
	if not ready_done:
		return
	var window_size: Vector2i = get_tree().root.size
	var narrow = window_size.x < 900 or window_size.y > window_size.x
	var target = Vector2i(600, 1000) if narrow else Vector2i(1000, 600) if touch_device else Vector2i(1280, 800)
	if get_tree().root.content_scale_size != target:
		get_tree().root.content_scale_size = target
	compact = narrow
	_responsive_layout()

func _responsive_layout() -> void:
	if not is_instance_valid(home_grid):
		return
	home_grid.columns = 1 if compact else 2
	header_grid.columns = 3 if compact else 6
	left_scroll.visible = not compact and not touch_device and size.x > 1100
	left_panel.visible = left_scroll.visible
	right_panel.visible = not compact and not touch_device and size.x > 1000
	var margin = 12 if compact else 22
	for edge in ["left", "right", "top", "bottom"]:
		root_margin.add_theme_constant_override("margin_" + edge, margin)
	if OS.has_feature("android"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.window_get_size()
		if screen.x > 0 and screen.y > 0:
			var factor = size / Vector2(screen)
			root_margin.add_theme_constant_override("margin_left", maxi(margin, int(safe.position.x * factor.x)))
			root_margin.add_theme_constant_override("margin_top", maxi(margin, int(safe.position.y * factor.y)))
			root_margin.add_theme_constant_override("margin_right", maxi(margin, int((screen.x - safe.end.x) * factor.x)))
			root_margin.add_theme_constant_override("margin_bottom", maxi(margin, int((screen.y - safe.end.y) * factor.y)))
	if is_instance_valid(modal_panel):
		modal_panel.size = Vector2(minf(size.x - 28, 960), minf(size.y - 28, 760))
		modal_panel.position = (size - modal_panel.size) / 2

func _select_crew(id: String) -> void:
	selected = id
	progress.last_crew = id
	var crew = RonkeData.crew(id)
	runner_name.text = crew.name
	runner_role.text = str(crew.role).to_upper()
	runner_tagline.text = crew.tagline
	runner_perk.text = crew.perk
	runner_orb.text = "STARTING ORB / " + RonkeData.all().elements[crew.element].name
	runner_orb.add_theme_color_override("font_color", RonkeData.orb_color(crew.element))
	runner_image.texture = _portrait(id)
	_save()

func _save() -> void:
	if RonkeSave.write_progress(progress) != OK:
		_toast("Progress could not be saved. Check available storage.")
	shard_label.text = "%d shards" % progress.shards

func _toast(text: String) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", GOLD)
	status_time = 3.0

func start_run() -> void:
	_close_modal()
	background_upgrade_pause = false
	model = RonkeRun.new(selected, world, randi(), progress.meta)
	paused = false
	settled = false
	arena.set_run(model)
	arena.shake_strength = progress.shake
	arena.auto_fire = true
	auto_button.text = "Auto on"
	home_view.visible = false
	game_view.visible = true
	arena.active = true
	arena.grab_focus()
	_update_hud()
	_toast("WASD + pointer, controller sticks, or touch controls. The pit is ready.")

func _update_hud() -> void:
	if not model:
		return
	health_label.text = "VITALITY  %d / %d" % [ceili(model.player.hp), int(model.player.max_hp)]
	health_bar.value = model.player.hp / model.player.max_hp * 100
	xp_bar.value = float(model.xp) / model.xp_needed * 100
	xp_label.text = "Lv.%d / D.%02d" % [model.level, model.wave]
	ammo_label.text = "%d / %d orbs" % [model.player.ammo, model.player.capacity]
	depth_label.text = "%02d / 10" % model.wave
	stats_label.text = "%s in the pit\n\n%d enemies cleared\n\n%d wall bounces\n\n%dx best combo" % [_clock(model.time), model.kills, model.bounces, model.best_combo]
	var names: Array[String] = []
	for element in model.elements:
		var color = RonkeData.orb_color(element).to_html(false)
		names.append("[color=#%s]●[/color]  [b]%s[/b]  [color=#9aafa0]Lv.%d[/color]" % [color, RonkeData.all().elements[element].name, int(model.element_levels.get(element, 1))])
	var orbit_text = "\n".join(names)
	if orbit_label.text != orbit_text:
		orbit_label.text = orbit_text
	picks_label.text = "A fresh start." if model.picks.is_empty() else "\n\n".join(model.picks)
	surge_bar.value = model.surge
	surge_button.disabled = model.surge < 100
	surge_button.text = "UNLEASH / E or X" if model.surge >= 100 else "Charging %d%%" % model.surge
	mobile_surge_button.text = "SURGE!" if model.surge >= 100 else "%d%% Surge" % model.surge
	mobile_surge_button.disabled = model.surge < 100

func _process(delta: float) -> void:
	if not ready_done:
		return
	if status_time > 0:
		status_time -= delta
		if status_time <= 0:
			status_label.text = "Native Godot prototype / PC + Android"
			status_label.add_theme_color_override("font_color", MUTED)
	if not model or not game_view.visible:
		return
	arena.active = not paused and model.phase == "playing"
	if not paused:
		model.advance(delta, arena.collect_input())
	for event in model.drain_events():
		arena.push_event(event)
		sound.play_event(event.type, event)
		match event.type:
			"level": _show_upgrade()
			"upgrade":
				if modal_kind == "upgrade":
					_close_modal()
				paused = false
				_toast("Upgrade: " + event.name)
			"end":
				_settle()
				_show_result()
	hud_clock += delta
	if hud_clock >= 0.1:
		hud_clock = 0
		_update_hud()

func _clock(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds / 60), int(seconds) % 60]

func _open_modal(kind: String, title: String, description: String, dismissible: bool = true, pause_game: bool = true) -> VBoxContainer:
	if modal_kind != "":
		_close_modal()
	modal_previous_pause = paused
	modal_kind = kind
	modal_dismissible = dismissible
	modal_focus_modes.clear()
	for control in root_margin.find_children("*", "Control", true, false):
		if control.focus_mode != Control.FOCUS_NONE:
			modal_focus_modes[control] = control.focus_mode
			control.focus_mode = Control.FOCUS_NONE
	if pause_game and model:
		paused = true
		arena.active = false
		arena.reset_input()
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	var captions = {"crew": "THE CREW", "camp": "BASECAMP", "help": "FIELD GUIDE", "upgrade": "EVOLVE YOUR ORBIT", "result": "EXPEDITION LOG", "pause": "TAKE A BREATH", "leave": "RETURN TO CAMP"}
	_label(modal_content, captions.get(kind, "ORBFALL"), 13, GREEN)
	var header = _hbox(modal_content)
	_label(header, title, 35)
	if dismissible:
		_button(header, "Close", _close_modal).size_flags_stretch_ratio = 0.3
	_label(modal_content, description, 19, MUTED)
	modal_layer.visible = true
	_responsive_layout()
	return modal_content

func _close_modal() -> void:
	if modal_kind == "":
		return
	modal_kind = ""
	modal_layer.visible = false
	paused = modal_previous_pause
	for control in modal_focus_modes:
		if is_instance_valid(control):
			control.focus_mode = modal_focus_modes[control]
	modal_focus_modes.clear()
	if model and game_view.visible:
		arena.grab_focus()
	else:
		start_button.grab_focus()

func _focus_modal() -> void:
	for button in modal_content.find_children("*", "Button", true, false):
		if not button.disabled:
			button.grab_focus()
			return

func _critical() -> bool:
	return modal_kind in ["upgrade", "result"]

func open_crew() -> void:
	if _critical():
		return
	var content = _open_modal("crew", "Meet your crew.", "All 23 runners are available. Select a runner for your next descent.")
	var grid = GridContainer.new()
	grid.columns = 3 if compact else 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for crew in RonkeData.all().crew:
		var card = Button.new()
		card.custom_minimum_size = Vector2(150, 180)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = crew.perk
		if crew.id == selected:
			card.add_theme_stylebox_override("normal", _style(Color("35412a"), GOLD))
		grid.add_child(card)
		var column = VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 8
		column.offset_right = -8
		column.offset_top = 7
		column.offset_bottom = -7
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(column)
		var image = TextureRect.new()
		image.texture = _portrait(crew.id)
		image.custom_minimum_size.y = 100
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(image)
		for pair in [[crew.name, 17, CREAM], [crew.role, 12, MUTED]]:
			var label = _label(column, pair[0], pair[1], pair[2])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var id: String = crew.id
		card.pressed.connect(func():
			_select_crew(id)
			_close_modal()
			_toast(RonkeData.crew(id).name + " is ready for the next run."))
	_focus_modal()

func open_camp() -> void:
	if _critical():
		return
	var content = _open_modal("camp", "Home between falls.", "Spend shards on permanent improvements for your next descent.")
	if not progress.last_run.is_empty():
		_button(content, "View last expedition", open_last_report)
	for entry in [["vitality", "Heartwood", "+10 starting health per rank."], ["power", "Heavy lifting", "+5% starting damage per rank."], ["reserves", "Deep pockets", "+1 starting orb charge per rank."]]:
		var column = _vbox(_panel(content), 10)
		var id: String = entry[0]
		var rank: int = progress.meta[id]
		var cost = 20 + rank * 25
		_label(column, entry[1] + " / Rank %d of 3" % rank, 27)
		_label(column, entry[2], 18, MUTED)
		var button = _button(column, "Fully improved" if rank >= 3 else "Improve / %d shards" % cost, func(): _buy_meta(id), true)
		button.disabled = rank >= 3 or progress.shards < cost
	_focus_modal()

func _buy_meta(id: String) -> void:
	if not id in ["vitality", "power", "reserves"]:
		return
	var rank: int = progress.meta[id]
	var cost = 20 + rank * 25
	if rank >= 3 or progress.shards < cost:
		return
	progress.shards -= cost
	progress.meta[id] += 1
	_save()
	_close_modal()
	open_camp()
	_toast("Basecamp improved. Your next run starts stronger.")

func open_help() -> void:
	if _critical():
		return
	var content = _open_modal("help", "The field guide.", "Keep enemies above the breach line. Clear ten waves and defeat both guardians.")
	for pair in [["Move and aim", "PC: WASD or arrows move. Pointer aims. Controller: left stick moves, right stick aims; A dashes, X triggers Surge, Start pauses. Auto throws start enabled; turn Auto off to use Space, mouse button, or right trigger."],
		["On Android", "Use the left stick to move. Drag elsewhere in the arena to aim. Tap DASH and SURGE on the right. Touch/controller aim assist finds a threat when you stop aiming. Back pauses. Changing focus pauses too."],
		["Read the danger", "Pink dashed lanes show where Prism enemies and guardians will shoot. Their aim locks during the charge: step away or dash across the lane before release. Breach warnings mean an enemy is close to crossing; a guardian breach ends the run."],
		["Build your orbit", "Pick an upgrade each level. Ember + Venom becomes Toxic Sun; Frost + Spark becomes Stormglass; Light + Void becomes Eclipse. Evolutions replace their ingredients."],
		["Return stronger", "Wall bounces keep orbs in play. Charges return at the bottom or after expiry. Defeated enemies charge Rift Surge. Spend run rewards at basecamp. Saves stay on this device; browser saves are separate."]]:
		_label(content, pair[0], 28, GOLD)
		_label(content, pair[1], 19)
	_button(content, "Got it", _close_modal, true)
	_focus_modal()

func _show_upgrade() -> void:
	var automatic = model.crew.id in ["cogitator", "radical"]
	var content = _open_modal("upgrade", "Choose your next advantage.", "%s is choosing automatically." % model.crew.name if automatic else "Level %d. Combat waits while you choose." % model.level, false, false)
	for i in range(model.choices.size()):
		var choice: Dictionary = model.choices[i]
		var button = _button(content, "%02d / %s\n%s\n%s" % [i + 1, choice.kind, choice.name, choice.description], func(): _choose_upgrade(i), choice.has("fusion"))
		button.custom_minimum_size.y = 112
		button.set_meta("upgrade_index", i)
		if choice.has("element"):
			button.add_theme_color_override("font_color", RonkeData.orb_color(choice.element).lightened(0.2))
		button.disabled = automatic
	_focus_modal()

func _choose_upgrade(index: int) -> void:
	if model and model.phase == "upgrade" and model.choose_upgrade(index):
		_close_modal()
		paused = false
		_update_hud()

func _settle() -> void:
	if not model or settled:
		return
	settled = true
	progress.shards += model.reward
	progress.total_kills += model.kills
	progress.best_wave = maxi(progress.best_wave, model.wave)
	progress.runs += 1
	progress.last_run = model.report()
	if model.phase == "victory":
		progress.wins += 1
	_save()

func _show_result() -> void:
	var win = model.phase == "victory"
	var content = _open_modal("result", "Back from the brink." if win else "A good run. A deep fall.", "Ten waves. Two guardians. One determined gorilla." if win else "The ruins won this round. Bank your shards and return stronger.", false)
	var portrait = TextureRect.new()
	portrait.texture = _portrait(model.crew.id, 0 if win else 7)
	portrait.custom_minimum_size = Vector2(180, 180)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(portrait)
	_build_report(content, model.report())
	_button(content, "One more descent", start_run, true)
	_button(content, "Back to basecamp", _return_home)
	_focus_modal()

func open_last_report() -> void:
	if _critical() or progress.last_run.is_empty():
		return
	var content = _open_modal("journal", "Your last expedition.", "A record of your most recent return from the pit.")
	_build_report(content, progress.last_run)
	_button(content, "Back to camp", func():
		_close_modal()
		open_camp(), true)
	_focus_modal()

func _build_report(parent: Control, report: Dictionary) -> void:
	var runner = RonkeData.crew(report.crew)
	_label(parent, "%s / %s" % [runner.name, RonkeData.all().worlds[int(report.world)].name], 23, GOLD)
	_label(parent, "Depth %02d / %s / +%d shards" % [int(report.wave), _clock(report.time), int(report.reward)], 23)
	var outcomes = {
		"victory": ["Both guardians defeated", "Try another ruin or runner for a different approach."],
		"projectile": ["Felled by a hostile projectile", "Leave the pink firing lanes during a windup; dash grants brief protection."],
		"breach": ["Overwhelmed by breaching enemies", "Prioritize the lowest enemies before adding more pressure up the pit."],
		"guardian_breach": ["A guardian crossed the breach line", "A guardian breach ends the run immediately. Focus the guardian before it reaches the bottom."],
		"abandoned": ["Returned to camp", "Your earned shards are banked. Spend them on a stronger start."],
		"impact": ["Felled in combat", "Use dash to escape danger and Surge to heal while clearing space."],
		"defeated": ["Expedition ended", "Watch the breach line and spend your banked shards at basecamp."]}
	var outcome: Array = outcomes.get(report.reason, outcomes.defeated)
	_label(parent, outcome[0], 22, GREEN if report.win else GOLD)
	_label(parent, outcome[1], 18, MUTED)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for pair in [["ENEMIES / GUARDIANS", "%d / %d" % [int(report.kills), int(report.guardians)]],
		["THROWS / BOUNCES", "%d / %d" % [int(report.shots), int(report.bounces)]],
		["DASHES / SURGES", "%d / %d" % [int(report.dashes), int(report.surges)]],
		["BREACHES / HIT DAMAGE", "%d / %d" % [int(report.breaches), ceili(report.damage_taken)]]]:
		var tile = _vbox(_panel(grid), 4)
		_label(tile, pair[0], 12, MUTED)
		_label(tile, pair[1], 23, CREAM)
	_label(parent, "Best combo / %dx" % int(report.combo), 18, MUTED)
	var names: Array[String] = []
	for element in report.elements:
		names.append(RonkeData.all().elements[element].name)
	_label(parent, "FINAL ORBIT", 14, GREEN)
	_label(parent, " / ".join(names), 20)
	if not report.picks.is_empty():
		_label(parent, "UPGRADE PATH", 14, GREEN)
		_label(parent, " > ".join(report.picks), 17, MUTED)

func pause_run() -> void:
	if not model or model.phase != "playing":
		return
	if modal_kind == "pause":
		_close_modal()
		return
	if modal_kind != "":
		return
	var content = _open_modal("pause", "The pit can wait.", "Your descent is paused. Nothing moves until you are ready.")
	_button(content, "Keep descending", _close_modal, true)
	_button(content, "Sound / Feel", func(): open_feedback(true))
	_button(content, "Bank shards and leave", _abandon_run)
	_focus_modal()

func _request_home() -> void:
	if not model:
		return
	if model.phase in ["victory", "defeat"]:
		_return_home()
		return
	if model.phase == "upgrade":
		_toast("Choose an upgrade before leaving.")
		return
	var content = _open_modal("leave", "Head back to basecamp?", "This ends the current run and banks the shards earned so far.")
	_button(content, "Keep descending", _close_modal)
	_button(content, "Bank shards and leave", _abandon_run, true)
	_focus_modal()

func _abandon_run() -> void:
	if model:
		model.finish(false, "abandoned")
		_settle()
	_return_home()

func _return_home() -> void:
	_close_modal()
	background_upgrade_pause = false
	model = null
	arena.model = null
	arena.active = false
	arena.reset_input()
	paused = false
	game_view.visible = false
	home_view.visible = true
	start_button.grab_focus()

func _toggle_auto() -> void:
	arena.auto_fire = not arena.auto_fire
	auto_button.text = "Auto on" if arena.auto_fire else "Auto off"
	_toast("Automatic throws enabled." if arena.auto_fire else "Hold mouse, Space, or right trigger to throw.")
	arena.grab_focus()

func open_feedback(from_pause: bool = false) -> void:
	if _critical():
		return
	var content = _open_modal("feedback", "Make it feel right.", "Sound and motion preferences are saved on this device.")
	var mute = CheckButton.new()
	mute.text = "Sound enabled"
	mute.button_pressed = not sound.muted
	mute.custom_minimum_size.y = 48
	content.add_child(mute)
	mute.toggled.connect(func(enabled):
		if enabled == sound.muted:
			_toggle_sound())
	_label(content, "Sound volume", 21, GOLD)
	_feedback_slider(content, "volume", progress.volume, func(value):
		sound.volume = value
		progress.volume = value
		if value <= 0:
			sound.stop_all()
		_save())
	_label(content, "Screen shake / zero turns motion off", 21, GOLD)
	_feedback_slider(content, "shake", progress.shake, func(value):
		progress.shake = value
		arena.shake_strength = value
		if value <= 0:
			arena.shake_energy = 0.0
		_save())
	_button(content, "Preview sound", func(): sound.play_event("level"))
	_button(content, "Back to pause" if from_pause else "Done", func():
		_close_modal()
		if from_pause:
			pause_run(), true)
	_focus_modal()

func _feedback_slider(parent: Control, key: String, value: float, changed: Callable) -> void:
	var row = _hbox(parent)
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(150, 48)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.set_meta("preference", key)
	row.add_child(slider)
	var percent = _label(row, "%d%%" % roundi(value * 100), 20)
	percent.custom_minimum_size.x = 58
	slider.value_changed.connect(func(amount):
		percent.text = "%d%%" % roundi(amount * 100)
		changed.call(amount))

func _toggle_sound() -> void:
	sound.muted = not sound.muted
	progress.muted = sound.muted
	if sound.muted:
		sound.stop_all()
	_save()
	if not sound.muted:
		sound.play_event("level")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if modal_kind == "upgrade" and event.keycode >= KEY_1 and event.keycode <= KEY_4:
		if not model.crew.id in ["cogitator", "radical"]:
			_choose_upgrade(event.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif modal_layer.visible and event.keycode == KEY_TAB:
		var buttons = modal_content.find_children("*", "Control", true, false).filter(func(b): return b.focus_mode != Control.FOCUS_NONE and b.is_visible_in_tree() and (not b is BaseButton or not b.disabled))
		if not buttons.is_empty():
			var index = buttons.find(get_viewport().gui_get_focus_owner())
			buttons[posmod(index + (-1 if event.shift_pressed else 1), buttons.size())].grab_focus()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_run"):
		_handle_back()
		get_viewport().set_input_as_handled()

func _handle_back() -> void:
	if modal_layer.visible:
		if modal_dismissible:
			_close_modal()
	elif model:
		pause_run()
	elif OS.has_feature("android"):
		get_tree().quit()

func _notification(what: int) -> void:
	if not ready_done:
		return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		arena.reset_input()
		if model:
			if model.phase == "upgrade" and not paused:
				background_upgrade_pause = true
				paused = true
				arena.active = false
			elif model.phase == "playing" and modal_kind == "":
				pause_run()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		if background_upgrade_pause:
			background_upgrade_pause = false
			if model and model.phase == "upgrade":
				paused = false
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back()

func _verify_pack_resources() -> void:
	var valid = RonkeData.all().get("crew", []).size() == 23
	var art_file = FileAccess.open("res://data/visual_data.json", FileAccess.READ)
	if not art_file:
		valid = false
	else:
		var art = JSON.parse_string(art_file.get_as_text())
		if not art is Dictionary or art.get("enemy_regions", {}).size() != 6:
			valid = false
		else:
			for path in art.get("floors", []):
				if not load(path) is Texture2D:
					valid = false
			if not load(art.get("enemy_atlas", "")) is Texture2D or not load(art.get("display_font", "")) is Font:
				valid = false
	if not FileAccess.file_exists("res://assets/fonts/LICENSE-DejaVu.txt"):
		valid = false
	for crew in RonkeData.all().get("crew", []):
		var frames = load("res://assets/animations/" + crew.id + ".tres")
		if not frames is SpriteFrames:
			valid = false
			continue
		for pair in [["idle", 1], ["walk", 2], ["throw", 4], ["hurt", 2], ["defeat", 2]]:
			if not frames.has_animation(pair[0]) or frames.get_frame_count(pair[0]) != pair[1]:
				valid = false
		var scene = load("res://scenes/runners/" + crew.id + ".tscn")
		if not scene is PackedScene:
			valid = false
			continue
		var runner = scene.instantiate()
		if runner.get_node("AnimatedSprite2D").offset != Vector2(0, -56):
			valid = false
		runner.free()
	if valid:
		print("PASS: all packaged crew resources, native scenes, and JSON data are present.")
		get_tree().quit(0)
	else:
		push_error("FAIL: packaged crew resources are incomplete")
		get_tree().quit(1)
