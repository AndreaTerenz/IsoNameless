class_name SettingContainer
extends BoxContainer

@export
var setting_category := ""
@export
var setting_name := ""
@export
var reset_btn : Button
@export
var default_btn : Button

var current_setting_value : Variant :
	get:
		return GSManager.get_setting(setting_category, setting_name).current_value

func _ready():
	reset_btn.pressed.connect(
		func ():
			reset_btn.disabled = true
			GSManager.reset_value(setting_category, setting_name)
			_setting_to_ui(current_setting_value)
	)
	
	reset_btn.disabled = true
		
	#TODO: connect reset-to-default button
	
	GSManager.reset.connect(
		func ():
			_setting_to_ui(current_setting_value)
			reset_btn.disabled = true
	)
	
	GSManager.loaded_defaults.connect(
		func ():
			if _ui_value() != current_setting_value:
				_setting_to_ui(current_setting_value)
				reset_btn.disabled = true
	)
	
	GSManager.applied.connect(
		func ():
			reset_btn.disabled = true
	)
	
	_setting_to_ui(current_setting_value)

func set_value(val):
	GSManager.set_value(setting_category, setting_name, val)
	reset_btn.disabled = false

func ui_to_setting():
	set_value(_ui_value())

# VIRTUAL - update UI state from setting value
func _setting_to_ui(value):
	pass

# VIRTUAL - return UI state
func _ui_value():
	return null
