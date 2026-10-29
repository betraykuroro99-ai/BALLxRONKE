extends SceneTree

const ANIMATIONS = {
	"idle": {"frames": [0], "fps": 1.0, "loop": true},
	"walk": {"frames": [4, 5], "fps": 6.0, "loop": true},
	"throw": {"frames": [1, 2, 3, 0], "fps": 8.0, "loop": false},
	"hurt": {"frames": [6, 0], "fps": 5.0, "loop": false},
	"defeat": {"frames": [6, 7], "fps": 5.0, "loop": false}
}

func _init() -> void:
	call_deferred("_build")

func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/animations"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/runners"))
	for crew in RonkeData.all().crew:
		var strip = load("res://assets/crew/" + crew.id + ".png")
		var frames = SpriteFrames.new()
		frames.remove_animation("default")
		for name in ANIMATIONS:
			var definition: Dictionary = ANIMATIONS[name]
			frames.add_animation(name)
			frames.set_animation_speed(name, definition.fps)
			frames.set_animation_loop(name, definition.loop)
			for index in definition.frames:
				var atlas = AtlasTexture.new()
				atlas.atlas = strip
				atlas.region = Rect2(index * 128, 0, 128, 128)
				frames.add_frame(name, atlas)
		var path = "res://assets/animations/" + crew.id + ".tres"
		if ResourceSaver.save(frames, path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		var runner = Node2D.new()
		runner.name = str(crew.id).to_pascal_case() + "Runner"
		runner.set_meta("crew_id", crew.id)
		var sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.sprite_frames = load(path)
		sprite.offset = Vector2(0, -56)
		sprite.animation = &"idle"
		sprite.autoplay = "idle"
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		runner.add_child(sprite)
		sprite.owner = runner
		var scene = PackedScene.new()
		if scene.pack(runner) != OK or ResourceSaver.save(scene, "res://scenes/runners/" + crew.id + ".tscn") != OK:
			push_error("Could not save runner scene: " + crew.id)
			quit(1)
			return
		runner.free()
	print("PASS: generated 23 SpriteFrames resources and 23 editor-ready AnimatedSprite2D runner scenes.")
	quit(0)
