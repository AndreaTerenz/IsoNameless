class_name OptionsSettingContainer
extends SettingContainer

@export
var option_btn : OptionButton

func _ready():
	super._ready()
	
	option_btn.item_selected.connect(
		func (_id):
			ui_to_setting()
	)

func _setting_to_ui(value):
	var idx = option_btn.get_item_index(value)
	option_btn.select(idx)

func _ui_value():
	return option_btn.get_selected_id()
