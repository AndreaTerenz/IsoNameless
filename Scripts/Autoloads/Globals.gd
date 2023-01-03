extends Node

signal player_set(p)

var player : Player = null
var debug_ui : DebugUI = null
var start_time := 0.

func _ready():
	start_time = Time.get_unix_time_from_system()
	
func _input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func set_player(p: Player):
	if not player:
		player = p
		player_set.emit(p)

func log_msg(obj, mode: DebugUI.DEBUG_MSG_MODE = DebugUI.DEBUG_MSG_MODE.LOG, print_stdout := true):
	if debug_ui:
		var s := str(obj)
		var to_print : String = debug_ui.new_msg(s, mode)
		
		if print_stdout and to_print != "":
			print(to_print)
