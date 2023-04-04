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
@export var show := false

@onready var debug_mesh = $DebugMesh

var player_inside := false :
	set(pi):
		if pi == player_inside:
			return
			
		player_inside = pi
		player_inside_changed.emit(player_inside)
		
		if pi:
			_on_player_entered()
		else:
			_on_player_left()
		
		if (player_inside and mode == MODE.ONESHOT_ENTER) or \
			(not player_inside and mode == MODE.ONESHOT_EXIT):
			enabled = false
var enabled := true :
	set(e):
		if e == enabled:
			return
			
		enabled = e
		enabled_changed.emit(e)
		
		player_inside = false
		set_deferred("monitorable", enabled)
		set_deferred("monitoring", enabled)
		
		if e:
			_on_enabled()
		else:
			_on_disabled()

func _ready():
	add_to_group(Globals.TRIGGERS_GROUP)
	debug_mesh.visible = show

	body_entered.connect(
		func (body):
			if body == Globals.player:
				player_inside = true
	)
	
	body_exited.connect(
		func (body):
			if body == Globals.player:
				player_inside = false
	)

###### VIRTUAL

func _on_player_entered():
	pass

func _on_player_left():
	pass

func _on_enabled():
	pass
	
func _on_disabled():
	pass
