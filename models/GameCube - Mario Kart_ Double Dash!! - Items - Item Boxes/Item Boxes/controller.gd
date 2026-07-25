# just the 3d behavior. the rest happens in the itemstuff scene

extends Area3D

@export var labelgroup: Node3D
@export var collisionshape3d: CollisionShape3D
@export var mesh: MeshInstance3D
var collected = false

func _ready():
	add_to_group("itemboxdouble")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("kart") and not collected:
		collected = true
		if body.has_method("collect_itemboxdouble"):
			body.collect_itemboxdouble()
			print("itembox collected (double!!): ", name)
		disable_item()
		# todo: probably add gecko code support
		await get_tree().create_timer(3.0).timeout
		reset_box()

func disable_item():
	collisionshape3d.disabled = true
	mesh.visible = false
	labelgroup.visible = false

func reset_box():
	collisionshape3d.disabled = false
	mesh.visible = true
	labelgroup.visible = true
	collected = false
