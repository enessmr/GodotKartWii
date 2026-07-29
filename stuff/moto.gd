extends RigidBody3D

@export var acceleration := 350.0
@export var steering := 3.0
@export var turn_stop_limit := 0.75
@export var max_speed := 30.0
@export var friction := 5.0

@export var slope_follow_speed := 8.0

@export var center_offset := Vector3(0, -1.2, 0)

var speed_input := 0.0
var turn_input := 0.0
var racing := false

@onready var ground_ray: RayCast3D = $"RayCast3D"

@export var robo: Node3D


func _ready():

	ground_ray.add_exception(self)

	center_of_mass = center_offset

	# prevent stupid flips
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	if robo:
		robo.racing = true



func _physics_process(delta):

	speed_input = Input.get_axis("brake", "accelerate")
	turn_input = Input.get_axis("steer_right", "steer_left")


	var normal := Vector3.UP

	if ground_ray.is_colliding():
		normal = ground_ray.get_collision_normal()



	# Forward projected onto slope

	var forward = global_transform.basis.z

	forward -= normal * forward.dot(normal)

	if forward.length() < 0.01:
		forward = Vector3.FORWARD

	forward = forward.normalized()



	# Acceleration

	if speed_input != 0:

		apply_central_force(
			forward * speed_input * acceleration
		)



	# Friction only sideways

	var sideways = linear_velocity - forward * linear_velocity.dot(forward)

	apply_central_force(
		-sideways * friction
	)



	# Speed limit

	if linear_velocity.length() > max_speed:

		linear_velocity = (
			linear_velocity.normalized()
			* max_speed
		)



	# Steering

	if linear_velocity.length() > turn_stop_limit:

		rotate_y(
			-turn_input * steering * delta
		)



	# Rotate body to slope AFTER movement calculations

	if ground_ray.is_colliding():

		align_to_slope(normal, delta)



func align_to_slope(normal: Vector3, delta):

	var yaw = global_rotation.y

	var forward = Vector3(
		sin(yaw),
		0,
		cos(yaw)
	)

	forward -= normal * forward.dot(normal)

	if forward.length() < 0.01:
		return

	forward = forward.normalized()


	var right = forward.cross(normal).normalized()


	var target = Basis(
		right,
		normal,
		forward
	).orthonormalized()


	var target_rotation = target.get_euler()

	# KEEP STEERING Y ROTATION
	target_rotation.y = yaw


	global_rotation = global_rotation.lerp(
		target_rotation,
		delta * slope_follow_speed
	)
