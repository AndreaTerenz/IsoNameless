class_name Trigger
extends Area3D

signal player_inside_changed(pi)
signal enabled_changed(e)

enum MODE {
	NORMAL,
	ONESHOT_ENTER,
	ONESHOT_EXIT,
}

@export var mode := MODE.NORMAL

@onready var debug_mesh = $DebugMesh

var player_inside := false :
	set(pi):
		if pi == player_inside:
			return
			
		player_inside = pi
		player_inside_changed.emit(player_inside)
var enabled := true :
	set(e):
		if e == enabled:
			return
			
		enabled = e
		enabled_changed.emit(e)
		player_inside = false
		monitorable = enabled
		monitoring = enabled

func _ready():
	add_to_group(Globals.TRIGGERS_GROUP)
	debug_mesh.visible = false

	body_entered.connect(
		func (body):
			if enabled and body == Globals.player:
				player_inside = true
				if mode == MODE.ONESHOT_ENTER:
					enabled = false
	)
	
	body_exited.connect(
		func (body):
			if enabled and body == Globals.player:
				player_inside = false
				if mode == MODE.ONESHOT_EXIT:
					enabled = false
	)
