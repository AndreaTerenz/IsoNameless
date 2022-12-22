class_name Player
extends CharacterBody3D

@export_range(.01, 20., .005) var TOTAL_SPEED = 5. 
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01, 2., .005) var H_DECELERATION := .5
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5

@onready
var body := %Body

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Globals.set_player(self)

func _physics_process(delta):
	var on_floor := is_on_floor()
	var v_vel := velocity.y
	var h_vel := Vector2(velocity.x, velocity.z)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("right", "left", "backward", "forward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		h_vel = Vector2(direction.x, direction.z) * H_SPEED
		h_vel = h_vel.rotated(TAU/8.).rotated(TAU/2.)
	else:
		h_vel = h_vel.lerp(Vector2.ZERO, H_DECELERATION * float(on_floor))
		
	# Add the gravity.
	if not on_floor:
		v_vel -= gravity * delta
	# Handle Jump.
	elif Input.is_action_just_pressed("jump"):
		v_vel = JUMP_VELOCITY
	
	velocity = Vector3(h_vel.x, v_vel, h_vel.y)
	
	if direction:
		var body_look_pos = Vector3(velocity.x, 0., velocity.z).normalized()
		body.look_at((global_position - body_look_pos), Vector3.UP)
		
	move_and_slide()
