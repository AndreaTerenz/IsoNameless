extends Node

signal player_set(p)

var player : Player = null
var debug_ui : Control = null
var start_time := 0.

func _ready():
	start_time = Time.get_unix_time_from_system()

func set_player(p: Player):
	if not player:
		player = p
		player_set.emit(p)

func new_debug_msg(s: String, mode: DebugUI.DEBUG_MSG_MODE = DebugUI.DEBUG_MSG_MODE.LOG):
	if debug_ui:
		debug_ui.new_msg(s, mode)
