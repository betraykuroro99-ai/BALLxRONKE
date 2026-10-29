class_name RonkeData
extends RefCounted

static var _data: Dictionary = {}

static func all() -> Dictionary:
	if _data.is_empty():
		var file = FileAccess.open("res://data/game_data.json", FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_data = parsed
	return _data

static func crew(id: String) -> Dictionary:
	for entry in all().get("crew", []):
		if entry.get("id", "") == id:
			return entry
	return all().get("crew", [{}])[0]

static func orb_color(id: String) -> Color:
	return Color(all().get("elements", {}).get(id, {}).get("color", "#e6ba7a"))
