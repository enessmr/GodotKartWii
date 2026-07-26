extends Node3D

var char_selected
var anim_played = false
@export var anim: AnimationPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if char_selected == true and anim_played == false:
		anim.play("mario_yeah")
		await get_tree().create_timer(1.2).timeout
		anim_played = true
	elif anim_played == false:
		anim.play("mario")
