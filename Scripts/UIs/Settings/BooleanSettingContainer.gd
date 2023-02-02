class_name BooleanSettingContainer
extends SettingContainer

@export
var check_btn : CheckButton

func _ready():
	super._ready()
	
	check_btn.pressed.connect(ui_to_setting)

func _setting_to_ui(value):
	check_btn.set_pressed_no_signal(value)

func _ui_value():
	return check_btn.button_pressed
