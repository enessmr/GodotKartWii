extends Control

@export var current: Control
@export var track_selection: Control
@export var char: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	char.vehiclesel = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
