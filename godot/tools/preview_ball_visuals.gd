extends SceneTree
func _init() -> void:
	var output = []
	for id in RonkeData.all().ball_visuals:
		output.append({"id": id, "name": RonkeData.all().elements[id].name, "radius": RonkeBallRules.geometry(id, 58), "color": RonkeData.orb_color(id).to_html(), "visual": RonkeBallVisuals.definition(id), "marks": RonkeBallVisuals.marks(id)})
	var args = OS.get_cmdline_user_args()
	var path = args[0] if not args.is_empty() else "/tmp/ronke-ball-visuals.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Cannot write visual preview data")
		quit(1)
		return
	file.store_string(JSON.stringify(output))
	print("PASS: exported ", output.size(), " shared ball glyph definitions")
	quit()
