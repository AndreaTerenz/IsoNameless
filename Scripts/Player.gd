class_name Player
extends CharacterBody3D

# If true, W moves towards isometric forward (and so on)
# If false, W moves towards top of the screen (and so on)
@export_group("Movement")
@export var ISOMETRIC_WASD := false
@export var JUMP_ENABLED := true
@export_range(.01, 20., .005) var TOTAL_SPEED = 5. 
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5
@export_range(.01, 20., .005) var ROT_SENSITIVITY := 4.
@export_subgroup("Ground movement")
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01,  2., .005) var H_DECELERATION := .5
@export_range(.01,  8., .005) var H_SPRINT_MULT := 6.
@export_subgroup("Sprinting")
@export_range(.01,  30., .005) var SPRINT_MAX_DIST := 8.
@export_range(1.,  5., .005) var SPRINT_IGNORE_DIST_MULT := 2.5

@export_group("Stamina")
@export_range(.001, 1., .0005) var STAMINA_RATE := .5

@onready
var body := %Body
@onready
var camera : Camera3D = %Camera
@onready
var camera_pivot := %CameraPivot
@onready
var interact_ray := %InteractRay
@onready
var ui = %UI

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var sprinting := false
var sprint_to := Vector3.ZERO
# Helpful
var sprint_delta := Vector3.ZERO

func _ready():
	Globals.set_player(self)
	ui.stamina_recharge_rate = STAMINA_RATE

func get_h_direction() -> Vector2:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("right", "left", "backward", "forward")
	var dir = (transform.basis * Utils.vec_sub(input_dir, "x0y")).normalized()
	
	var output = Utils.vec_sub(dir, "xz")
	
	return output if ISOMETRIC_WASD else output.rotated(TAU/8.+TAU/2.)
	
func get_h_velocity(current: Vector2, dir: Vector2) -> Vector2:
	if dir:
		return dir * H_SPEED
	
	return current.lerp(Vector2.ZERO, H_DECELERATION * float(is_on_floor()))
	
func get_v_velocity(current: float, delta: float) -> Vector3:
	var output := Vector3.UP
	
	# Add the gravity.
	if not is_on_floor():
		output *= current - gravity * delta
	# Handle Jump.
	elif Input.is_action_just_pressed("jump") and JUMP_ENABLED:
		output *= JUMP_VELOCITY
	else:
		output *= current
		
	return output
	
func get_body_rotation() -> float:
	var viewport := get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_center = viewport.get_visible_rect().size / 2.
	var angle_delta : Vector2 = mouse_pos - screen_center
	
	return -angle_delta.angle() + TAU / 8.

func get_sprint_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var A := camera.project_ray_origin(mouse_pos)
	var B := camera.project_position(mouse_pos, 1.)
	
	var P : Vector3 = global_position
	var N : Vector3 = (Vector3.UP)
	
	# FIXME : Check if point is actually reachable
	
	return Utils.isect_line_plane_v3(A,B,P,N)

func check_sprinting():
	if not sprinting and Input.is_action_just_pressed("sprint"):
		sprint_to = get_sprint_position()
		# There should always be a plane-ray intersection
		# so this check should be redundant
		if sprint_to == null:
			return false
		
		sprint_delta = (sprint_to - global_position)
		var sprint_dist := sprint_delta.length()
		# Change the max srpint distance based on stamina level
		var max_dist = SPRINT_MAX_DIST * ui.stamina
		
		# If the player wants to sprint too far, we limit it to the max allowed distance...
		if sprint_dist >= max_dist:
			# ...but if they try to sprint REALLY far we just ignore them
			if sprint_dist >= SPRINT_IGNORE_DIST_MULT*max_dist:
				return false
			
			sprint_delta = sprint_delta.limit_length(max_dist)
			sprint_to = global_position + sprint_delta
			
		# change stamina based on how far the player will sprint
		ui.stamina = 1. - sprint_dist/max_dist
		
		return true
	
	if sprinting:
		var gp : Vector3 = Utils.vec_sub(global_position, "x0z")
		if not Utils.length_geq((sprint_to - gp), .4):
			return false
		
	return sprinting
	
func apply_h_velocity(h_vel: Vector2):
	velocity.x = h_vel.x
	velocity.z = h_vel.y

func _physics_process(delta):
	var _spr = check_sprinting()
	var h_vel := Vector2.ZERO
	var old_sprint_vel := Vector3.ZERO
	
	# sprint status just changed
	if _spr != sprinting:
		
		if _spr:
			Globals.log_msg("Sprinting to: %s" % [sprint_to])
			var h_dir : Vector2 = Utils.vec_sub(sprint_delta.normalized(), "xz")
			h_vel = h_dir * H_SPEED * H_SPRINT_MULT
		else:
			#old_sprint_vel = velocity
			Globals.log_msg("Sprint done")
		
		sprinting = _spr
		apply_h_velocity(h_vel)
	
	if not sprinting:
		body.rotation.y = get_body_rotation()
		
		h_vel = get_h_velocity(Utils.vec_sub(velocity, "xz"), get_h_direction())
		var v_vel := get_v_velocity(velocity.y, delta)
		
		velocity = Utils.vec_sub(h_vel, "x0y") + v_vel + old_sprint_vel
	
	move_and_slide()
	
func _input(_event):
	if Input.is_action_just_pressed("fire"):
		var ray_length = global_position.distance_to(Globals.player.global_position) + 30.
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * ray_length
		
		interact_ray.global_position = from
		interact_ray.target_position = interact_ray.to_local(to)
		
		interact_ray.force_raycast_update()
		
		var coll = interact_ray.get_collider() as Node3D
		if coll and coll.player_inside:
			Globals.log_msg("Interacted!")
			coll.interact()
