extends Node3D

@export var mach_bike: Node3D
@export var the_state_machine: Node

var is_race_about_to_start
var is_wong_way
var is_fallen_down

func start_the_frickon_shit():
	if is_race_about_to_start:
		the_state_machine.race_startin()

func wong_shit():
	if is_wong_way:
		the_state_machine.wong_wae()
	elif is_wong_way == false:
		the_state_machine.wong_stah()

func dihed_meow_waaaaahhhh():
	if is_fallen_down:
		the_state_machine.fall()
	elif is_fallen_down == false:
		the_state_machine.fall_stah()

func race_started_buh():
	is_race_about_to_start = false
	mach_bike._on_race_start_animation_finished()

func next_lap():
	the_state_machine.next_lap()
