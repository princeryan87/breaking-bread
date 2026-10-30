extends Node

class_name AudioManager

## ===== AUDIO PLAYERS =====
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var engine_player: AudioStreamPlayer = $EnginePlayer
@onready var police_siren: AudioStreamPlayer = $PoliceSiren

## ===== STATE =====
var engine_running: bool = false
var current_speed: float = 0.0

func _ready() -> void:
	# Create placeholder audio streams (replace with actual files later)
	# For now, we'll use silent placeholders
	music_player.stream = AudioStreamWAV.new()
	sfx_player.stream = AudioStreamWAV.new()
	engine_player.stream = AudioStreamWAV.new()
	police_siren.stream = AudioStreamWAV.new()

	engine_player.bus = "Effects"
	police_siren.bus = "Effects"

func play_music(stream: AudioStream) -> void:
	music_player.stream = stream
	music_player.play()

func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()

func set_engine_running(running: bool) -> void:
	engine_running = running
	if running:
		engine_player.play()
	else:
		engine_player.stop()

func update_engine_pitch(speed: float, max_speed: float) -> void:
	current_speed = speed
	if engine_running and max_speed > 0:
		var pitch = 0.5 + (speed / max_speed) * 1.0
		engine_player.pitch_scale = clamp(pitch, 0.5, 2.0)

func set_police_siren(active: bool) -> void:
	if active:
		police_siren.play()
	else:
		police_siren.stop()

func play_bake_complete() -> void:
	# Placeholder for bake complete sound
	pass

func play_sell_sound() -> void:
	# Placeholder for sell sound
	pass

func play_caught_sound() -> void:
	# Placeholder for caught sound
	pass

func play_upgrade_sound() -> void:
	# Placeholder for upgrade sound
	pass