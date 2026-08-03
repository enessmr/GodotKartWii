extends Node

@export var anim_tree: AnimationTree
@export var jg: Node3D
@export var wong: AudioStreamPlayer
@export var rescue: AudioStreamPlayer
@export var anim2: AnimationPlayer

@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/StateMachine/playback")

#func _process(_delta):
#	if jg.is_race_about_to_start:
#		await get_tree().create_timer(2.0).timeout
#		state_machine.travel("coming_down_to_your_house_countdown")
#		await get_tree().create_timer(5.0)
#		anim2.play("hoppin_dih_dih_dih_dih")
#		state_machine.travel("countdown")
#	elif jg.is_wong_way:
#		state_machine.travel("wong_way_lahser")
#		wong.play()
#	elif jg.is_fallen_down:
#		state_machine.travel("picking_u_up")
#		rescue.play()

func race_startin():
	await get_tree().create_timer(2.0).timeout
	state_machine.travel("coming_down_to_your_house_countdown")
	anim2.play("hoppin_dih_dih_dih_dih")
	state_machine.travel("countdown")
	await get_tree().create_timer(3.85).timeout
	anim2.play_backwards("coming_down_to_your_house_countdown")
	jg.race_started_buh()

func wong_wae():
	anim2.play("coming_down_to_your_house_reverse")
	state_machine.travel("wong_way_lahser")
	wong.play()

func wong_stah():
	anim2.play_backwards("coming_down_to_your_house_reverse")
	wong.stop()
	await get_tree().create_timer(1.2).timeout
	state_machine.stop()

func fall():
	state_machine.travel("picking_u_up")
	rescue.play()

func fall_stah():
	rescue.stop()

func next_lap():
	anim2.play("coming_down_to_your_house_countdown")
	state_machine.travel("next_lap")
