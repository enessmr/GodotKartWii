extends Area3D

@export var path_3d: Path3D  # The path this cannon uses
@export var cannon_speed: float = 50.0
@export var exit_velocity_multiplier: float = 1.5

func _ready():
	body_entered.connect(_on_body_entered)
	
	if not path_3d:
		var parent = get_parent()
		for child in parent.get_children():
			if child is Path3D:
				path_3d = child
				break

func _on_body_entered(body: Node):
	if body is RigidBody3D and path_3d:
		if body.has_method("enter_cannon"):
			# The vehicle should enter at the START of the path
			# The Area3D should be positioned at the cannon entrance
			body.enter_cannon(path_3d, cannon_speed, exit_velocity_multiplier)
			print("🚀 Vehicle entered cannon!")
