@tool
extends TextureRect

## Use for special actions outside of InputMap. Format is keyboard icon|mouse icon|joypad icon.
const CUSTOM_ACTIONS = {
	"move": "WSAD||LeftStick"
}

enum {KEYBOARD, MOUSE, JOYPAD}
enum JoypadMode {ADAPTIVE, FORCE_KEYBOARD, FORCE_JOYPAD}
enum FitMode {NONE, MATCH_WIDTH, MATCH_HEIGHT}
enum JoypadModel {AUTO, XBOX, XBOX360, DS3, DS4, DUAL_SENSE, JOY_CON}

const MODEL_MAP = {
	JoypadModel.XBOX: "Xbox",
	JoypadModel.XBOX360: "Xbox360",
	JoypadModel.DS3: "DS3",
	JoypadModel.DS4: "DS4",
	JoypadModel.DUAL_SENSE: "DualSense",
	JoypadModel.JOY_CON: "JoyCon",
}

## Action name from InputMap or CUSTOM_ACTIONS.
@export var action_name: StringName = &"":
	set(action):
		action_name = action
		refresh()

## Whether a joypad button should be used or keyboard/mouse.
@export var joypad_mode: JoypadMode = JoypadMode.ADAPTIVE:
	set(mode):
		joypad_mode = mode
		set_process_input(mode == JoypadMode.ADAPTIVE)
		refresh()

## Controller model for the displayed icon.
@export var joypad_model: JoypadModel = JoypadModel.AUTO:
	set(model):
		joypad_model = model
		if model == JoypadModel.AUTO:
			if not Input.joy_connection_changed.is_connected(on_joy_connection_changed):
				Input.joy_connection_changed.connect(on_joy_connection_changed)
		else:
			if Input.joy_connection_changed.is_connected(on_joy_connection_changed):
				Input.joy_connection_changed.disconnect(on_joy_connection_changed)
		
		_cached_model = ""
		refresh()

## If using keyboard/mouse icon, this makes mouse preferred if available.
@export var favor_mouse: bool = true:
	set(favor):
		favor_mouse = favor
		refresh()

## Use to control the size of icon inside a container.
@export var fit_mode: FitMode = FitMode.MATCH_WIDTH:
	set(mode):
		fit_mode = mode
		refresh()

## Set whether the icon can refresh while invisible
@export var ignore_visibility: bool = false:
	set(new_value):
		ignore_visibility = new_value
		refresh()
		
var _visible : bool :
	get:
		return ignore_visibility or is_visible_in_tree()

var _base_path: String
var _use_joypad: bool
var _pending_refresh: bool
var _cached_model: String

func _init():
	add_to_group(&"action_icons")
	texture = load("res://addons/ActionIcon/Keyboard/Blank.png")
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _ready() -> void:
	_base_path = scene_file_path.get_base_dir()
	if _base_path.is_empty():
		_base_path = "res://addons/ActionIcon/"
	
	_use_joypad = not Input.get_connected_joypads().is_empty()
	
	if joypad_model == JoypadModel.AUTO:
		Input.joy_connection_changed.connect(on_joy_connection_changed)
	
	set_process_input(joypad_mode == JoypadMode.ADAPTIVE)
	
	if action_name == &"":
		return
	
	var action_exists = InputMap.has_action(action_name) or action_name in CUSTOM_ACTIONS
	
	assert(action_exists or Engine.is_editor_hint(), 
		"Action \"%s\" does not exist in the InputMap nor CUSTOM_ACTIONS." % action_name)
	
	refresh()

## Forces icon refresh. Useful when you change controls.
func refresh():
	if _pending_refresh:
		return
	
	_pending_refresh = true
	_refresh.call_deferred()

