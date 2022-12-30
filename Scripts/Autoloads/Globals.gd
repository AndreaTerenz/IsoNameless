extends Node

signal player_set(p)

var player : Player = null
var debug_ui : DebugUI = null
var start_time := 0.

func _ready():
	start_time = Time.get_unix_time_from_system()

func set_player(p: Player):
	if not player:
		player = p
		player_set.emit(p)

func log_msg(s: String, mode: DebugUI.DEBUG_MSG_MODE = DebugUI.DEBUG_MSG_MODE.LOG, print_stdout := true):
	if debug_ui:
		var to_print : String = debug_ui.new_msg(s, mode)
		
		if print_stdout:
			match mode:
				DebugUI.DEBUG_MSG_MODE.LOG:
					pass
				DebugUI.DEBUG_MSG_MODE.WARN:
					to_print = "[WARN] %s" % to_print
				DebugUI.DEBUG_MSG_MODE.ERROR:
					to_print = "[ERROR] %s" % to_print
			
			print(to_print)
