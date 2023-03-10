class_name NestedUI
extends Control

@export
var toggle_action := "quit"
@export
var force_toggle_action := false
@export
var mouse_filter_rect_color := Color(0., 0., 0., 0.)

var previous : NestedUI = null
var next_shown := false
var mouse_filter_rect : ColorRect = null

func _ready():
	Globals.quit_on_esc = false
	
	# Create mouse filtering ColorRect
	mouse_filter_rect = await Utils.make_background_colorrect(self)
	mouse_filter_rect.visible = false
	mouse_filter_rect.color = mouse_filter_rect_color
	mouse_filter_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if previous == null:
		_on_hide()
		
func _unhandled_input(event):
	if Input.is_action_just_pressed(toggle_action) and not next_shown:
		if previous != null:
			go_back()
		else:
			toggle()
	get_viewport().set_input_as_handled()
		
func go_back():
	_on_hide()
	
	if previous:
		previous._on_next_hid()
		queue_free()

func show_next(next_ui_scn : PackedScene):
	var next_ui = next_ui_scn.instantiate() as NestedUI
	if next_ui:
		next_ui.previous = self
		next_ui.top_level = true
		
		if force_toggle_action and not next_ui.force_toggle_action:
			next_ui.toggle_action = toggle_action
			next_ui.force_toggle_action = true
		
		add_child.call_deferred(next_ui)
		next_ui._on_show()
		_on_next_shown()
	else:
		push_error("The provided next_ui scene is not of NestedUI type")

func toggle():
	if visible:
		_on_hide()
	else:
		_on_show()

func _on_hide():
	hide()
		
	if previous == null:
		Globals.toggle_screen_blur(false)
	
func _on_show():
	show()
		
	if previous == null:
		Globals.toggle_screen_blur(true)

func _on_next_shown():
	next_shown = true
	mouse_filter_rect.visible = true
	
	if mouse_filter_rect_color.a == 0.:
		modulate.a = .5

func _on_next_hid():
	next_shown = false
	mouse_filter_rect.visible = false
	
	if mouse_filter_rect_color.a == 0.:
		modulate.a = 1.
