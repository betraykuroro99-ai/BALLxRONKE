class_name RonkeBallVisuals
extends RefCounted

# Marks stay inside the unchanged circular hitbox. Shared primitives also drive
# the contact-sheet preview; decoration never changes simulation geometry.
static func definition(element: String) -> Dictionary:
	return RonkeData.all().get("ball_visuals", {}).get(element, {"family": "baby", "accent": "#101d3d", "axis": "vertical"})

static func marks(element: String) -> Array:
	var result = _family_marks(element)
	var data = definition(element)
	if data.has("secondary"): result.append({"kind": "circle", "center": [.5, -.5], "radius": .13, "color": data.secondary})
	return result

static func _family_marks(element: String) -> Array:
	var data = definition(element)
	match data.family:
		"spiked": return [{"kind": "line", "points": [[-.65,0],[.65,0]]}, {"kind": "line", "points": [[0,-.65],[0,.65]]}, {"kind": "circle", "center": [0,0], "radius": .25}]
		"flame": return [{"kind": "poly", "points": [[-.5,.45],[-.55,-.05],[-.12,-.2],[.05,-.72],[.5,-.1],[.42,.45],[0,.65]]}]
		"ice": return [{"kind": "line", "points": [[-.6,-.35],[.6,.35]]}, {"kind": "line", "points": [[-.6,.35],[.6,-.35]]}, {"kind": "line", "points": [[0,-.7],[0,.7]]}]
		"toxic": return [{"kind": "poly", "points": [[0,-.7],[.5,.1],[.35,.6],[-.35,.6],[-.5,.1]]}, {"kind": "circle", "center": [0,.2], "radius": .15, "ink": true}]
		"laser":
			if data.axis == "horizontal": return [{"kind": "line", "points": [[-.75,0],[.75,0]]}]
			if data.axis == "diagonal": return [{"kind": "line", "points": [[-.55,-.55],[.55,.55]]},{"kind": "line", "points": [[-.55,.55],[.55,-.55]]}]
			if data.axis == "cross": return [{"kind": "line", "points": [[-.75,0],[.75,0]]},{"kind": "line", "points": [[0,-.75],[0,.75]]}]
			return [{"kind": "line", "points": [[0,-.75],[0,.75]]}]
		"metal": return [{"kind": "poly", "points": [[-.5,-.5],[.5,-.5],[.5,.5],[-.5,.5]]}, {"kind": "circle", "center": [0,0], "radius": .18, "ink": true}]
		"stone": return [{"kind": "line", "points": [[-.5,-.65],[-.1,-.1],[.4,.15],[.1,.65]]}, {"kind": "line", "points": [[-.1,-.1],[-.6,.35]]}]
		"ghost": return [{"kind": "circle", "center": [-.28,-.1], "radius": .16},{"kind": "circle", "center": [.28,-.1], "radius": .16},{"kind": "line", "points": [[-.55,.5],[-.2,.3],[.1,.55],[.5,.3]]}]
		"heart": return [{"kind": "poly", "points": [[0,-.25],[-.35,-.55],[-.65,-.2],[-.5,.2],[0,.65],[.5,.2],[.65,-.2],[.35,-.55]]}]
		"light": return [{"kind": "poly", "points": [[0,-.75],[.22,-.22],[.75,0],[.22,.22],[0,.75],[-.22,.22],[-.75,0],[-.22,-.22]]}]
		"bolt": return [{"kind": "poly", "points": [[.2,-.75],[-.55,.1],[-.05,.1],[-.2,.75],[.6,-.15],[.1,-.15]]}]
		"egg": return [{"kind": "line", "points": [[-.65,0],[-.25,-.25],[.1,.15],[.35,-.2],[.65,0]]}, {"kind": "circle", "center": [0,.4], "radius": .16}]
		"cell": return [{"kind": "circle", "center": [-.2,-.2], "radius": .3},{"kind": "circle", "center": [.35,.25], "radius": .2}]
		"clock": return [{"kind": "line", "points": [[0,-.65],[0,0],[.5,.2]]}, {"kind": "circle", "center": [0,0], "radius": .12}]
		"wind": return [{"kind": "line", "points": [[-.65,-.3],[.5,-.3],[.65,-.5]]},{"kind": "line", "points": [[-.65,.3],[.35,.3],[.5,.5]]}]
		"flesh": return [{"kind": "line", "points": [[-.6,-.3],[0,0],[.5,-.5]]},{"kind": "line", "points": [[0,0],[.1,.65],[.6,.4]]}]
	return []

static func draw_ball(canvas: CanvasItem, ball: Dictionary, pos: Vector2) -> void:
	var radius: float = ball.radius
	var base = RonkeData.orb_color(ball.element)
	var data = definition(ball.element)
	var accent = Color(data.accent)
	canvas.draw_circle(pos, radius + float(RonkeData.all().ball_geometry.outline_pixels), Color("101d3d"))
	canvas.draw_circle(pos, radius, base)
	var width = maxf(.8, radius * .22)
	for mark in marks(ball.element):
		var color = Color(mark.color) if mark.has("color") else Color("101d3d") if mark.get("ink", false) else accent
		if mark.kind == "circle":
			canvas.draw_circle(pos + Vector2(mark.center[0], mark.center[1]) * radius, float(mark.radius) * radius, color)
		else:
			var points = PackedVector2Array()
			for point in mark.points: points.append(pos + Vector2(point[0], point[1]) * radius)
			if mark.kind == "poly": canvas.draw_colored_polygon(points, color)
			else: canvas.draw_polyline(points, color, width, true)
	if data.family == "baby": canvas.draw_circle(pos - Vector2.ONE * radius * .25, radius * .3, Color("fffaf0"))
