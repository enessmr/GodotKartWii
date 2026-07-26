extends Control

@export var stream1: AudioStreamPlayer
@export var stream2: AudioStreamPlayer
@export var timetrials3d: Control
@export var current: Control

func _on_time_trials_pressed() -> void:
	if stream1:
		stream1.stream_paused = false
		stream1.volume_db = 0.0
	if stream2:
		stream2.stream_paused = false
		stream2.volume_db = 0.0
	timetrials3d.show()
	current.hide()
