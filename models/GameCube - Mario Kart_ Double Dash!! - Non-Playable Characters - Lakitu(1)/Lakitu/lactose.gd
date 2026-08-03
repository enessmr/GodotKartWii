extends Node

@export var lapboard_sc: Node3D
@export var reverse_model: MeshInstance3D
@export var jg_alarm: MeshInstance3D
@export var jg_hair: MeshInstance3D
@export var jg_flag: MeshInstance3D
@export var jg_light: MeshInstance3D
@export var im_lactose_intolerant_rod: MeshInstance3D
@export var lactose_ahh: AudioStreamPlayer
@export var ohothotahothothothotahothothothothothot: AudioStreamPlayer
@export var ahoohohoooooo: AudioStreamPlayer
@export var skull_emoji: AudioStreamPlayer
@export var animationplayer: AnimationPlayer
@export var signalplayer: AnimationPlayer
@export var re: Label
@export var wo: Label
@export var ne: Label
@export var go: Label
@export var vstt: AudioStreamPlayer

var lapcount


func _ready():
	animationplayer.play("tpose")
	vstt.play()
	
	await get_tree().create_timer(4.0982).timeout          # Wait 4.0982s
	re.show()
	
	await get_tree().create_timer(5.2345 - 4.0982).timeout # Wait 1.1363s
	re.hide()
	wo.show()
	
	await get_tree().create_timer(6.5435 - 5.2345).timeout # Wait 1.3090s
	wo.hide()
	ne.show()
	
	await get_tree().create_timer(7.7861 - 6.5435).timeout # Wait 1.2426s
	ne.hide()
	go.show()
	
	await get_tree().create_timer(1).timeout               # Wait 1s
	go.hide()


func wahoo():
	signalplayer.play("DOOTDOOTDOOOTduutduutduuuuuuuuuuuuhhhh")
	animationplayer.play("countdown")

func reverse():
	animationplayer.play("fahh_entrance")
	animationplayer.play("fuckyou")

func yahh():
	animationplayer.play("fahh_exit")

func lap2():
	if lapboard_sc and lapboard_sc.has_method("update_lap_display"):
		lapboard_sc.lapcount = lapcount
		lapboard_sc.update_lap_display()
	animationplayer.play("lap2baby")
	
func FINALLAP():
	animationplayer.play("lap3baby")
