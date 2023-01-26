extends Node

signal player_set(p)
signal level_started

enum DEBUG_MSG_MODE {
	LOG, #Default
	WARN,
	ERROR
}

enum CURSOR_MODE {
	NORMAL,
	COMBAT
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

const MIN_DB_LEVEL := DEBUG_MSG_MODE.LOG

var player : Player = null
var debug_ui : DebugUI = null
var start_time := -1.

var log_timestamp := true

var started:
	get:
		return start_time >= 0.

func _ready():
	pass
	
func _input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
func start_level():
	start_time = Time.get_unix_time_from_system()
	Globals.log_msg("Level started")
	level_started.emit()

func set_player(p: Player):
	if not player:
		player = p
		player_set.emit(p)
		
func start_log_seq():
	log_msg("")
	log_timestamp = false
	
func end_log_seq():
	log_timestamp = true

func log_msg(obj, mode: DEBUG_MSG_MODE = DEBUG_MSG_MODE.LOG, print_stdout := true):
	if started and mode >= MIN_DB_LEVEL:
		var s := str(obj)
		var time = "%.3f" % (Time.get_unix_time_from_system() - Globals.start_time)
		var mode_name = debug_msg_names.get(mode, "")
		
		if mode_name != "":
			mode_name = "%s | " % mode_name
			
		if log_timestamp:
			s = "-- [%s%s] -- \n%s" % [mode_name.to_upper(), time, s]
			
		debug_ui.new_msg(s, debug_msg_colors[mode])
		
		if print_stdout:
			print(s)
	
	return obj
	
func set_cursor_mode(mode: CURSOR_MODE):
	var cursor_img = ""
	
	match mode:
		CURSOR_MODE.NORMAL:
			cursor_img = "cursor_arrow"
		CURSOR_MODE.COMBAT:
			cursor_img = "cursor_combat"
		_:
			push_warning("Invalid cursor mode (%s)" % mode)
			return
	
	DisplayServer.cursor_set_custom_image(load("res://Assets/UI/%s.png" % cursor_img))
