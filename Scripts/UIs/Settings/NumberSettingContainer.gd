class_name RangeSettingContainer
extends SettingContainer

@export
var range_node : Range

func _ready():
	super._ready()
	
	range_node.value_changed.connect(
		func (_value):
			_ui_to_setting()
	)

# VIRTUAL - update setting value from UI state
func _ui_to_setting():
	set_value(range_node.value)

# VIRTUAL - update UI state from setting value
func _setting_to_ui(value):
	range_node.set_value_no_signal(value)
