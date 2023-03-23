class_name NPC
extends CharacterBody3D

signal dialogue_started
signal dialogue_done
signal learned(k,v)

@export_group("Character")
@export var npc_name := "Gigio"
@export var npc_portrait := preload("res://icon.png")

@export_group("Dialogue")
@export var dialogue_file = preload("res://Dialogue/diag_blank.dialogue")
@export var dialogue_skippable := true

@onready var dialog_ui : DialogUI = %dialogUI
@onready var memory = %Memory
@onready var interactable : Interactable = %Interactable

var interact_enabled : bool :
	set(val):
		interactable.enabled = val

func _ready():
	add_to_group("ACTORS")
	dialog_ui.setup(dialogue_file, npc_name, npc_portrait, dialogue_skippable)
	
	memory.learned.connect(
		func (k, v):
			# Repeat learned signal
			Globals.log_msg("New NPC %s fact: [%s | %s]" % [name, k, v])
			_on_memory_learned(k,v)
			learned.emit(k,v)
	)

func _on_interacted():
	_predialogue()
	dialog_ui.visible = true
	
func _on_dialog_done():
	dialogue_done.emit()
	_dialogue_done()

func memorize(key: String, data : Variant = null):
	memory.set_value(key, data)

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
