@warning_ignore_start(
	"inference_on_variant",
	"unused_parameter"
)
extends CharacterBody3D

#=============================================
# SGT64 - SITTING PLAYER CONTROLLER WITH TTS/MIC
# Godot 4.7-stable
# Stationary character - voice input/output only
# Head bone follows camera
#=============================================


#=============================================
# EXPORTS
#=============================================

@export_category("References")
@export var anim: AnimationPlayer
@export var robo: Node3D
@export var head: Node3D
@export var FirstPersonCamera: Camera3D
@export var skeleton: Skeleton3D


@export_category("Camera")
@export var mouse_sensitivity: float = 0.002
@export var camera_limit: float = 80.0


@export_category("Voice Settings")
@export var voice_mode: VoiceMode = VoiceMode.TTS
@export var tts_language: String = "en"


enum VoiceMode {
	TTS,
	MIC
}


#=============================================
# STATE
#=============================================

var pitch: float = 0.0
var yaw: float = 0.0

var is_speaking: bool = false
var is_recording: bool = false


#=============================================
# ANIMATION
#=============================================

const BLEND := 0.12
const SITTING_ANIM := "sitting_RELAX"

var _anim_current: String = ""


#=============================================
# HEAD BONE
#=============================================

var head_bone_id: int = -1


#=============================================
# TTS
#=============================================

var tts_voice_id: String = ""


#=============================================
# MICROPHONE
#=============================================

var mic_audio: AudioStreamMicrophone
var mic_player: AudioStreamPlayer

const MIC_BUS := "MicBus"

var mic_bus_index: int = -1


#=============================================
# GLOBAL
#=============================================

var global_self: Node


#=============================================
# INIT
#=============================================

func _ready() -> void:
	if not is_multiplayer_authority():
		return

	_setup_local_player()
	_initialize_animation()
	_initialize_head_bone()
	_initialize_voice_system()



func _setup_local_player() -> void:

	if has_node("/root/Global_self"):
		global_self = get_node("/root/Global_self")


	if is_instance_valid(FirstPersonCamera):
		FirstPersonCamera.current = true
	else:
		push_warning("FirstPersonCamera missing")


	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



#=============================================
# ANIMATION
#=============================================

func _initialize_animation() -> void:

	if not is_instance_valid(anim):

		var players := find_children(
			"*",
			"AnimationPlayer",
			true,
			false
		)

		if players.size() > 0:
			anim = players[0]


	if not is_instance_valid(anim):
		push_warning("No AnimationPlayer found")
		return


	if anim.has_animation(SITTING_ANIM):

		anim.play(
			SITTING_ANIM,
			BLEND
		)

		_anim_current = SITTING_ANIM

	else:

		push_warning(
			"Animation not found: " + SITTING_ANIM
		)



#=============================================
# HEAD BONE SETUP
#=============================================

func _initialize_head_bone() -> void:

	if not is_instance_valid(skeleton):
		skeleton = _find_skeleton()


	if not is_instance_valid(skeleton):
		push_warning("No Skeleton3D found")
		return


	var possible_names := [
		"Head",
		"head",
		"Neck",
		"neck",
		"spine_3",
		"Spine_3"
	]


	for bone_name in possible_names:

		head_bone_id = skeleton.find_bone(bone_name)

		if head_bone_id != -1:
			break


	if head_bone_id == -1:

		push_warning(
			"Could not find head bone"
		)



func _find_skeleton() -> Skeleton3D:

	if is_instance_valid(robo):

		for child in robo.get_children():

			if child is Skeleton3D:
				return child



	for child in get_children():

		if child is Skeleton3D:
			return child


	return null
	

#=============================================
# VOICE INITIALIZATION
#=============================================

func _initialize_voice_system() -> void:

	match voice_mode:

		VoiceMode.TTS:
			_initialize_tts()

		VoiceMode.MIC:
			_initialize_mic()



#=============================================
# TTS
#=============================================

func _initialize_tts() -> void:

	var voices := DisplayServer.tts_get_voices_for_language(
		tts_language
	)


	if voices.is_empty():

		voices = DisplayServer.tts_get_voices_for_language(
			"en"
		)


	if voices.is_empty():

		push_error(
			"No TTS voices available"
		)

		return


	tts_voice_id = voices[0]


	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_ENDED,
		Callable(self, "_on_tts_finished")
	)


	print(
		"TTS initialized: ",
		tts_voice_id
	)



func _speak_tts(text: String) -> void:

	if text.is_empty():
		return


	if tts_voice_id.is_empty():

		push_warning(
			"TTS voice not initialized"
		)

		return


	DisplayServer.tts_stop()


	DisplayServer.tts_speak(
		text,
		tts_voice_id,
		50,
		1.0,
		1.0,
		0,
		true
	)


	is_speaking = true


	if is_multiplayer_authority():

		_sync_speaking.rpc(
			true
		)



func stop_speaking_tts() -> void:

	DisplayServer.tts_stop()

	is_speaking = false


	if is_multiplayer_authority():

		_sync_speaking.rpc(
			false
		)



func _on_tts_finished(
		utterance_id: int
) -> void:

	is_speaking = false


	if is_multiplayer_authority():

		_sync_speaking.rpc(
			false
		)



#=============================================
# MICROPHONE
#=============================================

