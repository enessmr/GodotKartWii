extends Control

@export var stream: AudioStreamPlayer
@export var current: Control
@export var robo: Node3D
@export var car_select: Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_robo1_pressed() -> void:
	robo.char_selected = true
	await get_tree().create_timer(1.3).timeout
	stream.volume_db = 0.0
