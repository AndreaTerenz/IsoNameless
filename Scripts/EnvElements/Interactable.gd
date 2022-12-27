class_name Interactable
extends Area3D

enum INTERACT_MODE {
	NORMAL,
	ONESHOT_DISABLE,
	ONESHOT_FREE
}

signal interacted_with

@export
var mode : INTERACT_MODE = INTERACT_MODE.NORMAL
@export
var start_enabled := true

var player_entered := false

func _ready():
	set_enabled(start_enabled)
	
	if not Globals.player:
		await Globals.player_set
		
	body_entered.connect(
		func (body):
			player_entered = (body == Globals.player)
	)
	body_exited.connect(
		func (body):
			player_entered = not (body == Globals.player)
	)

func interact():
	interacted_with.emit()
	match mode:
		INTERACT_MODE.NORMAL:
			pass
		INTERACT_MODE.ONESHOT_DISABLE:
			set_enabled(false)
		INTERACT_MODE.ONESHOT_FREE:
			queue_free()

func set_enabled(e):
	monitoring = e
	monitorable = e
