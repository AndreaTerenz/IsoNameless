class_name DebugUI
extends Control

enum DEBUG_MSG_MODE {
	LOG, #Default
	WARN,
	ERROR
}

const debug_msg_colors := {
	DEBUG_MSG_MODE.LOG: Color.WHITE,
	DEBUG_MSG_MODE.WARN: Color.YELLOW,
	DEBUG_MSG_MODE.ERROR: Color.TOMATO,
}

@onready
var db_messages_cont := %"DB messages"

func _input(event):
	if Input.is_action_just_pressed("toggle_debug_ui"):
		visible = not visible

func new_msg(s: String, mode: DEBUG_MSG_MODE):
	var lbl := Label.new()
	lbl.text = "-- [%.1f] -- \n%s" % [Time.get_unix_time_from_system() - Globals.start_time, s]
	lbl.modulate = debug_msg_colors[mode]
	db_messages_cont.add_child(lbl)
	#Ensures last message is never clipped
	$"ScrollContainer".scroll_vertical += lbl.get_rect().size.y*2
