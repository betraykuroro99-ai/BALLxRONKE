extends SceneTree
var checks = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("BALL ENVIRONMENT: " + message)
func fixture(crew: String = "warrior") -> RonkeRun:
	var run = RonkeRun.new(crew, 0, 3333, {}, true)
	run.enemies.clear()
	run._add_enemy(Vector2(300, 400), 40, 1000000, "moss", 0)
	run.stats.crit = 0
	return run
func _run() -> void:
	for edge in ["top", "bottom"]:
		var run = fixture("tunneller")
		var ball = run.add_ball(Vector2(300, 23 if edge == "top" else 802), Vector2.UP if edge == "top" else Vector2.DOWN, "ghost", 1, false)
		run._update_ball(ball, .01)
		check(ball.wraps == 1 and run.enemies[0].hp == 1000000, "Wrap does not sweep through enemies: " + edge)
		check(ball.trail.all(func(p): return absf(p.y - ball.pos.y) < 12), "Wrap clears its teleport trail: " + edge)
	var run = fixture("carouser")
	run.player.pos = Vector2(300, 650)
	var ball = run.add_ball(Vector2(300, 620), Vector2.UP, "iron", 1, false)
	ball.orbit = true
	ball.angle = -PI / 2
	run.enemies[0].pos = Vector2(300, 620)
	run._update_ball(ball, .01)
	check(run.enemies[0].hp < 1000000 and not ball.dead, "Orbiting balls retain enemy collision")
	run.player.pos = Vector2(25, 650)
	ball.angle = PI
	ball.orbit_time = 0
	run._update_ball(ball, .01)
	check(ball.pos.x >= RonkeRun.WALL_LEFT + ball.radius, "Orbit remains visible inside side wall")
	run = fixture("flagellant")
	ball = run.add_ball(Vector2(100, 796), Vector2.DOWN, "baby", 1, false)
	run._update_ball(ball, .02)
	check(ball.velocity.y < 0 and ball.pos.y <= RonkeRun.WALL_BOTTOM - ball.radius, "Bottom bounce uses the visible wall and ball radius")
	run = fixture()
	ball = run.add_ball(Vector2(578, 300), Vector2.RIGHT, "iron_pellet", 1, false)
	var shot = {"pos": Vector2(578, 300), "radius": 5, "velocity": Vector2.DOWN, "damage": 10, "dead": false}
	run.bullets.append(shot)
	run._update_ball(ball, .01)
	check(ball.dead and not shot.dead, "Pellet cannot intercept a shot after being destroyed at a wall")
	for state in ["grounded", "airborne", "recalling"]:
		run = fixture()
		run.practice = false
		ball = run.add_ball(Vector2(300, 719), Vector2.ZERO, "iron", 1, false)
		if state == "airborne":
			ball.air_time = .5
			ball.air_duration = .5
			ball.lob_from = ball.pos
			ball.lob_target = Vector2(300, 300)
		elif state == "recalling":
			ball.manual_recall = true
			ball.returning = true
		shot = {"pos": Vector2(300, 700), "radius": 5, "velocity": Vector2.DOWN * 6000, "damage": 10, "dead": false}
		run.bullets.append(shot)
		run.advance(1.0 / 120)
		check(run.player.hp == (100 if state == "grounded" else 90), "Projectile interception resolves before player damage: " + state)
	run = fixture("tactician")
	run.practice = false
	run.turn_phase = "enemy"
	run.enemy_turn_left = .4
	ball = run.add_ball(Vector2(300, 719), Vector2.ZERO, "iron", 1, false)
	run.bullets.append({"pos": Vector2(300, 700), "radius": 5, "velocity": Vector2.DOWN * 6000, "damage": 10, "dead": false})
	run.advance(1.0 / 120)
	check(run.player.hp == 100, "Held Tactician balls still intercept moving hostile projectiles")
	run = fixture()
	ball = run.add_ball(Vector2(570, 300), Vector2.RIGHT, "iron", 1, false)
	for _i in range(30): run._update_ball(ball, 1.0 / 120)
	check(ball.trail.size() <= 8 and run._trail_length(ball.trail) <= 34, "Motion trails are bounded")
	check(ball.trail.all(func(p): return p.x >= RonkeRun.WALL_LEFT and p.x <= RonkeRun.WALL_RIGHT), "Trail follows actual reflected positions inside the arena")
	for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.ONE.normalized(), Vector2(1,-1).normalized()]:
		var points = RonkeArena.field_beam_endpoints(Vector2(300, 400), direction)
		check(points.size() == 2 and points.all(func(p): return p.x >= 15.99 and p.x <= 584.01 and p.y >= 21.99 and p.y <= 804.01), "Laser feedback stays inside collision boundaries")
	check(RonkeArena.field_beam_endpoints(Vector2(300,400), Vector2.ZERO).is_empty(), "Zero-length beam is safe")
	var before = RonkeBallRules.geometry("fire", 58)
	for id in RonkeData.all().ball_visuals:
		var marks = RonkeBallVisuals.marks(id)
		check(not marks.is_empty(), "Readable glyph: " + id)
		for mark in marks:
			if mark.kind == "circle":
				check(Vector2(mark.center[0], mark.center[1]).length() + float(mark.radius) <= .95, "Circle glyph remains inside ball body: " + id)
			else:
				check(mark.points.all(func(p): return Vector2(p[0],p[1]).length() <= .9), "Glyph remains inside ball body: " + id)
	check(RonkeBallRules.geometry("fire", 58) == before and is_equal_approx(before, 5.5), "Visual changes do not enlarge physical ball sizes")
	check(RonkeData.orb_color("blizzard").b > RonkeData.orb_color("blizzard").r, "Ice evolution is blue rather than arbitrary pink")
	check(RonkeData.orb_color("bomb").r > RonkeData.orb_color("bomb").b, "Explosive evolution uses a warm color")
	var ray = RonkeArena.field_beam_endpoints(Vector2(300,400), Vector2.RIGHT, true)
	check(ray.size() == 2 and ray[0] == Vector2(300,400) and ray[1].x == RonkeRun.WALL_RIGHT, "Cutter ray does not draw behind the ball")
	run = fixture()
	run.element_levels.freeze_ray = 3
	ball = run.add_ball(Vector2(300,400), Vector2.UP, "freeze_ray", 1, false)
	ball.parameters.chance = 1.0
	run.hit(run.enemies[0], ball)
	check(run.enemies[0].freeze == 13, "Freeze Ray response uses its actual level-three duration")
	var arena = RonkeArena.new()
	root.add_child(arena)
	await process_frame
	run = fixture()
	run.balls.clear()
	var index = 0
	for id in RonkeData.all().ball_visuals:
		run.add_ball(Vector2(40 + (index % 10) * 55, 70 + (index / 10) * 55), Vector2.UP, id, 1, false)
		index += 1
	for kind in ["time_snare", "magma", "swamp", "glacier", "landslide", "armageddon", "delayed_bomb"]:
		run.add_hazard(kind, Vector2(200,400), 45, 3)
	arena.size = Vector2(600,820)
	arena.active = false
	for world in range(3):
		run.world = world
		arena.set_run(run)
		for enabled in [true, false]:
			arena.configure_presentation(enabled, false)
			arena.push_event({"type": "beam", "pos": Vector2(300,400), "horizontal": false, "mode": "ray", "direction": Vector2.UP})
			var draws = arena.draw_count
			arena.queue_redraw()
			await process_frame
			await process_frame
			check(arena.draw_count > draws, "Native glyph/hazard/beam drawing in biome " + str(world) + " effects=" + str(enabled))
	arena.queue_free()
	if failures.is_empty():
		print("PASS: ball appearance and environment / ", checks, " checks")
		quit()
	else:
		print("FAIL: ", failures.size(), " / ", checks)
		quit(1)
