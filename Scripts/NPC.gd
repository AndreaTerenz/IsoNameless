class_name NPC
extends CharacterBody3D

signal dialogue_started
signal dialogue_done
signal learned(k,v)
signal interactable_changed(i)
signal portrait_changed(p)

@export_group("Character")
@export var npc_name := "Gigio"
@export var npc_portrait := preload("res://icon.png") :
	set(p):
		if p == npc_portrait:
			return
		
		npc_portrait = p
		portrait_changed.emit(p)
@export var interact_enabled := true :
	set(val):
		if val == interact_enabled:
			return
			
		if not is_inside_tree():
			await ready
			
		interactable.enabled = val
		map_decal.visible = val
		
		interactable_changed.emit(val)

@export_group("Dialogue")
@export var dialogue_file = preload("res://Dialogue/diag_blank.dialogue")
@export var dialogue_skippable := true
@export var dialogue_start_id = "start"

@onready var memory : Memory = %Memory
@onready var interactable : Interactable = %Interactable
@onready var map_decal = %MapDecal
@onready var mover : NPCMover = %Mover

var default_layers : int
var default_mask : int

func _ready():
	default_layers = collision_layer
	default_mask = collision_mask
	add_to_group(Globals.ACTORS_GROUP)
	
	memory.learned.connect(
		func (k, v):
			# Repeat learned signal
			Globals.log_msg("New NPC %s fact: [%s | %s]" % [name, k, v])
			_on_memory_learned(k,v)
			learned.emit(k,v)
	)

func _on_interacted():
	_predialogue()
	
func _on_dialog_done():
	dialogue_done.emit()
	_dialogue_done()

func memorize(key: String, data : Variant = null):
	memory.set_value(key, data)
	
func itempath_to_item(path: String, err_msg : String = ""):
	if not path.begins_with(Globals.DEFAULT_ITEMS_DIR):
		path = Globals.DEFAULT_ITEMS_DIR.path_join(path)
		
	if not ResourceLoader.exists(path):
		if err_msg != "":
			push_error("Tried to give player a non-existant item! ('%s')" % path)
		return null
		
	return load(path)
	
func give(item_path: String, amount := 1):
	var item: InventoryItem = itempath_to_item(item_path,
		"Tried to give player a non-existant item! ('%s')" % item_path)
	if item != null:
		Globals.player.receive_item(item, amount)
	
func take(item_path: String, amount := 1):
	var item: InventoryItem = itempath_to_item(item_path,
		"Tried to take from player a non-existant item! ('%s')" % item_path)
	if item != null:
		Globals.player.give_item(item, amount)
	
func query_player_inv(item_path: String, amount := -1):
	var item: InventoryItem = itempath_to_item(item_path,
		"Tried to take from player a non-existant item! ('%s')" % item_path)
	if item != null:
		return Globals.player.query_inventory(item, amount) 
	return false
		
func change_dialogue_file(path: String):
	if not ResourceLoader.exists(path) or not path.ends_with(".dialogue"):
		push_error("Invalid path for dialogue file!")
		return
		
	dialogue_file = load(path)

func _on_dialog_started():
	dialogue_started.emit()
	_dialogue_started()
	
func _process(delta):
	velocity = mover.update_velocity(delta)
	
	if velocity != Vector3.ZERO:
		move_and_slide()
	
# VIRTUAL
func _predialogue():
	pass

func _dialogue_started():
	pass
	
func _dialogue_done():
	pass
	
func _on_memory_learned(k,v):
	pass
