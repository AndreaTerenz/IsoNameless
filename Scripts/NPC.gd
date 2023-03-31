class_name NPC
extends CharacterBody3D

signal dialogue_started
signal dialogue_done
signal learned(k,v)
signal interactable_changed(i)

@export_group("Character")
@export var npc_name := "Gigio"
@export var npc_portrait := preload("res://icon.png")
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

@onready var memory = %Memory
@onready var interactable : Interactable = %Interactable
@onready var map_decal = %MapDecal
		
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
	
func give_player(item_path: String, amount := 1):
	if not item_path.begins_with(Globals.DEFAULT_ITEMS_DIR):
		item_path = Globals.DEFAULT_ITEMS_DIR.path_join(item_path)
		
	if not ResourceLoader.exists(item_path):
		push_error("Tried to give player non-existant item! ('%s')" % item_path)
		return
		
	var item: InventoryItem = load(item_path)
	Globals.player.receive_item(item, amount)

func _on_dialog_started():
	dialogue_started.emit()
	_dialogue_started()
	
# VIRTUAL
func _predialogue():
	pass

func _dialogue_started():
	pass
	
func _dialogue_done():
	pass
	
func _on_memory_learned(k,v):
	pass
