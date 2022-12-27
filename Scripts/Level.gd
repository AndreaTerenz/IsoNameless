extends Node3D

@export var debug_ui_scn : PackedScene = preload("res://Scenes/debug_ui.tscn")

var debug_ui : Control = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	if debug_ui_scn:
		debug_ui = debug_ui_scn.instantiate()
		add_child(debug_ui)
		
		Globals.debug_ui = debug_ui
		Globals.new_debug_msg("Level started")
	
func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _process(delta):
	var p := Globals.player
	var p_y := p.global_position.y
	var self_y := global_position.y
	if self_y - p_y > 20.:
		get_tree().reload_current_scene()
