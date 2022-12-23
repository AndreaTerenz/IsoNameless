class_name Player
extends CharacterBody3D

enum MODES {
	# Move with WASD in local directions, rotate *whole player* with Q and E 
	TANK,
	# Move with WASD in absolute NSEW directions, rotate *body* with mouse
	HADES
}

@export_enum("Tank", "Hades") var MOVEMENT_MODE : int = MODES.TANK
# If true, W moves towards isometric forward (and so on)
# If false, W moves towards top of the screen (and so on)
@export var ISOMETRIC_WASD := false

@export_range(.01, 20., .005) var TOTAL_SPEED = 5. 
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01,  2., .005) var H_DECELERATION := .5
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5
@export_range(.01, 20., .005) var ROT_SENSITIVITY := 4.

@onready
var body := %Body

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Globals.set_player(self)

func _input(event):
	if MOVEMENT_MODE == MODES.HADES:
		if event is InputEventMouseMotion:
			var viewport := get_viewport()
			var mouse_pos = viewport.get_mouse_position()
			var screen_center = viewport.get_visible_rect().size / 2.
			var delta : Vector2 = mouse_pos - screen_center
			
			body.rotation.y = -delta.angle() + TAU / 8.

func _physics_process(delta):
	if MOVEMENT_MODE == MODES.TANK:
		var rot_dir := 0.
		if Input.is_action_pressed("rot_left"):
			rot_dir = 1.
		elif Input.is_action_pressed("rot_right"):
			rot_dir = -1.
		
		rotate_y((TAU/8.) * rot_dir * ROT_SENSITIVITY * delta)
		
	var on_floor := is_on_floor()
	var v_vel := velocity.y
	var h_vel : Vector2 = Utils.vec_sub(velocity, "xz")

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("right", "left", "backward", "forward")
	var direction = (transform.basis * Utils.vec_sub(input_dir, "x0y")).normalized()
	
	if direction:
		h_vel = Utils.vec_sub(direction, "xz") * H_SPEED
	else:
		h_vel = h_vel.lerp(Vector2.ZERO, H_DECELERATION * float(on_floor))
		
	# Add the gravity.
	if not on_floor:
		v_vel -= gravity * delta
	# Handle Jump.
	elif Input.is_action_just_pressed("jump"):
		v_vel = JUMP_VELOCITY
	
	velocity = Vector3(h_vel.x, v_vel, h_vel.y)
	
	if direction and MOVEMENT_MODE == MODES.HADES and not ISOMETRIC_WASD:
		velocity = velocity.rotated(Vector3.UP, TAU/2.-TAU/8.)
	
	move_and_slide()
