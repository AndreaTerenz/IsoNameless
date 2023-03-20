class_name DialogUI
extends Control

signal dialog_started
signal dialog_done

@export
var dialogue_file = preload("res://Dialogue/diag_test_ncr.dialogue")
@export
var skippable := true

@onready
var diag_line = %DialogueLabel
@onready
var opts_cont = %OptionsCont
@onready
var name_lbl = %NameLbl
@onready
var portrait = %Portrait
@onready
var close_btn = %CloseBtn

var parent_npc : NPC = null
var next_id := ""
var responses : Array = []
var stop := false

func setup(diag_f : DialogueResource, n: String, propic: Texture, skip := true, par : NPC = get_parent()):
	visible = false
	
	parent_npc = par
	self.dialog_done.connect(parent_npc._on_dialog_done)
	
	skippable = skip
	close_btn.visible = skippable
	name_lbl.text = n
	dialogue_file = diag_f
	portrait.texture = propic

	visibility_changed.connect(
		func ():
			if visible:
				next_id = ""
				dialog_started.emit()
				update_line()
	)
	
	diag_line.finished_typing.connect(
		func ():
			if len(responses) > 0:
				opts_cont.show_options(responses)
			else:
				await get_tree().create_timer(2.0).timeout
				update_line()
	)
	
	opts_cont.selected.connect(
		func (opt_id: int):
			next_id = responses[opt_id].next_id
			update_line()
	)

func update_line():
	var from : String = "start" if next_id == "" else next_id
	var current_line : DialogueLine = \
		await DialogueManager.get_next_dialogue_line(dialogue_file, from, [parent_npc, Globals, Globals.player])
	
	if current_line == null:
		_hide()
		return
		
	next_id = current_line.next_id
	responses = current_line.responses
	stop = (len(responses) > 0)
	
	diag_line.dialogue_line = current_line
	diag_line.type_out()

func _hide():
	visible = false
	dialog_done.emit()

func _on_close_pressed():
	_hide()
