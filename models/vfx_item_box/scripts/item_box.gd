extends Node3D

var speed = 0.5
var angular_speed = PI

func _ready():
	pass
	
func _process(delta: float) -> void:
	rotate_y(speed * 1.8024 * delta)
	rotate_x(speed * 1.5766 * delta)
