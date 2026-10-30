class_name RonkeArena
extends Control

const BANANA = Color("f6d35c")
const CREAM = Color("fff1d6")
const DARK = Color("101d3d")
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
var damage_numbers = true
var banner = ""
var banner_time = 0.0
var font: Font
var floor_texture: Texture2D
var enemy_texture: Texture2D
var visual_data: Dictionary = {}
var vignette: GradientTexture2D
var fruit_accent: Texture2D
var draw_count = 0
var shake_strength = 0.5
var shake_energy = 0.0
var shake_offset = Vector2.ZERO
var feedback_clock = 0.0
var hurt_flash = 0.0
var phase_notice = ""
var phase_notice_time = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(180, 246)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	font = load("res://assets/fonts/Display.ttf")
	var data_file = FileAccess.open("res://data/visual_data.json", FileAccess.READ)
	if data_file:
		visual_data = JSON.parse_string(data_file.get_as_text())
	fruit_accent = load("res://assets/art/ui/fruit_accent.png")
	enemy_texture = load("res://assets/art/enemies/enemies.png")
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
	gradient.colors = PackedColorArray([Color.TRANSPARENT, Color.TRANSPARENT, Color(0.01, 0.02, 0.02, 0.48)])
	vignette = GradientTexture2D.new()
	vignette.gradient = gradient
	vignette.width = 128
	vignette.height = 128
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.0, 0.5)
	touch_enabled = OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--mobile-ui")

func set_run(run: RonkeRun) -> void:
	model = run
	texture = load("res://assets/crew/" + run.crew.id + ".png")
	sprite_frames = load("res://assets/animations/" + run.crew.id + ".tres")
	var paths = ["verdant", "ember", "astral"]
	floor_texture = load("res://assets/art/arenas/" + paths[run.world] + ".png")
	aim = Vector2(300, 100)
	shake_energy = 0.0
	shake_offset = Vector2.ZERO
	hurt_flash = 0.0
	banner_time = 0.0
	phase_notice_time = 0.0
	particles.clear()
	labels.clear()
	rings.clear()
	chains.clear()
	reset_input()
	queue_redraw()

