extends Node3D

var char_selected
var anim_played = false
var racing = false
@export var anim: AnimationPlayer
@export var mach_bike: Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if char_selected == true and anim_played == false and racing == false:
		anim.play("mario_yeah")
		await get_tree().create_timer(1.2).timeout
		anim_played = true
	elif anim_played == false and racing == false:
		anim.play("mario")
	if racing == true:
		anim.play("machbike")
		mach_bike.show()
