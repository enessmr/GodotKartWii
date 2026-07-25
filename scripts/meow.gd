extends Control
# Enrique my 67 😂😂😂

func _ready():
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/mariokartwii.tscn")
