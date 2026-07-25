extends Control
@export var stream1: AudioStreamPlayer
@export var stream2: AudioStreamPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_time_trials_pressed() -> void:
	stream1.play()
	stream2.play()
