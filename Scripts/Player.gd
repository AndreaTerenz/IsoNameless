class_name Player
extends CharacterBody3D

@export_range(.01, 20., .005) var TOTAL_SPEED = 5. 
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Globals.set_player(self)

func _input(event):
	if event is InputEventMouseMotion:
		var viewport := get_viewport()
		var mouse_pos = viewport.get_mouse_position()
		var screen_center = viewport.get_visible_rect().size / 2.
		var delta : Vector2 = mouse_pos - screen_center
		
		rotation.y = -delta.angle() + TAU / 8.

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Every action is flipped......MMMMMMM
	var input_dir = Input.get_vector("right", "left", "backward", "forward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * H_SPEED
		velocity.z = direction.z * H_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, H_SPEED)
		velocity.z = move_toward(velocity.z, 0, H_SPEED)
	
	move_and_slide()
	
func rotate_with_mouse(event: InputEventMouseMotion, node: Node3D, sensitivity := .001):
	var tmp = -event.relative * sensitivity
	var event_rel : Vector2 = Vector2(rad_to_deg(tmp.x), rad_to_deg(tmp.y))
	var y_rot = event_rel.x

	node.rotate_y(y_rot)
