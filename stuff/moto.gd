extends RigidBody3D

@export var acceleration := 45.0
@export var steering := 3.0
@export var turn_stop_limit := 0.75
@export var max_speed := 85.0  # Base IV max speed
@export var friction := 5.0

@export_category("DUMBSEEK SHIT")
@export var center_offset := Vector3(0, -1.2, 0)

# Mach Wheelie settings (Mario Kart Wii style)
@export var wheelie_speed := 95.0  # IV speed during wheelie (Mach Wheelie)
@export var wheelie_ev_max := 120.0  # IV + EV combined max during wheelie
@export var wheelie_rotation_speed := 2.5  # Steering speed during wheelie
@export var wheelie_gravity_scale := 0.5  # Floaty feel
@export var wheelie_balance_force := 15.0  # Auto-balance
@export var wheelie_duration := 10.0  # Seconds
@export var wheelie_exit_speed_multiplier := 0.95  # Speed decay when wheelie ends

@export_category("NOT DUMBSEEK SHIT")
@export var anim: AnimationPlayer
@export var jg: Node3D

# Race state
var is_race_about_to_start := true  # Start as true so music plays
var is_wong_way := false
var is_fallen_down := false


@export_category("DUMBSEEK SHIT")
@export var race_start_sound: AudioStreamPlayer
@export var race_music: AudioStreamPlayer

# Internal Velocity (from your own acceleration)
var iv_speed := 0.0
# External Velocity (from mushrooms, boost pads, etc.)
var ev_speed := 0.0

var speed_input := 0.0
var turn_input := 0.0
var racing := false
var is_wheelie := false
var wheelie_timer := 0.0
var wheelie_active_time := 0.0
var is_exiting_wheelie := false
var exit_speed_scale := 1.0
var wheelie_animation_playing := false  # Track if animation is already playing

@onready var ground_ray: RayCast3D = $"RayCast3D"

@export var robo: Node3D  # Mach Bike model

# Front wheel that rotates during wheelie
@export var front_wheel: Node3D
var wheel_rotation_angle := 0.0


func _ready():
	ground_ray.add_exception(self)
	center_of_mass = center_offset
	
	# Prevent flips
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	if robo:
		robo.racing = true
	if robo and robo.has_method("start_race"):
		robo.start_race()
	
	# Also set racing flag
	if robo:
		robo.racing = true
	
	# Connect to robo's animation finished signal if it exists
	if robo and robo.has_signal("race_start_animation_finished"):
		robo.race_start_animation_finished.connect(_on_race_start_animation_finished)
	
	# Start race countdown
	if is_race_about_to_start:
		play_race_start_sequence()


func _physics_process(delta):
	# If race hasn't started, freeze the vehicle
	if is_race_about_to_start:
		# Completely freeze the vehicle during countdown
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		return
	
	speed_input = Input.get_axis("brake", "accelerate")
	turn_input = Input.get_axis("steer_right", "steer_left")
	
	# TOGGLE WHEELIE - Press wheelie button to start/stop
	if Input.is_action_just_pressed("wheelie"):
		if is_wheelie:
			start_wheelie_exit()  # Stop wheelie
		elif not is_exiting_wheelie and ground_ray.is_colliding() and linear_velocity.length() > 5.0:
			start_wheelie()  # Start wheelie
	
	var normal := Vector3.UP
	if ground_ray.is_colliding():
		normal = ground_ray.get_collision_normal()
	
	# Forward direction
	var forward = global_transform.basis.z
	forward -= normal * forward.dot(normal)
	if forward.length() < 0.01:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	
	# Calculate current IV (speed from acceleration)
	var current_vel = linear_velocity.length()
	iv_speed = current_vel - ev_speed
	if iv_speed < 0:
		iv_speed = 0
	
	# MACH WHEELIE LOGIC
	if is_wheelie:
		# Only play animation once, not every frame
		if not wheelie_animation_playing:
			anim.play("wheelie_bike_mach")
			wheelie_animation_playing = true
		
		wheelie_active_time += delta
		
		# Auto exit after 10 seconds
		if wheelie_active_time >= wheelie_duration:
			start_wheelie_exit()
		
		# Floaty feel
		gravity_scale = wheelie_gravity_scale
		
		# Apply IV acceleration with wheelie boost
		if speed_input != 0:
			# IV is capped at wheelie_speed (95) during wheelie
			if iv_speed < wheelie_speed:
				apply_central_force(
					forward * speed_input * acceleration
				)
		
		# Combined speed (IV + EV) capped at wheelie_ev_max (120)
		var total_speed = iv_speed + ev_speed
		if total_speed > wheelie_ev_max:
			# Reduce IV if total exceeds max (EV takes priority)
			var over_limit = total_speed - wheelie_ev_max
			if iv_speed > over_limit:
				iv_speed -= over_limit
				# Apply braking force to reduce IV
				apply_central_force(
					-forward * over_limit * 10.0
				)
		
		# Inside drift steering (front wheel rotates)
		if front_wheel and abs(turn_input) > 0.1:
			wheel_rotation_angle += turn_input * wheelie_rotation_speed * delta
			front_wheel.rotation.y = wheel_rotation_angle
		
		# Auto-balance
		var balance_angle = global_rotation.x
		if balance_angle < 0.2:
			apply_torque(Vector3(-wheelie_balance_force, 0, 0))
		elif balance_angle > 0.6:
			apply_torque(Vector3(wheelie_balance_force * 0.5, 0, 0))
		
		# Auto stop if not accelerating
		if speed_input < 0.1 and wheelie_timer > 3.0:
			start_wheelie_exit()
		
		wheelie_timer += delta
		
	# EXITING WHEELIE - IV decays exponentially
	elif is_exiting_wheelie:
		exit_speed_scale *= wheelie_exit_speed_multiplier
		
		# Only IV decays, EV stays constant
		if iv_speed > max_speed:
			var target_iv = iv_speed * exit_speed_scale
			var slowdown_force = iv_speed - target_iv
			apply_central_force(
				-forward * slowdown_force * 10.0
			)
			iv_speed = target_iv
		
		gravity_scale = 1.0
		
		# Exit complete when IV reaches base speed
		if iv_speed <= max_speed or exit_speed_scale < 0.1:
			is_exiting_wheelie = false
			exit_speed_scale = 1.0
			iv_speed = max_speed
		
		# Can accelerate during exit
		if speed_input != 0 and iv_speed < max_speed:
			apply_central_force(
				forward * speed_input * acceleration
			)
		
		# Reset wheel
		if front_wheel and wheel_rotation_angle != 0:
			wheel_rotation_angle = 0
			front_wheel.rotation.y = 0
	
	else:
		# Normal driving (no wheelie)
		gravity_scale = 1.0
		
		# Normal IV acceleration
		if speed_input != 0 and iv_speed < max_speed:
			apply_central_force(
				forward * speed_input * acceleration
			)
		
		# IV capped at max_speed (30)
		if iv_speed > max_speed:
			var over_limit = iv_speed - max_speed
			apply_central_force(
				-forward * over_limit * 10.0
			)
			iv_speed = max_speed
		
		# Reset wheel
		if front_wheel and wheel_rotation_angle != 0:
			wheel_rotation_angle = 0
			front_wheel.rotation.y = 0
	
	# Friction (only affects IV, not EV)
	var sideways = linear_velocity - forward * linear_velocity.dot(forward)
	apply_central_force(
		-sideways * friction
	)
	
	# Steering
	if is_wheelie:
		if abs(turn_input) > 0.1:
			rotate_y(
				-turn_input * steering * delta * 0.3
			)
	else:
		if linear_velocity.length() > turn_stop_limit:
			rotate_y(
				-turn_input * steering * delta
			)


