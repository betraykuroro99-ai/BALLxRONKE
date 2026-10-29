class_name RonkeArena
extends Control

const GOLD = Color("e6ba7a")
const CREAM = Color("f3eedf")
const DARK = Color("0d201a")
var model: RonkeRun
var texture: Texture2D
var sprite_frames: SpriteFrames
var aim = Vector2(300, 100)
var pointer_held = false
var active = false
var touch_enabled = false
var touch_move = Vector2.ZERO
var move_touch = -1
var aim_touch = -1
var touch_origin = Vector2(82, 750)
var pending_dash = false
var pending_surge = false
var last_aim_ms = 0
var auto_fire = true
var particles: Array = []
var labels: Array = []
var rings: Array = []
var chains: Array = []
var styles: Dictionary = {}
var effects = true
var banner = ""
var banner_time = 0.0
var font: Font

func _ready() -> void:
	custom_minimum_size = Vector2(180, 246)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	font = ThemeDB.fallback_font
	touch_enabled = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile-ui")

func set_run(run: RonkeRun) -> void:
	model = run
	texture = load("res://assets/crew/" + run.crew.id + ".png")
	sprite_frames = load("res://assets/animations/" + run.crew.id + ".tres")
	aim = Vector2(300, 100)
	particles.clear()
	labels.clear()
	rings.clear()
	chains.clear()
	reset_input()
	queue_redraw()

func reset_input() -> void:
	move_touch = -1
	aim_touch = -1
	touch_move = Vector2.ZERO
	pointer_held = false
	pending_dash = false
	pending_surge = false

func world_point(local_point: Vector2) -> Vector2:
	return local_point * Vector2(600.0 / maxf(size.x, 1), 820.0 / maxf(size.y, 1))

func _gui_input(event: InputEvent) -> void:
	if not active or not model:
		return
	if event is InputEventMouseMotion and event.device != -1:
		aim = world_point(event.position)
		last_aim_ms = Time.get_ticks_msec()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != -1:
		pointer_held = event.pressed
		if event.pressed:
			aim = world_point(event.position)
			last_aim_ms = Time.get_ticks_msec()
			grab_focus()
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		pointer_held = false
	if not active or not is_visible_in_tree() or not model:
		return
	if event is InputEventScreenTouch:
		var local = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and not Rect2(Vector2.ZERO, size).has_point(local):
			return
		if handle_touch(event.index, event.pressed, world_point(local)):
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var local = get_global_transform_with_canvas().affine_inverse() * event.position
		if drag_touch(event.index, world_point(local)):
			get_viewport().set_input_as_handled()

func handle_touch(index: int, pressed: bool, point: Vector2) -> bool:
	touch_enabled = true
	if not pressed:
		if index == move_touch:
			move_touch = -1
			touch_move = Vector2.ZERO
			return true
		if index == aim_touch:
			aim_touch = -1
			pointer_held = false
			return true
		return false
	if point.x < 180 and point.y > 610 and move_touch < 0:
		move_touch = index
		touch_origin = Vector2(clampf(point.x, 55, 135), clampf(point.y, 660, 760))
		touch_move = Vector2.ZERO
	elif point.x > 465 and point.y > 690:
		pending_dash = true
	elif point.x > 465 and point.y > 580:
		pending_surge = true
	elif aim_touch < 0:
		aim_touch = index
		aim = point
		pointer_held = true
		last_aim_ms = Time.get_ticks_msec()
	return true

func drag_touch(index: int, point: Vector2) -> bool:
	if index == move_touch:
		touch_move = ((point - touch_origin) / 40.0).limit_length()
		return true
	if index == aim_touch:
		aim = point
		last_aim_ms = Time.get_ticks_msec()
		return true
	return false

