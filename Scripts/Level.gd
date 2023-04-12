class_name Level
extends Node3D

@export var chtitle_ui_scn : PackedScene = preload("res://Scenes/UIs/chapter_title_UI.tscn")
@export var debug_ui_on_start := false

var chapter_id : int :
	get:
		return get_meta("chapter_id", -1)
var chapter_sub_idx : int :
	get:
		return get_meta("chapter_sub_idx", -1)
var chapter_title : String :
	get:
		return ProjectSettings.get_setting("levels/ch_name_%d" % chapter_id, "")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	for kid in get_children():
		if Globals.world_env == null and kid is WorldEnvironment:
			Globals.world_env = kid
	
	if chapter_id >= 0 and chapter_sub_idx == 0:
		var chtitle_ui : Control = chtitle_ui_scn.instantiate()
		
		add_child(chtitle_ui)
		
		if not chtitle_ui.failed:
			await chtitle_ui.fx_done
		
		chtitle_ui.queue_free()
	
	Globals.level = self
