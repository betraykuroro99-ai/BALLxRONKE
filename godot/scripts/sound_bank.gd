class_name RonkeSound
extends Node

var muted = true
var voices: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}
var voice_index = 0
var last_shot = 0

func _ready() -> void:
	for _i in range(8):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -22
		add_child(voice)
		voices.append(voice)
	for pair in [["shot", 340.0, 0.04], ["kill", 620.0, 0.07], ["hurt", 110.0, 0.16], ["level", 880.0, 0.22], ["surge", 440.0, 0.3]]:
		var data = PackedByteArray()
		var count = int(22050 * pair[2])
		data.resize(count * 2)
		for i in range(count):
			var envelope = minf(1, i / 80.0) * pow(1.0 - float(i) / count, 2)
			data.encode_s16(i * 2, int(sin(TAU * pair[1] * i / 22050.0) * 14000 * envelope))
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = data
		tones[pair[0]] = stream

func play_event(kind: String) -> void:
	if muted or not tones.has(kind) or voices.is_empty():
		return
	if kind == "shot":
		if Time.get_ticks_msec() - last_shot < 90:
			return
		last_shot = Time.get_ticks_msec()
	var voice = voices[voice_index % voices.size()]
	voice_index += 1
	voice.stream = tones[kind]
	voice.play()
