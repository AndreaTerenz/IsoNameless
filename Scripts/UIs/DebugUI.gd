class_name DebugUI
extends Control

const MAX_DEBUG_MSG = 48

@onready var db_messages_cont := %"DB messages"

func _input(_event):
	if Input.is_action_just_pressed("toggle_debug_ui"):
		visible = not visible

func new_msg(s: String, color: Color):
	var lbl := Label.new()
	lbl.text = s
	lbl.modulate = color
	
	db_messages_cont.add_child(lbl)
	
	if db_messages_cont.get_child_count() >= MAX_DEBUG_MSG:
		var kid = db_messages_cont.get_child(0)
		db_messages_cont.remove_child(kid)
	
	#Ensures last message is never clipped
	$"ScrollContainer".scroll_vertical += lbl.get_rect().size.y*2
	
	return lbl.text

func clear_all():
	var kids = db_messages_cont.get_children()
	for kid in kids:
		kid.queue_free()
