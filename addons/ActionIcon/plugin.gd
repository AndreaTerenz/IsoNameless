@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("ActionIcon", "TextureRect",
					preload("res://addons/ActionIcon/ActionIcon.gd"),
					preload("res://addons/ActionIcon/icon.png"))

func _exit_tree():
	remove_custom_type("ActionIcon")