func collect_input() -> Dictionary:
	var movement = (Input.get_vector("move_left", "move_right", "move_up", "move_down") + touch_move).limit_length()
	var pads = Input.get_connected_joypads()
	if not pads.is_empty():
		var stick = Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.23:
			aim = model.player.pos + stick.normalized() * 500
			last_aim_ms = Time.get_ticks_msec()
	if (touch_enabled or not pads.is_empty()) and Time.get_ticks_msec() - last_aim_ms > 1800:
		var target = model.nearest_threat()
		if not target.is_empty():
			aim = target.pos
	var result = {"move": movement, "aim": Vector2(clampf(aim.x, 0, 600), clampf(aim.y, 20, 680)),
		"shoot": auto_fire or pointer_held or aim_touch >= 0 or Input.is_action_pressed("fire"),
		"dash": pending_dash or Input.is_action_just_pressed("dash"),
		"surge": pending_surge or Input.is_action_just_pressed("surge")}
	pending_dash = false
	pending_surge = false
	return result

func push_event(event: Dictionary) -> void:
	var kind = event.type
	if kind == "wave":
		banner = "GUARDIAN AHEAD" if event.boss else "DEPTH %02d" % event.wave
		banner_time = 2.1
	if kind == "damage" and labels.size() < 45:
		labels.append({"pos": event.pos + Vector2(randf_range(-10, 10), -20), "text": str(event.value) + ("!" if event.crit else ""), "crit": event.crit, "life": 0.65})
	if kind in ["hit", "kill", "hurt", "surge", "dash", "shield"] and effects:
		var count = 28 if kind == "surge" else 9 if kind == "kill" else 4
		var color: Color = event.get("color", Color("ef9d80") if kind == "hurt" else GOLD if kind != "kill" else Color("afd18a"))
		for _i in range(count):
			if particles.size() >= 180:
				break
			particles.append({"pos": event.pos, "velocity": Vector2.from_angle(randf() * TAU) * randf_range(35, 160), "color": color, "life": randf_range(0.25, 0.65)})
	if kind in ["splash", "shield", "surge"]:
		rings.append({"pos": event.pos, "radius": event.get("radius", 80.0 if kind == "surge" else 45.0), "life": 0.35})
	if kind == "chain":
		chains.append({"from": event.pos, "to": event.end, "life": 0.13})

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not model:
		return
	if active:
		banner_time = maxf(0, banner_time - delta)
		for particle in particles:
			particle.life -= delta
			particle.pos += particle.velocity * delta
			particle.velocity.y += 90 * delta
		for label in labels:
			label.life -= delta
			label.pos.y -= 35 * delta
		for ring in rings:
			ring.life -= delta
		for chain in chains:
			chain.life -= delta
		particles = particles.filter(func(p): return p.life > 0)
		labels = labels.filter(func(p): return p.life > 0)
		rings = rings.filter(func(p): return p.life > 0)
		chains = chains.filter(func(p): return p.life > 0)
	queue_redraw()

func _box(rect: Rect2, color: Color, border: Color = DARK, radius: int = 8) -> void:
	var key = color.to_html() + border.to_html() + str(radius)
	if not styles.has(key):
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.border_color = border
		style.set_border_width_all(2)
		style.set_corner_radius_all(radius)
		styles[key] = style
	draw_style_box(styles[key], rect)

