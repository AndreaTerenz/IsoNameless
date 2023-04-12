extends Node

signal player_set(p)
signal level_started
signal paused_changed(p)

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

const ACTORS_GROUP := "Actors"
const TRIGGERS_GROUP := "Triggers"

const DEFAULT_ITEMS_DIR := "res://Items"
const MIN_DB_LEVEL := DEBUG_MSG_MODE.LOG

var debug_ui_scn : PackedScene = preload("res://Scenes/debug_ui.tscn")
var debug_ui : DebugUI = null
var world_env : WorldEnvironment = null
var start_time := -1.
var log_queue := []
var log_timestamp := true
var blur_rect : ColorRect = null
var memory := Memory.new()

var player : Player :
	set(p):
		if not player:
			player = p
			player_set.emit(p)
var player_pos : Vector3 :
	get:
		if not player:
			return Vector3.ZERO
		return player.global_position
var level : Level = null :
	set(l):
		level = l
		
		debug_ui.visible = level.debug_ui_on_start
		
		log_msg("Started")
		level_started.emit()
var paused := false :
	set(p):
		if paused == p:
			return
		
		paused = p
		
		if paused == get_tree().paused:
			return
		
		if paused:
			log_msg("Paused")
			await toggle_screen_blur(true)
			get_tree().paused = true
		else:
			log_msg("Resumed")
			get_tree().paused = false
			toggle_screen_blur(false)
			
		paused_changed.emit(p)
var started:
	get:
		return level != null
		
func _ready():
	start_time = Time.get_ticks_msec()
	enforce_screen_size()
	
	blur_rect = await Utils.make_background_colorrect()
	blur_rect.material = preload("res://Materials/screen_blur_mat.tres")
	
	add_child(memory)
	memory.learned.connect(
		func (k,v):
			log_msg("New Global fact: [%s | %s]" % [k,v])
	)
	
	debug_ui = debug_ui_scn.instantiate()
	add_child(debug_ui)
	debug_ui.visible = false
	
	var r = get_tree().root
	
	for kid in r.get_children():
		if kid is Level:
			debug_ui.visible = kid.debug_ui_on_start
			break
	
	for tmp in log_queue:
		_print_to_db_ui(tmp[0], tmp[1], tmp[2])
	log_queue.clear()
	
func enforce_screen_size():
	var w_size := DisplayServer.window_get_size()
	var s_size := DisplayServer.screen_get_size()
	
	if w_size != s_size:
		DisplayServer.window_set_size(s_size)
		
func _notification(what):
	if level != null:
		if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
			Globals.log_msg("Focus in")
		elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			Globals.log_msg("Focus out")
			paused = true
		
func toggle_screen_blur(vis : bool):
	if not blur_rect:
		push_warning("Tried setting screen blur before blur_rect was initialized")
		return
		
	#blur_rect.visible = vis
	var alpha = 1.0 if vis else 0.0
	var mat := (blur_rect.material as ShaderMaterial)
	
	var t := get_tree().create_tween()
	t.tween_property(mat, "shader_parameter/alpha", alpha, .1).from_current()
	await t.finished
	
func restart_level():
	debug_ui.clear_all()
	Globals.log_msg("Restarting...")
	start_time = Time.get_ticks_msec() 
	get_tree().reload_current_scene()
		
func start_log_seq():
	log_msg("")
	log_timestamp = false
	
func end_log_seq():
	log_timestamp = true

func log_msg(obj, mode: DEBUG_MSG_MODE = DEBUG_MSG_MODE.LOG, print_stdout := true):
	var s := str(obj)
	var time := (Time.get_ticks_msec() - start_time) / 1000.
	var mode_name = debug_msg_names.get(mode, "")
	
	if mode_name != "":
		mode_name = "%s | " % mode_name
		
	if log_timestamp:
		s = "-- [%s%.3f] -- \n%s" % [mode_name.to_upper(), time, s]
	
	if mode >= MIN_DB_LEVEL:
		if debug_ui:
			_print_to_db_ui(s, debug_msg_colors[mode], print_stdout)
		else:
			log_queue.append([s, debug_msg_colors[mode], print_stdout])
	
	return obj

func _print_to_db_ui(s, col, ps):
	debug_ui.new_msg(s, col)
	
	if ps:
		print(s)

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
	
func global_memory_get(key: String, default : Variant = null):
	return memory.get_value(key, default)

func global_memorize(key: String, value):
	memory.set_value(key, value)

func await_player():
	if not player:
		await player_set

func await_level():
	if not level:
		await level_started
