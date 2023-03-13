extends Node3D

@export var debug_ui_scn : PackedScene = preload("res://Scenes/debug_ui.tscn")
@export var settings_ui_scn : PackedScene = preload("res://Scenes/UIs/settings_ui.tscn")
@export var debug_ui_on_start := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	if debug_ui_scn:
		var debug_ui : Control = debug_ui_scn.instantiate()
		add_child(debug_ui)
		
		Globals.debug_ui = debug_ui
		debug_ui.visible = debug_ui_on_start
	
	if settings_ui_scn and false:
		var settings_ui : Control = settings_ui_scn.instantiate()
		Globals.log_msg("Settings loaded from Level.gd")
		add_child(settings_ui)
		
	rotate_y(TAU/8.)
	
	for kid in get_children():
		if kid is WorldEnvironment:
			Globals.world_env = kid
			break
	
	Globals.start_level()

func _process(_delta):
	var p := Globals.player
	var p_y := p.global_position.y
	var self_y := global_position.y
	if self_y - p_y > 20.:
		get_tree().reload_current_scene()