func _text(text: String, pos: Vector2, font_size: int, color: Color, centered: bool = false) -> void:
	if centered:
		pos.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / 2.0
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if not model or size.x <= 0 or size.y <= 0:
		return
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 820))
	var colors = [Color("162f27"), Color("2c281f"), Color("252a38")]
	draw_rect(Rect2(0, 0, 600, 820), colors[model.world])
	for y in range(0, 820, 66):
		draw_line(Vector2(14, y), Vector2(586, y), Color(0.6, 0.7, 0.5, 0.04))
		for x in range(24 + (int(y / 66.0) % 2) * 60, 600, 118):
			draw_line(Vector2(x, y), Vector2(x, y + 66), Color(0.6, 0.7, 0.5, 0.04))
	for x in [0, 588]:
		draw_rect(Rect2(x, 0, 12, 820), Color("2d4638"))
		for y in range(30, 820, 75):
			draw_rect(Rect2(x + 3, y, 6, 18), Color("61734e"))
	draw_dashed_line(Vector2(20, 700), Vector2(580, 700), Color(0.9, 0.6, 0.5, 0.3), 1, 8)
	_text("HOLD THE LINE", Vector2(438, 691), 12, Color("8e7966"))
	if active and model.phase == "playing":
		var direction: Vector2 = (aim - model.player.pos).normalized()
		draw_dashed_line(model.player.pos + Vector2(0, -20), model.player.pos + Vector2(0, -20) + direction * 200, Color(0.9, 0.8, 0.6, 0.3), 2, 11)
	for enemy in model.enemies:
		_draw_enemy(enemy)
	for bullet in model.bullets:
		draw_circle(bullet.pos, bullet.radius + 3, Color(0.9, 0.5, 0.6, 0.15))
		draw_circle(bullet.pos, bullet.radius, Color("df9ba3"))
		draw_circle(bullet.pos - Vector2.ONE, bullet.radius * 0.35, CREAM)
	for ball in model.balls:
		var color = RonkeData.orb_color(ball.element)
		draw_line(ball.pos - ball.velocity * 0.025, ball.pos, Color(color, 0.24), ball.radius * 1.2, true)
		if effects:
			draw_circle(ball.pos, ball.radius + 5, Color(color, 0.08))
		draw_circle(ball.pos, ball.radius, color)
		draw_circle(ball.pos - Vector2(1.3, 1.3), 1.9, CREAM)
	var p: Dictionary = model.player
	var world_scale = size / Vector2(600, 820)
	draw_set_transform((p.pos + Vector2(0, 27)) * world_scale, 0, Vector2(world_scale.x, world_scale.y * 0.26))
	draw_circle(Vector2.ZERO, 29, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 820))
	if p.invincible > 0:
		draw_arc(p.pos, 43, 0, TAU, 40, Color(0.95, 0.8, 0.5, 0.6), 2, true)
	var frame = 7 if model.phase == "defeat" else 6 if p.hurt > 0.07 else 1 if p.shoot > 0.15 else 2 if p.shoot > 0.08 else 3 if p.shoot > 0 else 4 + int(model.time * 7) % 2 if p.moving or p.dash > 0 else 0
	if sprite_frames:
		var mapping = [["idle", 0], ["throw", 0], ["throw", 1], ["throw", 2], ["walk", 0], ["walk", 1], ["hurt", 0], ["defeat", 1]][frame]
		var frame_texture = sprite_frames.get_frame_texture(mapping[0], mapping[1])
		draw_texture_rect(frame_texture, Rect2(p.pos - Vector2(84, 127), Vector2(168, 168)), false)
	if p.dash_cd > 0:
		draw_arc(p.pos + Vector2(0, 28), 18, -PI / 2, -PI / 2 + TAU * (1 - p.dash_cd / 3.5), 25, Color(0.9, 0.8, 0.5, 0.5), 2, true)
	for particle in particles:
		draw_rect(Rect2(particle.pos, Vector2(3, 3)), Color(particle.color, clampf(particle.life / 0.4, 0, 1)))
	for ring in rings:
		draw_arc(ring.pos, ring.radius * (1.2 - ring.life), 0, TAU, 36, Color(0.9, 0.8, 0.5, clampf(ring.life * 2, 0, 0.7)), 2, true)
	for chain in chains:
		var middle: Vector2 = (chain.from + chain.to) / 2 + Vector2(8, -8)
		draw_polyline(PackedVector2Array([chain.from, middle, chain.to]), Color("eaffd9"), 2, true)
	for label in labels:
		_text(label.text, label.pos, 23 if label.crit else 17, Color(GOLD if label.crit else CREAM, clampf(label.life * 2, 0, 1)), true)
	if model.combo > 2 and model.combo_time > 0:
		_text("%dx COMBO" % model.combo, Vector2(300, 641), 23, GOLD, true)
	if banner_time > 0:
		_text(banner, Vector2(300, 340), 38, CREAM, true)
		_text("MAKE EVERY BOUNCE COUNT", Vector2(300, 367), 14, GOLD, true)
	if touch_enabled:
		_draw_touch()
	draw_set_transform(Vector2.ZERO)