func configure_presentation(enabled: bool, numbers: bool) -> void:
	effects = enabled
	damage_numbers = numbers
	if not effects:
		particles.clear()
		rings.clear()
		chains.clear()
		shake_energy = 0.0
		shake_offset = Vector2.ZERO
	if not damage_numbers:
		labels.clear()
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
	if kind == "hurt":
		hurt_flash = 0.32
		shake_energy = maxf(shake_energy, 1.0)
	elif kind == "surge" or (kind == "kill" and event.get("kind", "") == "boss"):
		shake_energy = maxf(shake_energy, 0.85)
	elif kind == "hit" and event.get("crit", false):
		shake_energy = maxf(shake_energy, 0.3)
	if kind == "kill" and event.get("kind", "") == "boss":
		banner = "GUARDIAN DEFEATED"
		banner_time = 2.1
		if effects and rings.size() < 32:
			rings.append({"pos": event.pos, "radius": 140.0, "life": 0.35})
	if kind == "boss_phase":
		phase_notice = "ROOTHEART / AWAKENED" if event.guardian == "rootheart" else "GATEKEEPER / ENRAGED"
		phase_notice_time = 1.8
	if kind == "wave":
		banner = "GUARDIAN AHEAD" if event.boss else "DEPTH %02d" % event.wave
		banner_time = 2.1
	if kind == "damage" and damage_numbers and labels.size() < 45:
		labels.append({"pos": event.pos + Vector2(randf_range(-8, 8), -25), "text": str(event.value) + ("!" if event.crit else ""), "crit": event.crit, "life": 0.65})
	if kind in ["hit", "kill", "hurt", "surge", "dash", "shield"] and effects:
		var count = 28 if kind == "surge" else 11 if kind == "kill" else 5
		var color: Color = event.get("color", Color("ef9d80") if kind == "hurt" else BANANA if kind != "kill" else Color("afd18a"))
		for _i in range(count):
			if particles.size() >= 180:
				break
			particles.append({"pos": event.pos, "velocity": Vector2.from_angle(randf() * TAU) * randf_range(35, 160), "color": color, "life": randf_range(0.25, 0.65)})
	if kind in ["splash", "shield", "surge"] and effects and rings.size() < 32:
		rings.append({"pos": event.pos, "radius": event.get("radius", 80.0 if kind == "surge" else 45.0), "life": 0.35})
	if kind == "chain" and effects and chains.size() < 48:
		chains.append({"from": event.pos, "to": event.end, "life": 0.13})

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not model:
		return
	# Feedback uses presentation time only; simulation timing is untouched.
	feedback_clock += delta
	shake_energy = maxf(0.0, shake_energy - delta * 3.5)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	shake_offset = Vector2(sin(feedback_clock * 83), cos(feedback_clock * 107)) * 6.0 * shake_strength * shake_energy * shake_energy if active and effects else Vector2.ZERO
	if active:
		banner_time = maxf(0, banner_time - delta)
		phase_notice_time = maxf(0, phase_notice_time - delta)
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
	draw_string_outline(font, pos + Vector2(0, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.02, 0.04, 0.03, color.a * 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_floor() -> void:
	if floor_texture:
		# Nine regions compress the illustrated walls to the actual bounce boundary.
		var width = float(floor_texture.get_width())
		var height = float(floor_texture.get_height())
		var sx = [0.0, 96.0, width - 96.0, width]
		var sy = [0.0, 110.0, height - 140.0, height]
		var dx = [0.0, 18.0, 582.0, 600.0]
		var dy = [0.0, 24.0, 788.0, 820.0]
		var tint = Color(0.72, 0.86, 1.0) if model.world == 0 else Color(0.90, 0.85, 0.94) if model.world == 1 else Color(0.82, 0.88, 1.0)
		for row in range(3):
			for col in range(3):
				draw_texture_rect_region(floor_texture, Rect2(dx[col], dy[row], dx[col + 1] - dx[col], dy[row + 1] - dy[row]), Rect2(sx[col], sy[row], sx[col + 1] - sx[col], sy[row + 1] - sy[row]), tint)
	else:
		draw_rect(Rect2(0, 0, 600, 820), Color("162b50"))
	draw_rect(Rect2(0, 0, 600, 820), Color(0.045, 0.12, 0.32, 0.14))
	if fruit_accent:
		draw_texture_rect(fruit_accent, Rect2(28, 26, 32, 32), false, Color(1, 1, 1, 0.35))
	if vignette:
		draw_texture_rect(vignette, Rect2(0, 0, 600, 820), false)
	if effects:
		var color = Color("69c9ee") if model.world == 0 else Color("f0c976") if model.world == 1 else Color("b1bfff")
		for i in range(22):
			var x = 28 + fmod(i * 137.9 + sin(model.time * 0.18 + i) * 10, 544)
			var y = fmod(i * 83.4 - model.time * (4 + i % 3) + 1640, 820)
			var alpha = 0.13 + sin(model.time * 0.8 + i * 1.7) * 0.06
			draw_circle(Vector2(x, y), 1.2 if i % 3 else 1.8, Color(color, alpha))
	var danger = 0.0
	for enemy in model.enemies:
		danger = maxf(danger, clampf((enemy.pos.y - 530) / 160, 0, 1))
	var line_color = Color("ef9d80") if danger > 0.45 else BANANA
	var opacity = 0.25 + danger * 0.45
	draw_line(Vector2(22, 700), Vector2(578, 700), Color(line_color, opacity * 0.15), 9, true)
	draw_dashed_line(Vector2(22, 700), Vector2(578, 700), Color(line_color, opacity), 1.5, 10)
	for x in [29.0, 571.0]:
		draw_polyline(PackedVector2Array([Vector2(x - 5, 694), Vector2(x, 700), Vector2(x - 5, 706)]), Color(line_color, opacity + 0.1), 2, true)
	_text("BREACH LINE", Vector2(465, 691), 11, Color(line_color, 0.65))

func _draw() -> void:
	if not model or size.x <= 0 or size.y <= 0:
		return
	draw_count += 1
	draw_set_transform(shake_offset * size / Vector2(600, 820), 0, size / Vector2(600, 820))
	_draw_floor()
	for enemy in model.enemies:
		if not enemy.dead and enemy.get("charging", false):
			_draw_attack_warning(enemy)
	if active and model.phase == "playing":
		var direction: Vector2 = (aim - model.player.pos).normalized()
		draw_dashed_line(model.player.pos + Vector2(0, -20), model.player.pos + Vector2(0, -20) + direction * 200, Color(0.33, 0.79, 0.96, 0.35), 2, 11)
	for enemy in model.enemies:
		_draw_enemy(enemy)
	for bullet in model.bullets:
		draw_line(bullet.pos - bullet.velocity * 0.045, bullet.pos, Color(0.95, 0.45, 0.55, 0.3), bullet.radius, true)
		var diamond = PackedVector2Array([bullet.pos + Vector2(0, -bullet.radius - 2), bullet.pos + Vector2(bullet.radius + 2, 0), bullet.pos + Vector2(0, bullet.radius + 2), bullet.pos + Vector2(-bullet.radius - 2, 0)])
		draw_colored_polygon(diamond, DARK)
		for i in range(diamond.size()):
			diamond[i] = bullet.pos + (diamond[i] - bullet.pos) * 0.72
		draw_colored_polygon(diamond, Color("f79ca9"))
		draw_circle(bullet.pos, 1.8, CREAM)
	for ball in model.balls:
		var color = RonkeData.orb_color(ball.element)
		draw_line(ball.pos - ball.velocity * 0.045, ball.pos, Color(color, 0.12), ball.radius * 1.8, true)
		draw_line(ball.pos - ball.velocity * 0.022, ball.pos, Color(color, 0.45), ball.radius * 0.75, true)
		if effects:
			draw_circle(ball.pos, ball.radius + 6, Color(color, 0.09))
			draw_circle(ball.pos, ball.radius + 3, Color(color, 0.17))
		draw_circle(ball.pos, ball.radius + 1, DARK)
		draw_circle(ball.pos, ball.radius, color)
		draw_circle(ball.pos - Vector2(1.3, 1.3), 1.9, CREAM)
		if ball.element in ["toxic_sun", "stormglass", "eclipse"]:
			draw_arc(ball.pos, ball.radius + 3, model.time * 5, model.time * 5 + PI * 1.2, 10, Color(CREAM, 0.75), 1, true)
	var p: Dictionary = model.player
	var world_scale = size / Vector2(600, 820)
	draw_set_transform((p.pos + Vector2(0, 27) + shake_offset) * world_scale, 0, Vector2(world_scale.x, world_scale.y * 0.26))
	draw_circle(Vector2.ZERO, 29, Color(0, 0, 0, 0.3))
	draw_set_transform(shake_offset * size / Vector2(600, 820), 0, size / Vector2(600, 820))
	if p.invincible > 0:
		draw_arc(p.pos, 43, 0, TAU, 40, Color(0.95, 0.8, 0.5, 0.6), 2, true)
	var frame = 7 if model.phase == "defeat" else 6 if p.hurt > 0.07 else 1 if p.shoot > 0.15 else 2 if p.shoot > 0.08 else 3 if p.shoot > 0 else 4 + int(model.time * 7) % 2 if p.moving or p.dash > 0 else 0
	if sprite_frames:
		var mapping = [["idle", 0], ["throw", 0], ["throw", 1], ["throw", 2], ["walk", 0], ["walk", 1], ["hurt", 0], ["defeat", 1]][frame]
		var frame_texture = sprite_frames.get_frame_texture(mapping[0], mapping[1])
		draw_texture_rect(frame_texture, Rect2(p.pos - Vector2(84, 127), Vector2(168, 168)), false)
	if p.dash_cd > 0:
		draw_arc(p.pos + Vector2(0, 28), 18, -PI / 2, -PI / 2 + TAU * (1 - p.dash_cd / 3.5), 25, Color(0.96, 0.83, 0.36, 0.5), 2, true)
	for particle in particles:
		draw_colored_polygon(PackedVector2Array([particle.pos + Vector2(0, -3), particle.pos + Vector2(2, 0), particle.pos + Vector2(0, 3), particle.pos + Vector2(-2, 0)]), Color(particle.color, clampf(particle.life / 0.4, 0, 1)))
	for ring in rings:
		draw_arc(ring.pos, ring.radius * (1.2 - ring.life), 0, TAU, 36, Color(0.96, 0.83, 0.36, clampf(ring.life * 2, 0, 0.7)), 2, true)
	for chain in chains:
		var middle: Vector2 = (chain.from + chain.to) / 2 + Vector2(8, -8)
		draw_polyline(PackedVector2Array([chain.from, middle, chain.to]), Color("eaffd9"), 2, true)
	for label in labels:
		_text(label.text, label.pos, 23 if label.crit else 17, Color(BANANA if label.crit else CREAM, clampf(label.life * 2, 0, 1)), true)
	# Keep HUD, touch targets and banners stationary while the world reacts.
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 820))
	_draw_breach_warning()
	if hurt_flash > 0:
		var warning = Color(1.0, 0.25, 0.24, hurt_flash * 1.5)
		draw_rect(Rect2(2, 2, 596, 816), warning, false, 5)
	if model.combo > 2 and model.combo_time > 0:
		_text("%dx COMBO" % model.combo, Vector2(300, 641), 23, BANANA, true)
	if model.phase == "playing" and model.enemies.is_empty():
		var remaining = maxf(0.0, 1.6 - model.clear_clock)
		_text("EXIT OPENING" if model.wave == RonkeRun.LAST_WAVE else "NEXT DEPTH / %02d" % (model.wave + 1), Vector2(300, 120), 25, BANANA, true)
		_text("%.1fs / STAY ALERT" % remaining, Vector2(300, 145), 15, CREAM, true)
	if phase_notice_time > 0:
		_text(phase_notice, Vector2(300, 212), 22, Color("ffc0be"), true)
	if banner_time > 0:
		var opacity = minf(1.0, banner_time * 3)
		_box(Rect2(106, 294, 388, 88), Color(0.035, 0.07, 0.17, opacity * 0.86), Color(BANANA, opacity * 0.55), 4)
		draw_line(Vector2(140, 304), Vector2(460, 304), Color(BANANA, opacity * 0.35), 1)
		_text(banner, Vector2(300, 341), 34, Color(CREAM, opacity), true)
		_text("MAKE EVERY BOUNCE COUNT", Vector2(300, 367), 12, Color(BANANA, opacity), true)
	if touch_enabled:
		_draw_touch()
	draw_set_transform(Vector2.ZERO)

