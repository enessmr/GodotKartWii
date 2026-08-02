extends Node

@export var anim_tree: AnimationTree
@export var jg: Node3D
@export var wong: AudioStreamPlayer
@export var rescue: AudioStreamPlayer

@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/StateMachine/playback")

func _process(_delta):
	if jg.is_race_about_to_start:
		state_machine.travel("coming_down_to_your_house_countdown")
		await get_tree().create_timer(1.0)
		state_machine.travel("countdown")
	elif jg.is_wong_way:
		state_machine.travel("wong_way_lahser")
		wong.play()
	elif jg.is_fallen_down:
		state_machine.travel("picking_u_up")
		rescue.play()
