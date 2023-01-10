class_name NPC
extends CharacterBody3D

signal dialogue_started
signal dialogue_done

@export
var npc_name := "Gigio"
@export
var npc_portrait := preload("res://icon.png")
@export
var dialogue_file = preload("res://Dialogue/diag_test_1.dialogue")

@onready
var dialog_ui := %dialogUI

func _ready():
	dialog_ui.setup(dialogue_file, npc_name, npc_portrait)

func _on_interacted():
	dialog_ui.visible = true
	
func _on_dialog_done():
	dialogue_done.emit()
