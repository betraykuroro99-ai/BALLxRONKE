class_name RonkeSound
extends Node

# Short original synthesized cues: no downloads, streaming, or runtime allocations.
const RATE = 22050
const COOLDOWNS = {"shot": 100, "hit": 75, "crit": 100, "kill": 85, "bounce": 130, "windup": 250}
const PRIORITY = {"shot": 0, "bounce": 0, "hit": 1, "kill": 1, "crit": 2, "dash": 2,
	"shield": 2, "windup": 2, "hurt": 3, "wave": 3, "boss": 4, "level": 4, "surge": 4, "victory": 5, "defeat": 5}
var muted = true
var volume = 0.65
var voices: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}
var last_played: Dictionary = {}
var priorities: Array[int] = []
var started: Array[int] = []

func _ready() -> void:
	for _i in range(10):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
		priorities.append(-1)
		started.append(0)
	# Start/end frequency, duration, noise blend, harmonic blend.
	var recipes = {
		"shot": [420.0, 230.0, 0.055, 0.08, 0.15], "bounce": [760.0, 540.0, 0.045, 0.03, 0.25],
		"hit": [190.0, 65.0, 0.085, 0.38, 0.2], "crit": [850.0, 180.0, 0.14, 0.2, 0.45],
		"kill": [340.0, 90.0, 0.14, 0.3, 0.3], "hurt": [140.0, 48.0, 0.25, 0.35, 0.5],
		"dash": [170.0, 650.0, 0.13, 0.5, 0.0], "shield": [500.0, 1050.0, 0.17, 0.02, 0.4],
		"windup": [390.0, 650.0, 0.19, 0.02, 0.3], "wave": [220.0, 330.0, 0.28, 0.04, 0.3], "boss": [130.0, 55.0, 0.6, 0.12, 0.55],
		"level": [440.0, 880.0, 0.4, 0.0, 0.35], "surge": [110.0, 880.0, 0.48, 0.2, 0.5],
		"victory": [440.0, 880.0, 0.7, 0.0, 0.45], "defeat": [220.0, 55.0, 0.65, 0.06, 0.25]}
	for kind in recipes:
		tones[kind] = _synthesize(recipes[kind])

func _synthesize(recipe: Array) -> AudioStreamWAV:
	var data = PackedByteArray()
	var count = int(RATE * recipe[2])
	data.resize(count * 2)
	var phase = 0.0
	var random = RandomNumberGenerator.new()
	random.seed = 7391
	for i in range(count):
		var t = float(i) / count
		phase += TAU * lerpf(recipe[0], recipe[1], t) / RATE
		var envelope = minf(1.0, i / 110.0) * pow(1.0 - t, 2)
		var tone = (sin(phase) + sin(phase * 2.0) * recipe[4]) / (1.0 + recipe[4])
		var sample = lerpf(tone, random.randf_range(-1, 1), recipe[3])
		data.encode_s16(i * 2, int(clampf(sample * envelope, -1, 1) * 24000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	return stream

func play_event(kind: String, event: Dictionary = {}) -> void:
	if kind == "hit" and event.get("crit", false):
		kind = "crit"
	elif kind == "wave" and event.get("boss", false):
		kind = "boss"
	elif kind == "boss_phase":
		kind = "boss"
	elif kind == "end":
		kind = "victory" if event.get("win", false) else "defeat"
	if muted or volume <= 0 or not tones.has(kind) or voices.is_empty():
		return
	var now = Time.get_ticks_msec()
	if now - int(last_played.get(kind, -10000)) < int(COOLDOWNS.get(kind, 0)):
		return
	var priority = int(PRIORITY.get(kind, 2))
	var slot = -1
	for i in range(voices.size()):
		if not voices[i].playing:
			slot = i
			break
		if priorities[i] <= priority and (slot < 0 or priorities[i] < priorities[slot] or (priorities[i] == priorities[slot] and started[i] < started[slot])):
			slot = i
	if slot < 0:
		return
	last_played[kind] = now
	priorities[slot] = priority
	started[slot] = now
	var voice = voices[slot]
	voice.stream = tones[kind]
	voice.pitch_scale = randf_range(0.96, 1.04) if priority < 3 else 1.0
	voice.volume_db = linear_to_db(volume) - (25.0 if kind in ["shot", "bounce"] else 20.0 if priority < 3 else 15.0)
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
