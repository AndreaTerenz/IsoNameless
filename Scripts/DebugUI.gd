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

const debug_msg_names := {
	DEBUG_MSG_MODE.WARN: "Warn",
	DEBUG_MSG_MODE.ERROR: "Error",
}

const MAX_DEBUG_MSG = 48

@export var min_db_msg := DEBUG_MSG_MODE.LOG

@onready
var db_messages_cont := %"DB messages"

func _input(_event):
	if Input.is_action_just_pressed("toggle_debug_ui"):
		visible = not visible

func new_msg(s: String, mode: DEBUG_MSG_MODE):
	if mode < min_db_msg:
		return ""
	
	var lbl := Label.new()
	var time = Time.get_unix_time_from_system() - Globals.start_time
	
	if not debug_msg_names.has(mode):
		lbl.text = "-- [%.1f] -- \n%s" % [time, s]
	else:
		lbl.text = "-- [%s | %.1f] -- \n%s" % [debug_msg_names[mode].to_upper(), time, s]
		
	lbl.modulate = debug_msg_colors[mode]
	
	db_messages_cont.add_child(lbl)
	
	if db_messages_cont.get_child_count() >= MAX_DEBUG_MSG:
		var kid = db_messages_cont.get_child(0)
		db_messages_cont.remove_child(kid)
	
	#Ensures last message is never clipped
	$"ScrollContainer".scroll_vertical += lbl.get_rect().size.y*2
	
	return lbl.text
