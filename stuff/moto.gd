extends RigidBody3D

var sphere_offset = Vector3.DOWN

@export var acceleration := 350.0
@export var steering := 19.0
@export var turn_speed := 4.0
@export var turn_stop_limit := 0.75

@export var center_offset := Vector3(0, -0.7, 0)
@export var max_tilt := 35.0

var speed_input := 0.0
var turn_input := 0.0
var racing := false

@onready var car_mesh = $"the mach bike"
@onready var ground_ray = $"RayCast3D"

@export var robo: Node3D


func _ready():
	ground_ray.add_exception(self)

	# Lower center of mass for arcade stability
	center_of_mass = center_offset

	await get_tree().create_timer(0.2).timeout
	if robo:
		robo.racing = racing


func _physics_process(delta):
	speed_input = Input.get_axis("brake", "accelerate") * acceleration
	turn_input = Input.get_axis("steer_right", "steer_left") * deg_to_rad(steering)

	if ground_ray.is_colliding():
		# Forward force from the actual rigidbody direction
		apply_central_force(global_transform.basis.z * speed_input)

		# Steering torque
		if linear_velocity.length() > turn_stop_limit:
			apply_torque(Vector3.UP * turn_input * 100.0)

		# Align visual bike to slope
		var normal = ground_ray.get_collision_normal()
		var target = align_with_y(car_mesh.global_transform, normal)

		car_mesh.global_transform = car_mesh.global_transform.interpolate_with(
			target,
			10.0 * delta
		)

	# Stop the physics body from going completely upside down
	clamp_tilt()


func clamp_tilt():
	var rot = rotation

	rot.x = clamp(
		rot.x,
		deg_to_rad(-max_tilt),
		deg_to_rad(max_tilt)
	)

	rot.z = clamp(
		rot.z,
		deg_to_rad(-max_tilt),
		deg_to_rad(max_tilt)
	)

	rotation = rot


func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)

	return xform.orthonormalized()
