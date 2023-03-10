class_name Interactable
extends Area3D

enum INTERACT_MODE {
	MULTIPLE,
	ONESHOT_DISABLE,
	ONESHOT_FREE
}

signal interacted
signal player_entered
signal player_exited
signal enabled_changed(en)

@export
var tooltip_text := "Interact"
@export
var tooltip_origin : Node3D = null
@export
var mode : INTERACT_MODE = INTERACT_MODE.MULTIPLE
@export
var start_enabled := true

var tooltip_scene := preload("res://Scenes/actors/interact_tooltip.tscn")
var tooltip : Sprite3D = null
var enabled :
	get:
		return monitorable and monitoring
	set(e):
		monitoring = e
		monitorable = e
		enabled_changed.emit(e)
		
var interact_data:
	get:
		return get_interact_data()
		
var player_inside := false

func _ready():
	enabled = start_enabled
	
	if not Globals.player:
		await Globals.player_set
		
	body_entered.connect(
		func (body):
			if body == Globals.player:
				tooltip.visible = true
				player_inside = true
				_on_player_entered()
				player_entered.emit()
	)
	body_exited.connect(
		func (body):
			if body == Globals.player:
				tooltip.visible = false
				player_inside = false
				_on_player_exited()
				player_exited.emit()
	)
	
	if tooltip_origin:
		tooltip = tooltip_scene.instantiate()
		tooltip.visible = false
		tooltip.text = tooltip_text.trim_prefix(" ").trim_suffix(" ")
		tooltip_origin.add_child(tooltip)

func interact():
	if not enabled:
		return
		
	_on_interact()
	interacted.emit()
	
	match mode:
		INTERACT_MODE.MULTIPLE:
			pass
		INTERACT_MODE.ONESHOT_DISABLE:
			enabled = false
		INTERACT_MODE.ONESHOT_FREE:
			queue_free()
	
	return interact_data
	
# VIRTUAL
func _on_interact():
	pass
	
func _on_player_entered():
	pass

func _on_player_exited():
	pass

func get_interact_data():
	return null
