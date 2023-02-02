class_name RangeSettingContainer
extends SettingContainer

@export
var range_node : Range

func _ready():
	super._ready()
	
	range_node.value_changed.connect(
		func (_value):
			ui_to_setting()
	)

func _ui_value():
	return range_node.value

func _setting_to_ui(value):
	range_node.set_value_no_signal(value)
	
	if range_node is SpinBox:
		# Immense anger 
		range_node.get_line_edit().text = str(value)