func start_wheelie():
	if is_wheelie or is_exiting_wheelie:
		return
	
	print("🏍️ WHEELIE START!")  # Debug
	
	is_wheelie = true
	wheelie_timer = 0.0
	wheelie_active_time = 0.0
	gravity_scale = wheelie_gravity_scale
	wheelie_animation_playing = false  # Reset so animation plays
	
	# Play MACH WHEELIE animation
	if robo and robo.has_method("play_wheelie"):
		robo.play_wheelie(true)
	
	# Pop-up effect
	apply_central_force(Vector3.UP * 50.0)


func start_wheelie_exit():
	if not is_wheelie:
		return
	
	print("Wheelie stopped")  # Debug
	
	is_wheelie = false
	is_exiting_wheelie = true
	exit_speed_scale = 1.0
	gravity_scale = 1.0
	wheelie_animation_playing = false  # Reset for next time
	
	# Stop wheelie animation - ONLY call once!
	if robo and robo.has_method("play_wheelie"):
		robo.play_wheelie(false)
	
	# Reset wheel
	if front_wheel:
		wheel_rotation_angle = 0
		front_wheel.rotation.y = 0


# Add EV from mushrooms, boost pads, etc.
func add_ev_boost(amount: float):
	ev_speed += amount
	# Cap EV so total doesn't exceed wheelie_ev_max
	if is_wheelie and (iv_speed + ev_speed) > wheelie_ev_max:
		ev_speed = wheelie_ev_max - iv_speed
	elif not is_wheelie and (iv_speed + ev_speed) > max_speed:
		ev_speed = max_speed - iv_speed


# Remove EV (when boost runs out)
func remove_ev_boost(amount: float):
	ev_speed -= amount
	if ev_speed < 0:
		ev_speed = 0


# Called by robo when wheelie animation completes
func on_wheelie_animation_complete():
	if is_wheelie:
		start_wheelie_exit()


# Race start sequence - plays the intro animation
func play_race_start_sequence():
	print("🏁 Race about to start!")
	
	# Play starting sound effect
	if race_start_sound:
		race_start_sound.play()
	
	jg.is_race_about_to_start = true


# Called by JG/robo when the race start animation finishes
func _on_race_start_animation_finished():
	print("🏁 Race start animation finished!")
	
	# Start race music
	if race_music:
		race_music.play()
	
	# Race begins!
	is_race_about_to_start = false
	print("🏁 GO! Race started!")


# Alternative: Connect to AnimationPlayer's animation_finished signal
func _on_anim_animation_finished(anim_name: String):
	if anim_name == "race_start":
		_on_race_start_animation_finished()


# Call this when race is over
func end_race():
	is_race_about_to_start = true  # Reset for next race
	if race_music:
		race_music.stop()
	if race_start_sound:
		race_start_sound.stop()