func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.pos
	var width: float = enemy.width
	var half = width / 2
	var color = Color("f4edc9") if enemy.flash > 0 else Color("7d8162") if enemy.kind == "boss" else Color("9a8261") if enemy.kind == "granite" else Color("837b9b") if enemy.kind == "prism" else Color("a4a76c") if enemy.kind == "swift" else Color("64866c")
	_box(Rect2(pos - Vector2.ONE * half, Vector2.ONE * width), color, DARK, 15 if enemy.kind == "boss" else 7)
	if enemy.kind == "prism":
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -half + 7), pos + Vector2(half - 8, 0), pos + Vector2(0, half - 7), pos + Vector2(-half + 8, 0)]), Color("dab8f4"))
	else:
		var eye = 10 if enemy.kind == "boss" else 4
		var spread = 22 if enemy.kind == "boss" else 10
		for x in [-spread, spread]:
			draw_circle(pos + Vector2(x, -3), eye, DARK)
			draw_circle(pos + Vector2(x + 1, 0), eye * 0.35, GOLD if enemy.kind == "boss" else CREAM)
		draw_line(pos + Vector2(-7, half * 0.44), pos + Vector2(7, half * 0.44), Color("243d28"), 3)
		if enemy.kind == "granite":
			draw_polyline(PackedVector2Array([pos + Vector2(-half + 4, -half + 5), pos + Vector2(-5, -3), pos + Vector2(-13, half - 3)]), Color("514631"), 3, true)
		else:
			_box(Rect2(pos + Vector2(-half - 1, -half - 2), Vector2(width * 0.6, 8)), Color("91ad6b"), Color.TRANSPARENT, 3)
	if enemy.burn > 0 or enemy.poison > 0 or enemy.slow > 0 or enemy.weak > 0:
		var outline = Color("8ee5ed") if enemy.slow > 0 else Color("b3e589") if enemy.poison > 0 else Color("ffc18a") if enemy.burn > 0 else Color("ffbee3")
		draw_rect(Rect2(pos - Vector2.ONE * (half + 3), Vector2.ONE * (width + 6)), outline, false, 2)
	if enemy.hp < enemy.max_hp or enemy.kind == "boss":
		draw_rect(Rect2(pos + Vector2(-half, half + 8), Vector2(width, 4)), DARK)
		draw_rect(Rect2(pos + Vector2(-half, half + 8), Vector2(width * clampf(enemy.hp / enemy.max_hp, 0, 1), 4)), GOLD if enemy.kind == "boss" else Color("8cbd90"))
	if enemy.kind == "boss":
		_text("THE GATEKEEPER" if enemy.max_hp < 600 else "THE ROOT OF IT ALL", pos + Vector2(0, -half - 12), 12, CREAM, true)

func _draw_touch() -> void:
	var origin = touch_origin if move_touch >= 0 else Vector2(82, 750)
	draw_circle(origin, 53, Color(0.65, 0.8, 0.7, 0.10))
	draw_arc(origin, 53, 0, TAU, 40, Color(0.65, 0.8, 0.7, 0.35), 2, true)
	draw_circle(origin + touch_move * 35, 22, Color(0.65, 0.8, 0.7, 0.40))
	for button in [[Vector2(530, 750), "DASH", model.player.dash_cd <= 0], [Vector2(530, 640), "SURGE", model.surge >= 100]]:
		draw_circle(button[0], 39, Color(GOLD, 0.3 if button[2] else 0.08))
		draw_arc(button[0], 39, 0, TAU, 32, Color(GOLD, 0.8 if button[2] else 0.25), 2, true)
		_text(button[1], button[0] + Vector2(0, 5), 14, GOLD, true)
