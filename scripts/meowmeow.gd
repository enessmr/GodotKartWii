extends Node3D
@export var rigidbody3d: RigidBody3D

# for all fucking nitro tracks (wii)
var max_laps = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rigidbody3d.racing = true
