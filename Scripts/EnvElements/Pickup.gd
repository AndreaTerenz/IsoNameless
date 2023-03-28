class_name Pickup
extends Interactable

@export var item : InventoryItem
@export_range(1, 32) var amount := 1

func _ready():
	super._ready()
	
	mode = INTERACT_MODE.ONESHOT_FREE
	self._text = "Take"
