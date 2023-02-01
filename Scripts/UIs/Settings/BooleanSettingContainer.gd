class_name BooleanSettingContainer
extends SettingContainer

@export
var check_btn : CheckButton

func _ready():
	super._ready()
	
	check_btn.pressed.connect(_ui_to_setting)

# VIRTUAL - update setting value from UI state
func _ui_to_setting():
	set_value(check_btn.button_pressed)

# VIRTUAL - update UI state from setting value
func _setting_to_ui(value):
	check_btn.set_pressed_no_signal(value)
