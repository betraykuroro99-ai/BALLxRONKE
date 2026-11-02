class_name RonkeCombatGeometry
extends RefCounted

# Exact swept circle against a square: four faces and four rounded corners.
# This avoids both tunnelling and the false corner hits from an expanded AABB.
static func circle_box_overlap(pos: Vector2, radius: float, center: Vector2, half: float) -> bool:
	var nearest = pos.clamp(center - Vector2.ONE * half, center + Vector2.ONE * half)
	return pos.distance_squared_to(nearest) <= radius * radius + 0.00001

static func sweep_circle_box(start: Vector2, end: Vector2, radius: float, center: Vector2, half: float) -> Dictionary:
	var motion = end - start
	if circle_box_overlap(start, radius, center, half):
		var nearest = start.clamp(center - Vector2.ONE * half, center + Vector2.ONE * half)
		var normal = (start - nearest).normalized()
		if normal == Vector2.ZERO:
			var side = start - center
			if absf(side.x) > absf(side.y): normal = Vector2(signf(side.x), 0)
			else: normal = Vector2(0, signf(side.y))
			if normal == Vector2.ZERO: normal = -motion.normalized() if motion != Vector2.ZERO else Vector2.UP
		return {"fraction": 0.0, "normal": normal, "pos": start}
	if motion.length_squared() < 0.00000001: return {}
	var best: Dictionary = {}
	for axis in range(2):
		if absf(motion[axis]) < 0.000001: continue
		for side in [-1.0, 1.0]:
			var plane: float = center[axis] + side * (half + radius)
			var fraction: float = (plane - start[axis]) / motion[axis]
			if fraction < 0 or fraction > 1: continue
			var point: Vector2 = start + motion * fraction
			if absf(point[1 - axis] - center[1 - axis]) > half: continue
			var normal = Vector2.ZERO
			normal[axis] = side
			if motion.dot(normal) >= 0: continue
			if best.is_empty() or fraction < best.fraction: best = {"fraction": fraction, "normal": normal, "pos": point}
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var corner: Vector2 = center + Vector2(x, y) * half
			var relative = start - corner
			var a = motion.length_squared()
			var b = 2.0 * relative.dot(motion)
			var c = relative.length_squared() - radius * radius
			var discriminant = b * b - 4.0 * a * c
			if discriminant < 0: continue
			var fraction = (-b - sqrt(discriminant)) / (2.0 * a)
			if fraction < 0 or fraction > 1: continue
			var point: Vector2 = start + motion * fraction
			if (point.x - corner.x) * x < -0.00001 or (point.y - corner.y) * y < -0.00001: continue
			if best.is_empty() or fraction < best.fraction: best = {"fraction": fraction, "normal": (point - corner).normalized(), "pos": point}
	return best

static func segment_circle(start: Vector2, end: Vector2, center: Vector2, radius: float) -> bool:
	var motion = end - start
	var fraction = clampf((center - start).dot(motion) / motion.length_squared(), 0, 1) if motion.length_squared() > 0.000001 else 0.0
	return (start + motion * fraction).distance_squared_to(center) <= radius * radius

static func moving_circles(a_start: Vector2, a_end: Vector2, b_start: Vector2, b_end: Vector2, radius: float) -> Dictionary:
	var start = a_start - b_start
	var motion = (a_end - a_start) - (b_end - b_start)
	if start.length_squared() <= radius * radius:
		var normal = start.normalized()
		if normal == Vector2.ZERO: normal = -motion.normalized() if motion != Vector2.ZERO else Vector2.UP
		return {"fraction": 0.0, "normal": normal}
	var a = motion.length_squared()
	if a < 0.00000001: return {}
	var b = 2.0 * start.dot(motion)
	var c = start.length_squared() - radius * radius
	var discriminant = b * b - 4.0 * a * c
	if discriminant < 0: return {}
	var fraction = (-b - sqrt(discriminant)) / (2.0 * a)
	if fraction < 0 or fraction > 1: return {}
	return {"fraction": fraction, "normal": (start + motion * fraction).normalized()}
