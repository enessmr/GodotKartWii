extends Node3D

@export var m1: MeshInstance3D  # Drag m1 into this slot
var lapcount: int = 0  # Gets set from external script

func update_lap_display():
	# Get kart and update lapcount from it
	var kart = get_tree().get_first_node_in_group("kart")
	if kart:
		lapcount = kart.lap_count + 1  # Add 1 here directly
	
	# Clamp lap between 2 and 9
	var lap = clamp(lapcount, 2, 9)
	
	# Determine material filename based on lap number
	var material_name = str(lap) + ".tres"
	if lap == 7:
		material_name = "THISISNOTTHEFUCKING67.tres"
	
	var material_path = "res://models/Wii - Mario Kart Wii - Miscellaneous - Lakitu/Lakitu/nummat/" + material_name
	var material = load(material_path)
	
	if material and m1:
		m1.mesh.surface_set_material(0, material)