func _draw_attack_warning(enemy: Dictionary) -> void:
	# Essential gameplay information stays visible with optional effects disabled.
	var duration = model.attack_windup(enemy)
	var progress = clampf(1.0 - enemy.fire / duration, 0.0, 1.0)
	var color = Color("ffc0be")
	var radius: float = enemy.width * 0.6 + 5.0
	draw_arc(enemy.pos, radius, -PI / 2, -PI / 2 + TAU * maxf(0.02, progress), 32, color, 2.5, true)
	for direction in model.attack_directions(enemy):
		var length = 1000.0
		if absf(direction.x) > 0.001:
			length = minf(length, ((600.0 if direction.x > 0 else 0.0) - enemy.pos.x) / direction.x)
		if absf(direction.y) > 0.001:
			length = minf(length, ((820.0 if direction.y > 0 else 0.0) - enemy.pos.y) / direction.y)
		var start: Vector2 = enemy.pos + direction * radius
		var end: Vector2 = enemy.pos + direction * maxf(radius, length)
		draw_dashed_line(start, end, Color(color, 0.22 + progress * 0.18), 1.5, 12, true)
		var tip: Vector2 = enemy.pos + direction * minf(radius + 35, maxf(radius, length))
		var side = direction.orthogonal() * 5
		draw_polyline(PackedVector2Array([tip - direction * 9 + side, tip, tip - direction * 9 - side]), color, 2, true)