func _refresh():
	if Engine.is_editor_hint() or not _visible:
		return
	
	_pending_refresh = false
	
	var is_joypad := false
	if joypad_mode == JoypadMode.FORCE_JOYPAD or (joypad_mode == JoypadMode.ADAPTIVE and _use_joypad):
		is_joypad = true
	
	if action_name in CUSTOM_ACTIONS:
		var image_list: PackedStringArray = CUSTOM_ACTIONS[action_name].split("|")
		assert(image_list.size() >= 3, "Need more |")
		
		if is_joypad and not image_list[JOYPAD].is_empty():
			var model := get_joypad_model(0) + "/"
			texture = get_image(JOYPAD, model + image_list[JOYPAD])
		elif not is_joypad:
			if (favor_mouse or image_list[KEYBOARD].is_empty()) and not image_list[MOUSE].is_empty():
				texture = get_image(MOUSE, image_list[MOUSE])
			elif image_list[KEYBOARD]:
				texture = get_image(KEYBOARD, image_list[KEYBOARD])
		return
	
	var keyboard := -1
	var mouse := -1
	var joypad := -1
	var joypad_axis := -1
	var joypad_axis_value: float
	var joypad_id: int
	
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and keyboard == -1:
			keyboard = event.keycode
		elif event is InputEventMouseButton and mouse == -1:
			mouse = event.button_index
		elif event is InputEventJoypadButton and joypad == -1:
			joypad = event.button_index
			joypad_id = event.device
		elif event is InputEventJoypadMotion and joypad_axis == -1:
			joypad_axis = event.axis
			joypad_axis_value = event.axis_value
			joypad_id = event.device
	
	if is_joypad and joypad >= 0:
		texture = get_joypad(joypad, joypad_id)
	elif is_joypad and joypad_axis >= 0:
		texture = get_joypad_axis(joypad_axis, joypad_axis_value, joypad_id)
	elif not is_joypad:
		if mouse >= 0 and (favor_mouse or keyboard < 0):
			texture = get_mouse(mouse)
		elif keyboard >= 0:
			texture = get_keyboard(keyboard)
	
	if not texture and action_name != &"":
		push_error(str("No icon for action: ", action_name))
	else:
		var s = texture.get_size()
		if fit_mode != FitMode.NONE:
			custom_minimum_size = Vector2()
			
		if fit_mode == FitMode.MATCH_WIDTH:
			custom_minimum_size.x = s.y
		elif fit_mode == FitMode.MATCH_HEIGHT:
			custom_minimum_size.y = s.x

func get_keyboard(key: int) -> Texture:
	var str = ""
	
	if KEY_0 <= key and key <= KEY_9:
		# Convert key to ASCII character
		str = char(key)
	elif KEY_A <= key and key <= KEY_Z:
		# Convert key to ASCII character and make uppercase
		str = char(key)#.to_upper()
	elif KEY_F1 <= key and key <= KEY_F12:
		# Convert key to Function button name
		str = "F%d" % [key - KEY_F1 + 1]
	else:
		var other_keys := {
			KEY_LEFT: "Left",
			KEY_RIGHT: "Right",
			KEY_UP: "Up",
			KEY_DOWN: "Down",
			KEY_QUOTELEFT: "Tilde",
			KEY_MINUS: "Minus",
			KEY_PLUS: "Plus",
			KEY_BACKSPACE: "Backspace",
			KEY_BRACELEFT: "BracketLeft",
			KEY_BRACERIGHT: "BracketRight",
			KEY_SEMICOLON: "Semicolon",
			KEY_QUOTEDBL: "Quote",
			KEY_BACKSLASH: "BackSlash",
			KEY_ENTER: "Enter",
			KEY_ESCAPE: "Esc",
			KEY_LESS: "LT",
			KEY_GREATER: "GT",
			KEY_QUESTION: "Question",
			KEY_CTRL: "Ctrl",
			KEY_SHIFT: "Shift",
			KEY_ALT: "Alt",
			KEY_SPACE: "Space",
			KEY_META: "Win",
			KEY_CAPSLOCK: "CapsLock",
			KEY_TAB: "Tab",
			KEY_PRINT: "PrintScrn",
			KEY_INSERT: "Insert",
			KEY_HOME: "Home",
			KEY_PAGEUP: "PageUp",
			KEY_DELETE: "Delete",
			KEY_END: "End",
			KEY_PAGEDOWN: "PageDown",
		}
		
		str = other_keys.get(key, "")
	
	if str != "":
		return get_image(KEYBOARD, str)
	
	return null

func get_joypad_model(device: int) -> String:
	if not _cached_model.is_empty():
		return _cached_model
	
	var model := "Xbox"
	if joypad_model == JoypadModel.AUTO:
		var device_name := Input.get_joy_name(maxi(device, 0))
		if device_name.contains("Xbox 360"):
			model = "Xbox360"
		elif device_name.contains("PS3"):
			model = "DS3"
		elif device_name.contains("PS4"):
			model = "DS4"
		elif device_name.contains("PS5"):
			model = "DualSense"
		elif device_name.contains("Joy-Con") or device_name.contains("Joy Con"):
			model = "JoyCon"
	else:
		model = MODEL_MAP[joypad_model]
	
	_cached_model = model
	return model

