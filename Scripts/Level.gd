class_name Level
extends Node3D

signal playable_changed(p)

@export var chtitle_ui_scn : PackedScene = preload("res://Scenes/UIs/chapter_title_UI.tscn")
@export var debug_ui_on_start := false

var level_name : String :
	get:
		return get_meta("level_name", "")
var level_description : String :
	get:
		return get_meta("description", "")
var chapter_id : int :
	get:
		return get_meta("chapter_id", -1)
var chapter_sub_idx : int :
	get:
		return get_meta("chapter_sub_idx", -1)
var chapter_title : String :
	get:
		return ProjectSettings.get_setting("levels/ch_name_%d" % chapter_id, "")
		
var is_playable := false :
	set (p):
		if p == is_playable:
			return
			
		is_playable = p
		playable_changed.emit(is_playable)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	
	for kid in get_children():
		if Globals.world_env == null and kid is WorldEnvironment:
			Globals.world_env = kid
	
	Globals.level = self
	
	if chapter_title != "" and chapter_sub_idx == 0:
		var chtitle_ui : Control = chtitle_ui_scn.instantiate()
		
		add_child(chtitle_ui)
		
		await chtitle_ui.fx_done
	else:
		if chapter_id < 0 and chapter_sub_idx >= 0:
			push_warning("Level has a chapter index (%d) but no assigned chapter!" % chapter_sub_idx)
		elif chapter_id >= 0 and chapter_sub_idx < 0:
			push_warning("Level has an assigned chapter ('%s') but no chapter index!" % chapter_title)
	
	is_playable = true
