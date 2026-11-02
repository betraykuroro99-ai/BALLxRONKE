class_name RonkeBallRules
extends RefCounted

static func parameters(element: String, level: int = 1) -> Dictionary:
	var profile: Dictionary = RonkeData.all().get("ball_rules", {}).get(element, {})
	var levels: Array = profile.get("levels", [])
	return levels[clampi(level - 1, 0, 2)].duplicate(true) if levels.size() == 3 else {}

static func geometry(element: String, tile: float) -> float:
	var data: Dictionary = RonkeData.all().get("ball_geometry", {})
	var baby = element in ["baby", "fleshy_baby", "iron_pellet", "stone_pellet", "sniper_pellet"]
	var key = "fleshy_baby_radius_tiles" if element == "fleshy_baby" else "pellet_radius_tiles" if element in ["iron_pellet", "stone_pellet", "sniper_pellet"] else "baby_radius_tiles" if baby else "special_radius_tiles"
	return tile * float(data.get(key, 4.0 / 58.0 if baby else 5.5 / 58.0))

static func character(id: String) -> Dictionary:
	var data: Dictionary = RonkeData.all().get("character_rules", {})
	var result: Dictionary = data.get("default", {}).duplicate(true)
	result.merge(data.get(id, {}), true)
	return result

static func upgrade_description(element: String, current_level: int) -> String:
	var before = parameters(element, current_level)
	var after = parameters(element, current_level + 1)
	var labels = {"stacks": "Stacks per hit", "limit": "Maximum stacks", "duration": "Duration", "chance": "Chance", "heal": "Healing", "cooldown": "Reload", "speed": "Launch speed", "impact": "Initial impact", "erosion": "Damage lost per hit", "count_min": "Minimum spawned", "count_max": "Maximum spawned", "divisions": "Clone divisions", "interval": "Interval", "targets": "Targets", "percent": "Enemy-health damage", "threshold": "Trigger stacks", "hits": "Trigger hits", "curse_hits": "Curse trigger hits"}
	var changes: Array[String] = []
	for pair in [["low", "high", "Effect damage"], ["burn_low", "burn_high", "Burn damage"], ["poison_low", "poison_high", "Poison damage"], ["curse_low", "curse_high", "Curse damage"], ["berserk_low", "berserk_high", "Berserk damage"]]:
		if after.has(pair[0]) and (after[pair[0]] != before.get(pair[0]) or after[pair[1]] != before.get(pair[1])):
			changes.append("%s: %s–%s → %s–%s" % [pair[2], str(before[pair[0]]), str(before[pair[1]]), str(after[pair[0]]), str(after[pair[1]])])
	for key in labels:
		if not after.has(key) or after[key] == before.get(key): continue
		var old: String = str(before[key])
		var next: String = str(after[key])
		if key in ["chance", "speed", "impact", "erosion", "percent"]:
			old = "%.1f%%" % (float(before[key]) * 100)
			next = "%.1f%%" % (float(after[key]) * 100)
		elif key in ["duration", "cooldown", "interval"]:
			old += "s"
			next += "s"
		changes.append("%s: %s → %s" % [labels[key], old, next])
	if changes.is_empty(): changes.append("Keeps its current effect. Reach level 3 to use it in evolution recipes.")
	return "\n".join(changes)