func get_joypad(button: int, device: int) -> Texture:
	var model := get_joypad_model(device) + "/"
	
	match button:
		JOY_BUTTON_A:
			return get_image(JOYPAD, model + "A")
		JOY_BUTTON_B:
			return get_image(JOYPAD, model + "B")
		JOY_BUTTON_X:
			return get_image(JOYPAD, model + "X")
		JOY_BUTTON_Y:
			return get_image(JOYPAD, model + "Y")
		JOY_BUTTON_LEFT_SHOULDER:
			return get_image(JOYPAD, model + "LB")
		JOY_BUTTON_RIGHT_SHOULDER:
			return get_image(JOYPAD, model + "RB")
		JOY_BUTTON_LEFT_STICK:
			return get_image(JOYPAD, model + "L")
		JOY_BUTTON_RIGHT_STICK:
			return get_image(JOYPAD, model + "R")
		JOY_BUTTON_GUIDE:
			return get_image(JOYPAD, model + "Select")
		JOY_BUTTON_START:
			return get_image(JOYPAD, model + "Start")
		JOY_BUTTON_DPAD_UP:
			return get_image(JOYPAD, model + "DPadUp")
		JOY_BUTTON_DPAD_DOWN:
			return get_image(JOYPAD, model + "DPadDown")
		JOY_BUTTON_DPAD_LEFT:
			return get_image(JOYPAD, model + "DPadLeft")
		JOY_BUTTON_DPAD_RIGHT:
			return get_image(JOYPAD, model + "DPadRight")
	return null

func get_joypad_axis(axis: int, value: float, device: int) -> Texture:
	var model := get_joypad_model(device) + "/"
	
	match axis:
		JOY_AXIS_LEFT_X:
			if value < 0:
				return get_image(JOYPAD, model + "LeftStickLeft")
			elif value > 0:
				return get_image(JOYPAD, model + "LeftStickRight")
			else:
				return get_image(JOYPAD, model + "LeftStick")
		JOY_AXIS_LEFT_Y:
			if value < 0:
				return get_image(JOYPAD, model + "LeftStickUp")
			elif value > 0:
				return get_image(JOYPAD, model + "LeftStickDown")
			else:
				return get_image(JOYPAD, model + "LeftStick")
		JOY_AXIS_RIGHT_X:
			if value < 0:
				return get_image(JOYPAD, model + "RightStickLeft")
			elif value > 0:
				return get_image(JOYPAD, model + "RightStickRight")
			else:
				return get_image(JOYPAD, model + "RightStick")
		JOY_AXIS_RIGHT_Y:
			if value < 0:
				return get_image(JOYPAD, model + "RightStickUp")
			elif value > 0:
				return get_image(JOYPAD, model + "RightStickDown")
			else:
				return get_image(JOYPAD, model + "RightStick")
		JOY_AXIS_TRIGGER_LEFT:
			return get_image(JOYPAD, model + "LT")
		JOY_AXIS_TRIGGER_RIGHT:
			return get_image(JOYPAD, model + "RT")
	return null

func get_mouse(button: int) -> Texture:
	match button:
		MOUSE_BUTTON_LEFT:
			return get_image(MOUSE, "Left")
		MOUSE_BUTTON_RIGHT:
			return get_image(MOUSE, "Right")
		MOUSE_BUTTON_MIDDLE:
			return get_image(MOUSE, "Middle")
		MOUSE_BUTTON_WHEEL_DOWN:
			return get_image(MOUSE, "WheelDown")
		MOUSE_BUTTON_WHEEL_LEFT:
			return get_image(MOUSE, "WheelLeft")
		MOUSE_BUTTON_WHEEL_RIGHT:
			return get_image(MOUSE, "WheelRight")
		MOUSE_BUTTON_WHEEL_UP:
			return get_image(MOUSE, "WheelUp")
	return null

func get_image(type: int, image: String) -> Texture2D:
	match type:
		KEYBOARD:
			return load(_base_path + "/Keyboard/" + image + ".png") as Texture
		MOUSE:
			return load(_base_path + "/Mouse/" + image + ".png") as Texture
		JOYPAD:
			return load(_base_path + "/Joypad/" + image + ".png") as Texture
	return null

func on_joy_connection_changed(device: int, connected: bool):
	if connected:
		_cached_model = ""
		refresh()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	
	if _use_joypad and (event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion):
		_use_joypad = false
		refresh()
	elif not _use_joypad and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		_use_joypad = true
		refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree() and _pending_refresh:
			refresh()
