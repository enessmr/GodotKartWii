extends RigidBody3D

@export var acceleration := 45.0
@export var steering := 3.0
@export var turn_stop_limit := 0.75
@export var max_speed := 85.0
@export var friction := 5.0

@export_category("DUMBSEEK SHIT")
@export var center_offset := Vector3(0, -1.2, 0)

@export var wheelie_speed := 95.0
@export var wheelie_ev_max := 120.0
@export var wheelie_rotation_speed := 2.5
@export var wheelie_gravity_scale := 0.5
@export var wheelie_balance_force := 15.0
@export var wheelie_duration := 10.0
@export var wheelie_exit_speed_multiplier := 0.95

@export_category("NOT DUMBSEEK SHIT")
@export var anim: AnimationPlayer
@export var jg: Node3D
@export var course: Node3D
@export var race_final: AudioStreamPlayer
@export var hoohoo: AudioStreamPlayer3D
var lap_count

var is_race_about_to_start := true
var is_wong_way := false
var is_fallen_down := false

@export_category("DUMBSEEK SHIT")
@export var race_start_sound: AudioStreamPlayer
@export var race_music: AudioStreamPlayer
@export var slope_grip := 20.0
@export var slope_boost := 35.0

@export_category("CANNON SETTINGS")
@export var cannon_gravity_scale: float = 0.1
@export var cannon_rotation_speed: float = 5.0

# Cannon state

var is_in_cannon := false
var current_cannon_path: Path3D = null
var current_path_progress := 0.0
var current_path_length := 0.0
var cannon_speed := 50.0
var exit_velocity_multiplier := 1.5

var iv_speed := 0.0
var ev_speed := 0.0

var speed_input := 0.0
var turn_input := 0.0
var racing := false
var is_wheelie := false
var wheelie_timer := 0.0
var wheelie_active_time := 0.0
var is_exiting_wheelie := false
var exit_speed_scale := 1.0
var wheelie_animation_playing := false

@onready var ground_ray: RayCast3D = $"RayCast3D"
@export var robo: Node3D
@export var front_wheel: Node3D
var wheel_rotation_angle := 0.0

func _ready():
	ground_ray.add_exception(self)
	center_of_mass = center_offset
	
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	
	if robo:
		robo.racing = true
		if robo.has_method("start_race"):
			robo.start_race()
		robo.racing = true
		if robo.has_signal("race_start_animation_finished"):
			robo.race_start_animation_finished.connect(_on_race_start_animation_finished)
	
	if is_race_about_to_start:
		play_race_start_sequence()
	lap_count = 1

func _physics_process(delta):
	# CANNON PATH FOLLOWING
	if is_in_cannon and current_cannon_path:
		current_path_progress += cannon_speed * delta

		if current_path_progress >= current_path_length:
			exit_cannon()
			return

		var path_pos = current_cannon_path.curve.sample_baked(current_path_progress)
		var global_path_pos = current_cannon_path.to_global(path_pos)

		global_position = global_path_pos

		var next_pos = current_cannon_path.curve.sample_baked(
			min(current_path_progress + 0.1, current_path_length)
		)

		var global_next_pos = current_cannon_path.to_global(next_pos)

		var direction = (global_next_pos - global_path_pos).normalized()

		if direction.length() > 0.1:
			var target_basis = Basis.looking_at(-direction, Vector3.UP)
			global_transform.basis = global_transform.basis.slerp(target_basis, delta * cannon_rotation_speed)

		return
	
	if is_race_about_to_start:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	
	speed_input = Input.get_axis("brake", "accelerate")
	turn_input = Input.get_axis("steer_left", "steer_right")
	
	if Input.is_action_just_pressed("wheelie"):
		if is_wheelie:
			start_wheelie_exit()
		elif not is_exiting_wheelie and ground_ray.is_colliding() and linear_velocity.length() > 5.0:
			start_wheelie()
	
	var normal := Vector3.UP
	if ground_ray.is_colliding():
		normal = ground_ray.get_collision_normal()
	
	var forward = global_transform.basis.z
	forward -= normal * forward.dot(normal)
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	# SLOPE BOOST (Mario Kart style)
	if ground_ray.is_colliding():
		var slope_amount = 1.0 - normal.dot(Vector3.UP)

		# Downhill boost
		if forward.dot(Vector3.DOWN) > 0.05:
			apply_central_force(forward * slope_boost * slope_amount)

		# Keep speed on uphill
		if forward.dot(Vector3.UP) > 0.05:
			apply_central_force(forward * acceleration * 0.25)

	var current_vel = linear_velocity.length()
	iv_speed = current_vel - ev_speed
	if iv_speed < 0:
		iv_speed = 0
	
	if is_wheelie:
		if not wheelie_animation_playing:
			anim.play("wheelie_bike_mach_end_fr")
			hoohoo.play()
			wheelie_animation_playing = true
		
		wheelie_active_time += delta
		
		if wheelie_active_time >= wheelie_duration:
			start_wheelie_exit()
		
		gravity_scale = wheelie_gravity_scale
		
		if speed_input != 0:
			if iv_speed < wheelie_speed:
				apply_central_force(forward * speed_input * acceleration)
		
		var total_speed = iv_speed + ev_speed
		if total_speed > wheelie_ev_max:
			var over_limit = total_speed - wheelie_ev_max
			if iv_speed > over_limit:
				iv_speed -= over_limit
				apply_central_force(-forward * over_limit * 10.0)
		
		if front_wheel and abs(turn_input) > 0.1:
			wheel_rotation_angle += turn_input * wheelie_rotation_speed * delta
			front_wheel.rotation.y = wheel_rotation_angle
		
		var balance_angle = global_rotation.x
		if balance_angle < 0.2:
			apply_torque(Vector3(-wheelie_balance_force, 0, 0))
		elif balance_angle > 0.6:
			apply_torque(Vector3(wheelie_balance_force * 0.5, 0, 0))
		
		if speed_input < 0.1 and wheelie_timer > 3.0:
			start_wheelie_exit()
		
		wheelie_timer += delta
		
	elif is_exiting_wheelie:
		exit_speed_scale *= wheelie_exit_speed_multiplier
		
		if iv_speed > max_speed:
			var target_iv = iv_speed * exit_speed_scale
			var slowdown_force = iv_speed - target_iv
			apply_central_force(-forward * slowdown_force * 10.0)
			iv_speed = target_iv
		
		gravity_scale = 1.0
		
		if iv_speed <= max_speed or exit_speed_scale < 0.1:
			is_exiting_wheelie = false
			exit_speed_scale = 1.0
			iv_speed = max_speed
		
		if speed_input != 0 and iv_speed < max_speed:
			apply_central_force(forward * speed_input * acceleration)
		
		if front_wheel and wheel_rotation_angle != 0:
			wheel_rotation_angle = 0
			front_wheel.rotation.y = 0
	
	else:
		gravity_scale = 1.0
		
		if speed_input != 0 and iv_speed < max_speed:
			apply_central_force(forward * speed_input * acceleration)
		
		if iv_speed > max_speed:
			var over_limit = iv_speed - max_speed
			apply_central_force(-forward * over_limit * 10.0)
			iv_speed = max_speed
		
		if front_wheel and wheel_rotation_angle != 0:
			wheel_rotation_angle = 0
			front_wheel.rotation.y = 0
	
	var sideways = linear_velocity - forward * linear_velocity.dot(forward)
	apply_central_force(-sideways * friction)
	
	if is_wheelie:
		if abs(turn_input) > 0.1:
			rotate_y(-turn_input * steering * delta * 0.3)
	else:
		if linear_velocity.length() > turn_stop_limit:
			rotate_y(-turn_input * steering * delta)

