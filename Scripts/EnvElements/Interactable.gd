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
var tooltip_text : String = "Interact"
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
var _text : String : 
	set(t):
		_text = t
		if tooltip and tooltip.is_inside_tree():
			tooltip.text = _text
		#
var player_inside : bool = false:
	set(pi):
		player_inside = pi
		tooltip.visible = pi
		if player_inside:
			_on_player_entered()
			player_entered.emit()
		else:
			_on_player_exited()
			player_exited.emit()

func _ready():
	enabled = start_enabled
	
	await Globals.await_player()
		
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
	
	_text = tooltip_text
	
	if tooltip_origin:
		tooltip = tooltip_scene.instantiate()
		tooltip_origin.add_child.call_deferred(tooltip)
		
		await tooltip.ready
		
		tooltip.visible = false
		tooltip.text = _text

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