func _initialize_mic() -> void:

	mic_audio = AudioStreamMicrophone.new()


	mic_player = AudioStreamPlayer.new()

	mic_player.stream = mic_audio

	mic_player.bus = MIC_BUS


	add_child(
		mic_player
	)


	_create_mic_bus()


	print(
		"Microphone initialized"
	)



func _create_mic_bus() -> void:

	for i in AudioServer.get_bus_count():

		if AudioServer.get_bus_name(i) == MIC_BUS:

			mic_bus_index = i
			return



	mic_bus_index = AudioServer.get_bus_count()


	AudioServer.add_bus(
		mic_bus_index
	)


	AudioServer.set_bus_name(
		mic_bus_index,
		MIC_BUS
	)



func start_mic_recording() -> void:

	if not is_instance_valid(mic_player):

		push_warning(
			"Microphone player missing"
		)

		return


	if is_recording:
		return


	mic_player.play()


	is_recording = true
	is_speaking = true


	print(
		"Microphone started"
	)


	if is_multiplayer_authority():

		_sync_speaking.rpc(
			true
		)



func stop_mic_recording() -> void:

	if not is_instance_valid(mic_player):
		return


	if not is_recording:
		return


	mic_player.stop()


	is_recording = false
	is_speaking = false


	print(
		"Microphone stopped"
	)


	if is_multiplayer_authority():

		_sync_speaking.rpc(
			false
		)



func toggle_mic() -> void:

	if is_recording:

		stop_mic_recording()

	else:

		start_mic_recording()



#=============================================
# VOICE API
#=============================================

func speak_text(text: String) -> void:

	if text.is_empty():
		return


	match voice_mode:

		VoiceMode.TTS:

			_speak_tts(
				text
			)


		VoiceMode.MIC:

			start_mic_recording()



func start_voice_input() -> void:

	match voice_mode:

		VoiceMode.TTS:
			pass


		VoiceMode.MIC:

			start_mic_recording()



func stop_voice_input() -> void:

	match voice_mode:

		VoiceMode.TTS:

			stop_speaking_tts()


		VoiceMode.MIC:

			stop_mic_recording()



func toggle_voice_mode() -> void:

	stop_voice_input()


	if voice_mode == VoiceMode.TTS:

		voice_mode = VoiceMode.MIC

		_initialize_mic()


	else:

		voice_mode = VoiceMode.TTS

		_initialize_tts()



func is_voice_active() -> bool:

	return is_speaking or is_recording

#=============================================
# TEXT BOX INTEGRATION
#=============================================

func on_text_changed(new_text: String) -> void:

	if voice_mode == VoiceMode.MIC:
		return


	if new_text.is_empty():

		stop_speaking_tts()

	else:

		speak_text(
			new_text
		)



func on_text_submitted(text: String) -> void:

	if text.is_empty():
		return


	if voice_mode == VoiceMode.TTS:

		speak_text(
			text
		)

	else:

		if is_multiplayer_authority():

			_sync_text_message.rpc(
				text
			)



func on_text_box_focus_entered() -> void:

	if is_recording:

		stop_mic_recording()



#=============================================
# CAMERA / HEAD CONTROL
#=============================================

func _physics_process(_delta: float) -> void:

	if not is_multiplayer_authority():
		return


	_update_head_bone_rotation()

	_apply_camera_rotation()



func _update_head_bone_rotation() -> void:

	if not is_instance_valid(skeleton):
		return


	if head_bone_id == -1:
		return


	var limited_pitch := clamp(
		pitch,
		deg_to_rad(-60),
		deg_to_rad(60)
	)


	var yaw_rotation := Quaternion(
		Vector3.UP,
		yaw
	)


	var pitch_rotation := Quaternion(
		Vector3.RIGHT,
		limited_pitch
	)


	skeleton.set_bone_pose_rotation(
		head_bone_id,
		yaw_rotation * pitch_rotation
	)



func _apply_camera_rotation() -> void:

	if not is_instance_valid(head):
		return


	head.rotation_order = EULER_ORDER_YXZ


	head.rotation.y = yaw

	head.rotation.x = pitch



#=============================================
# INPUT
#=============================================

func _unhandled_input(event: InputEvent) -> void:

	if not is_multiplayer_authority():
		return



	if global_self and global_self.has_method(
		"is_input_blocked"
	):

		if global_self.is_input_blocked():
			return



	if event is InputEventMouseMotion:

		yaw -= event.relative.x * mouse_sensitivity

		pitch -= event.relative.y * mouse_sensitivity


		pitch = clamp(
			pitch,
			deg_to_rad(-camera_limit),
			deg_to_rad(camera_limit)
		)



#=============================================
# MULTIPLAYER
#=============================================

@rpc(
	"any_peer",
	"call_remote"
)

func _sync_speaking(
	speaking: bool
) -> void:

	if is_multiplayer_authority():
		return


	is_speaking = speaking



@rpc(
	"any_peer",
	"call_remote"
)

func _sync_text_message(
	text: String
) -> void:

	print(
		"Message received: ",
		text
	)



#=============================================
# CLEANUP
#=============================================

func _exit_tree() -> void:

	if is_speaking:

		DisplayServer.tts_stop()



	if is_recording and is_instance_valid(mic_player):

		mic_player.stop()

		is_recording = false
