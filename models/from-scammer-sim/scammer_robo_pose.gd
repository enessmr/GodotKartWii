extends Node3D

var char_selected
var anim_played = false
var racing = false  # THIS NEEDS TO STAY
var is_wheelie = false
var is_playing_end_animation := false
var vehiclesel = false

@export var anim: AnimationPlayer
@export var mach_bike: Node3D
@export var vehicle: RigidBody3D
@export var wheelie_duration := 10.0

@export var wheelie_animation_speed := 1.2
@export var wheelie_trick_animation := "mach_wheelie"
@export var wheelie_end_animation := "wheelie_bike_mach_end_fr"

func _process(delta: float) -> void:
	if char_selected == true and anim_played == false and racing == false:
		anim.play("mario_yeah")
		await get_tree().create_timer(1.2).timeout
		anim_played = true
	elif anim_played == false and racing == false:
		anim.play("mario")
	
	if racing == true:
		if is_wheelie:
			# Wheelie is active - animation is playing
			pass
		elif not is_playing_end_animation:
			# Normal riding
			anim.play("mach_bike_fr")
			mach_bike.show()
		elif not is_playing_end_animation and not vehiclesel:
			# Normal riding
			anim.play("mach_bike_fr")
			mach_bike.show()
	elif vehiclesel == true:
		mach_bike.show()
		anim.play("mach_bike_fr")


func play_wheelie(active: bool):
	is_wheelie = active
	
	if active:
		# Start wheelie
		is_playing_end_animation = false
		if anim.has_animation(wheelie_trick_animation):
			anim.play(wheelie_trick_animation)
			anim.speed_scale = wheelie_animation_speed
		else:
			anim.play("mach_bike_fr")
			anim.speed_scale = 1.5
		
		show_wheelie_effects()
		mach_bike.rotation.x = -0.15
		
	else:
		# End wheelie - play end animation
		is_playing_end_animation = true
		
		if anim.has_animation(wheelie_end_animation):
			anim.play_backwards(wheelie_end_animation)
			anim.speed_scale = 1.0
			if not anim.animation_finished.is_connected(_on_end_animation_finished):
				anim.animation_finished.connect(_on_end_animation_finished)
		else:
			# Fallback if no end animation
			anim.play("mach_bike_fr")
			is_playing_end_animation = false
		
		hide_wheelie_effects()
		mach_bike.rotation.x = 0.0


func _on_end_animation_finished(anim_name: String):
	if anim_name == wheelie_end_animation:
		is_playing_end_animation = false
		anim.animation_finished.disconnect(_on_end_animation_finished)
		# Go back to normal riding
		if racing:
			anim.play("mach_bike_fr")


func _on_animation_finished(anim_name: String):
	if anim_name == wheelie_trick_animation and is_wheelie:
		if vehicle and vehicle.has_method("on_wheelie_animation_complete"):
			vehicle.on_wheelie_animation_complete()


@export var wheelie_particles: GPUParticles3D
@export var wheelie_sparks: GPUParticles3D

func show_wheelie_effects():
	if wheelie_particles:
		wheelie_particles.emitting = true
	if wheelie_sparks:
		wheelie_sparks.emitting = true


func hide_wheelie_effects():
	if wheelie_particles:
		wheelie_particles.emitting = false
	if wheelie_sparks:
		wheelie_sparks.emitting = false


func on_wheelie_boost_peak():
	pass


func _ready():
	if anim.has_signal("animation_finished"):
		anim.animation_finished.connect(_on_animation_finished)
	
	if not racing:
		if mach_bike:
			mach_bike.hide()


func start_race():
	racing = true
	is_wheelie = false
	anim_played = true
	mach_bike.show()
	anim.play("mach_bike_fr")
