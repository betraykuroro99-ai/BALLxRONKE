class_name RonkeSave
extends RefCounted

const PATH = "user://progress.json"
const BACKUP = "user://progress.backup.json"
const VERSION = 1
static var active_path = PATH
static var backup_path = BACKUP

static func use_test_profile(name: String) -> void:
	# Tests never overwrite a player's normal save, including on Windows/macOS.
	var folder = "user://qa/" + name.validate_filename()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	active_path = folder + "/progress.json"
	backup_path = folder + "/progress.backup.json"

static func fresh() -> Dictionary:
	return {"version": VERSION, "shards": 0, "total_kills": 0, "best_wave": 0,
		"runs": 0, "wins": 0, "last_crew": "warrior", "world": 0,
		"last_run": {}, "muted": true, "volume": 0.65, "shake": 0.5, "meta": {"vitality": 0, "power": 0, "reserves": 0}}

static func load_progress() -> Dictionary:
	for path in [active_path, backup_path]:
		if not FileAccess.file_exists(path):
			continue
		var f = FileAccess.open(path, FileAccess.READ)
		if not f:
			continue
		var parser = JSON.new()
		if parser.parse(f.get_as_text()) != OK:
			continue
		var raw = parser.data
		if raw is Dictionary:
			var version = raw.get("version", 0)
			if (version is int or version is float) and is_finite(float(version)) and int(version) == VERSION:
				return sanitize(raw)
	return fresh()

static func sanitize(raw: Dictionary) -> Dictionary:
	var result = fresh()
	for key in ["shards", "total_kills", "best_wave", "runs", "wins"]:
		var value = raw.get(key, 0)
		if (value is int or value is float) and is_finite(float(value)):
			result[key] = clampi(int(value), 0, 100000000)
	result["best_wave"] = mini(int(result["best_wave"]), 10)
	var meta = raw.get("meta", {})
	if meta is Dictionary:
		for key in result["meta"]:
			var value = meta.get(key, 0)
			if (value is int or value is float) and is_finite(float(value)):
				result["meta"][key] = clampi(int(value), 0, 3)
	var id = str(raw.get("last_crew", "warrior"))
	if RonkeData.crew(id).get("id") == id:
		result["last_crew"] = id
	result["world"] = clampi(int(raw.get("world", 0)), 0, 2) if raw.get("world", 0) is float or raw.get("world", 0) is int else 0
	result["muted"] = raw.get("muted", true) != false
	for key in ["volume", "shake"]:
		var value = raw.get(key, result[key])
		if (value is int or value is float) and is_finite(float(value)):
			result[key] = clampf(float(value), 0.0, 1.0)
	result.last_run = sanitize_report(raw.get("last_run", {}))
	return result

static func sanitize_report(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.is_empty():
		return {}
	var id = str(raw.get("crew", ""))
	if RonkeData.crew(id).id != id:
		return {}
	var result = {"crew": id, "win": raw.get("win", false) == true,
		"reason": str(raw.get("reason", "defeated")), "elements": [], "picks": []}
	if not result.reason in ["victory", "projectile", "breach", "guardian_breach", "impact", "abandoned", "defeated"]:
		result.reason = "defeated"
	for key in ["world", "wave", "time", "kills", "guardians", "reward", "shots", "dashes", "surges", "breaches", "damage_taken", "combo", "bounces"]:
		var value = raw.get(key, 0)
		result[key] = clampf(float(value), 0.0, 100000000.0) if (value is int or value is float) and is_finite(float(value)) else 0.0
	result.world = mini(int(result.world), 2)
	result.wave = mini(int(result.wave), 10)
	result.guardians = mini(int(result.guardians), 2)
	if raw.get("elements") is Array:
		for element in raw.elements.slice(0, 19):
			if element is String and RonkeData.all().elements.has(element) and not result.elements.has(element):
				result.elements.append(element)
	if raw.get("picks") is Array:
		for pick in raw.picks.slice(0, 50):
			if pick is String:
				result.picks.append(pick.left(80))
	return result

static func write_progress(progress: Dictionary) -> Error:
	var temp = active_path + ".tmp"
	var f = FileAccess.open(temp, FileAccess.WRITE)
	if not f:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(sanitize(progress), "\t"))
	f.flush()
	f.close()
	if FileAccess.file_exists(active_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		var backup_error = DirAccess.rename_absolute(active_path, backup_path)
		if backup_error != OK:
			return backup_error
	var error = DirAccess.rename_absolute(temp, active_path)
	if error != OK and FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(backup_path, active_path)
	return error
