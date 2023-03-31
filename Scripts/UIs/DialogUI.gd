class_name DialogUI
extends Control

signal done
signal interrupted

@export var dialogue_file = preload("res://Dialogue/diag_blank.dialogue")
@export var skippable := true

@onready var diag_line = %DialogueLabel
@onready var opts_cont = %OptionsCont
@onready var name_lbl = %NameLbl
@onready var portrait = %Portrait
@onready var close_btn = %CloseBtn

var target_npc : NPC = null
var next_id := ""
var responses : Array = []
var stop := false
var typing := false
var line_update_timer := Timer.new()

func _ready():
	visible = false

	visibility_changed.connect(
		func ():
			if visible:
				next_id = ""
				#dialog_started.emit()
				update_line()
	)
	
	add_child.call_deferred(line_update_timer)
	await line_update_timer.ready
	line_update_timer.one_shot = true
	line_update_timer.timeout.connect(
		func ():
			update_line()
	)

func setup(_npc : NPC):
	target_npc = _npc
	
	skippable = _npc.dialogue_skippable
	close_btn.visible = skippable
	name_lbl.text = _npc.npc_name
	dialogue_file = _npc.dialogue_file
	portrait.texture = _npc.npc_portrait
	
	reset()

func reset():
	typing = false
	line_update_timer.stop()
	responses = []
	next_id = ""
	visible = false
	opts_cont.visible = false

func update_line():
	var from : String = "start" if next_id == "" else next_id
	var current_line : DialogueLine = \
		await DialogueManager.get_next_dialogue_line(dialogue_file, from, [target_npc, Globals, Globals.player])
	
	if current_line == null:
		visible = false
		done.emit()
		return
		
	next_id = current_line.next_id
	responses = current_line.responses
	stop = (len(responses) > 0)
	
	diag_line.dialogue_line = current_line
	diag_line.type_out()
	typing = true

func _on_close_pressed():
	line_update_timer.stop()
	interrupted.emit()
	visible = false

func _on_label_finished_typing():
	if len(responses) > 0:
		opts_cont.show_options(responses)
	else:
		# Will trigger update to next line on timeout,
		# unless interrupted
		line_update_timer.start(2.0)
		
	typing = false


func _on_options_cont_selected(opt_id):
	next_id = responses[opt_id].next_id
	update_line()