func enter_cannon(path: Path3D, speed: float = 50.0, exit_multiplier: float = 1.5):
	if is_in_cannon:
		return

	print("🚀 Entering cannon!")

	is_in_cannon = true
	current_cannon_path = path
	current_path_progress = 0.0
	current_path_length = path.curve.get_baked_length()
	cannon_speed = speed
	exit_velocity_multiplier = exit_multiplier

	gravity_scale = cannon_gravity_scale
	freeze = true

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	global_position = path.to_global(path.curve.sample_baked(0.0))

func exit_cannon():
	print("🚀 Exiting cannon!")

	is_in_cannon = false

	current_cannon_path = null
	current_path_progress = 0.0
	current_path_length = 0.0

	freeze = false
	gravity_scale = 1.0

	if anim and anim.has_animation("cannon_exit"):
		anim.play("cannon_exit")

func start_wheelie():
	if is_wheelie or is_exiting_wheelie:
		return
	
	print("🏍️ WHEELIE START!")
	
	is_wheelie = true
	wheelie_timer = 0.0
	wheelie_active_time = 0.0
	gravity_scale = wheelie_gravity_scale
	wheelie_animation_playing = false
	
	if robo and robo.has_method("play_wheelie"):
		robo.play_wheelie(true)
	
	apply_central_force(Vector3.UP * 50.0)

func start_wheelie_exit():
	if not is_wheelie:
		return
	
	print("Wheelie stopped")
	
	is_wheelie = false
	is_exiting_wheelie = true
	exit_speed_scale = 1.0
	gravity_scale = 1.0
	wheelie_animation_playing = false
	
	if robo and robo.has_method("play_wheelie"):
		robo.play_wheelie(false)
	
	if front_wheel:
		wheel_rotation_angle = 0
		front_wheel.rotation.y = 0

func add_ev_boost(amount: float):
	ev_speed += amount
	if is_wheelie and (iv_speed + ev_speed) > wheelie_ev_max:
		ev_speed = wheelie_ev_max - iv_speed
	elif not is_wheelie and (iv_speed + ev_speed) > max_speed:
		ev_speed = max_speed - iv_speed

func remove_ev_boost(amount: float):
	ev_speed -= amount
	if ev_speed < 0:
		ev_speed = 0

func on_wheelie_animation_complete():
	if is_wheelie:
		start_wheelie_exit()

func next_lap():
	lap_count += 1
	if lap_count == course.max_laps:
		jg.finallap()
		race_music.stop()
		await get_tree().create_timer(3.0)
		race_final.start()
	else:
		jg.next_lap()

func play_race_start_sequence():
	print("🏁 Race about to start!")
	
	if race_start_sound:
		race_start_sound.play()
	
	jg.is_race_about_to_start = true
	jg.start_the_frickon_shit()

func _on_race_start_animation_finished():
	print("🏁 Race start animation finished!")
	
	if race_music:
		race_music.play()
	
	is_race_about_to_start = false
	jg.is_race_about_to_start = false
	print("🏁 GO! Race started!")

func _on_anim_animation_finished(anim_name: String):
	if anim_name == "race_start":
		_on_race_start_animation_finished()

func end_race():
	is_race_about_to_start = true
	if race_music:
		race_music.stop()
	if race_start_sound:
		race_start_sound.stop()
