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
var world_env : WorldEnvironment = null
var start_time := -1.
var log_queue := []
var log_timestamp := true
var blur_rect : ColorRect = null

var started:
	get:
		return start_time >= 0.

var quit_on_esc := true

func _ready():
	enforce_display_size()
	
	blur_rect = await Utils.make_background_colorrect()
	blur_rect.visible = false
	blur_rect.material = preload("res://Materials/screen_blur_mat.tres")
	
func enforce_display_size():
	var size := DisplayServer.window_get_size()
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	var expected_size := Vector2i(int(w), int(h))
	
	if size != expected_size:
		DisplayServer.window_set_size(Vector2i(int(w),int(h)))
	
func _input(_event):
	if Input.is_action_just_pressed("quit") and quit_on_esc:
		get_tree().quit()
		
func toggle_screen_blur(vis : bool):
	blur_rect.visible = vis
		
func start_level():
	start_time = Time.get_unix_time_from_system()
	
	for obj in log_queue:
		log_msg(obj)
	log_queue.clear()
	
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
	elif not started:
		log_queue.append(obj)
	
	return obj
	
func set_cursor_mode(mode: CURSOR_MODE):
	var cursor_img = ""
	var center_cursor := -1.
	
	match mode:
		CURSOR_MODE.NORMAL:
			cursor_img = "cursor_arrow"
			center_cursor = 0.
		CURSOR_MODE.COMBAT:
			cursor_img = "cursor_combat"
			center_cursor = 1.
		_:
			push_warning("Invalid cursor mode (%s)" % mode)
			return
			
	var img = load("res://Assets/UI/%s.png" % cursor_img)
	
	DisplayServer.cursor_set_custom_image(img, DisplayServer.CURSOR_ARROW, center_cursor * img.get_size()/2.)
	
func set_env_property(prop_name: String, value: Variant):
	if not world_env:
		push_error("World environment object not set")
		return null
		
	if not (prop_name in world_env.environment):
		push_error("Tried to set non-existant environment property '%s'" % prop_name)
		return null
		
	world_env.environment.set(prop_name, value)
	return value