func _draw_breach_warning() -> void:
	var count = 0
	var guardian = false
	for enemy in model.enemies:
		if not enemy.dead and enemy.pos.y + enemy.width / 2.0 > RonkeRun.HEIGHT - 190:
			count += 1
			guardian = guardian or enemy.kind == "boss"
	if count == 0:
		return
	var color = Color("ffb1a2")
	for x in [24, 576]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 684), Vector2(x + 7, 684), Vector2(x, 698)]), color)
	_text("GUARDIAN AT BREACH / STOP IT!" if guardian else "BREACH RISK / %d CLOSE" % count, Vector2(300, 690), 15, color, true)

func _draw_enemy(enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.pos
	var width: float = enemy.width
	var name: String = enemy.kind
	if enemy.kind == "boss":
		name = enemy.guardian
	var data: Array = visual_data.get("enemy_regions", {}).get(name, [0, 0, 512, 512])
	var region = Rect2(data[0], data[1], data[2], data[3])
	var scale_factor = 1.2 if enemy.kind == "boss" else 1.14
	var draw_size = Vector2(width * scale_factor, width * scale_factor * region.size.y / region.size.x)
	var bob = sin(model.time * 2.0 + enemy.id * 1.3) * (1.8 if enemy.kind == "prism" else 0.7)
	var rect = Rect2(pos - draw_size / 2 + Vector2(0, bob), draw_size)
	if enemy_texture:
		draw_texture_rect_region(enemy_texture, Rect2(rect.position + Vector2(2, 6), rect.size), region, Color(0.01, 0.025, 0.02, 0.55))
		if enemy.burn > 0 or enemy.poison > 0 or enemy.slow > 0 or enemy.weak > 0:
			var outline = Color("8ee5ed") if enemy.slow > 0 else Color("b3e589") if enemy.poison > 0 else Color("ffc18a") if enemy.burn > 0 else Color("ffbee3")
			draw_texture_rect_region(enemy_texture, rect.grow(3.5), region, Color(outline, 0.55))
		draw_texture_rect_region(enemy_texture, rect, region, Color(1.8, 1.65, 1.4) if enemy.flash > 0 else Color.WHITE)
	else:
		_box(Rect2(pos - Vector2.ONE * width / 2, Vector2.ONE * width), Color("64866c"))
	if enemy.hp < enemy.max_hp or enemy.kind == "boss":
		var bar = Rect2(Vector2(pos.x - draw_size.x / 2, rect.end.y + 5), Vector2(draw_size.x, 5 if enemy.kind == "boss" else 3.5))
		draw_rect(bar.grow(1), Color(0.02, 0.04, 0.03, 0.9))
		bar.size.x *= clampf(enemy.hp / enemy.max_hp, 0, 1)
		draw_rect(bar, Color("ffc0be") if enemy.kind == "boss" and enemy.boss_phase == 2 else BANANA if enemy.kind == "boss" else Color("a8ca9c"))
		if enemy.kind == "boss":
			var midpoint = bar.position + Vector2(draw_size.x * 0.5, 0)
			draw_line(midpoint - Vector2(0, 1), midpoint + Vector2(0, 6), DARK, 2)
	if enemy.kind == "boss":
		var title = "THE GATEKEEPER" if enemy.guardian == "gatekeeper" else "THE ROOT OF IT ALL"
		_text(title + (" / II" if enemy.boss_phase == 2 else " / I"), Vector2(pos.x, rect.position.y - 9), 12, Color("ffc0be") if enemy.boss_phase == 2 else BANANA, true)

func _draw_touch() -> void:
	var origin = touch_origin if move_touch >= 0 else Vector2(82, 750)
	draw_circle(origin, 53, Color(0.035, 0.07, 0.17, 0.38))
	draw_arc(origin, 53, 0, TAU, 40, Color(BANANA, 0.32), 2, true)
	draw_arc(origin, 46, 0, TAU, 40, Color(BANANA, 0.12), 1, true)
	draw_circle(origin + touch_move * 35, 22, Color(0.33, 0.79, 0.96, 0.48))
	draw_arc(origin + touch_move * 35, 22, 0, TAU, 24, Color(CREAM, 0.35), 1, true)
	for button in [[Vector2(530, 750), "DASH", model.player.dash_cd <= 0], [Vector2(530, 640), "SURGE", model.surge >= 100]]:
		draw_circle(button[0], 39, Color(0.035, 0.09, 0.075, 0.6))
		draw_circle(button[0], 34, Color(BANANA, 0.22 if button[2] else 0.04))
		draw_arc(button[0], 39, 0, TAU, 32, Color(BANANA, 0.8 if button[2] else 0.25), 2, true)
		_text(button[1], button[0] + Vector2(0, 5), 14, BANANA, true)
