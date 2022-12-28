class_name Player
extends CharacterBody3D

#enum MODES {
#	# Move with WASD in local directions, rotate *whole player* with Q and E 
#	TANK,
#	# Move with WASD in absolute NSEW directions, rotate *body* with mouse
#	HADES
#}
#
#@export_enum("Tank", "Hades") var MOVEMENT_MODE : int = MODES.TANK

# If true, W moves towards isometric forward (and so on)
# If false, W moves towards top of the screen (and so on)
@export var ISOMETRIC_WASD := false
@export var JUMP_ENABLED := true

@export_range(.01, 20., .005) var TOTAL_SPEED = 5. 
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01,  2., .005) var H_DECELERATION := .5
@export_range(.01,  8., .005) var H_SPRINT_MULT := 6.
@export_range(.01,  30., .005) var SPRINT_MAX_DIST := 8.
@export_range(1.,  5., .005) var SPRINT_IGNORE_DIST_MULT := 2.5
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5
@export_range(.01, 20., .005) var ROT_SENSITIVITY := 4.

@onready
var body := %Body
@onready
var camera : Camera3D = %Camera
@onready
var camera_pivot := %CameraPivot
@onready
var interact_ray := %InteractRay

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var sprinting := false
var sprint_to := Vector3.ZERO

func _ready():
	Globals.set_player(self)

func get_h_direction() -> Vector2:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("right", "left", "backward", "forward")
	var dir = (transform.basis * Utils.vec_sub(input_dir, "x0y")).normalized()
	
	return Utils.vec_sub(dir, "xz")
	
func get_h_velocity(current: Vector2, dir: Vector2) -> Vector2:
	if dir:
		return dir * H_SPEED
	
	return current.lerp(Vector2.ZERO, H_DECELERATION * float(is_on_floor()))
	
func get_v_speed(current: float, delta: float) -> float:
	# Add the gravity.
	if not is_on_floor():
		return current - gravity * delta
	# Handle Jump.
	elif Input.is_action_just_pressed("jump") and JUMP_ENABLED:
		return JUMP_VELOCITY
		
	return current
	
func get_body_rotation() -> float:
	var viewport := get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_center = viewport.get_visible_rect().size / 2.
	var angle_delta : Vector2 = mouse_pos - screen_center
	
	return -angle_delta.angle() + TAU / 8.
	
func check_sprinting():
	if not sprinting and Input.is_action_just_pressed("sprint"):
		var mouse_pos = get_viewport().get_mouse_position()
		var A := camera.project_ray_origin(mouse_pos)
		var B := camera.project_position(mouse_pos, 1.)
		
		var P : Vector3 = body.global_position
		var N : Vector3 = (Vector3.UP)
		
		# FIXME : Check if point is actually reachable
		
		sprint_to = Utils.isect_line_plane_v3(A,B,P,N)
		
		var pos_delta := (sprint_to - global_position)
		Utils.mute_debug_meshes = true
		if pos_delta.length_squared() >= (SPRINT_MAX_DIST**2):
			# If the player wants to sprint too far, we limit it to the max allowed distance...
			
			# ...but if they try to sprint REALLY far we just ignore them
			if pos_delta.length_squared() >= (SPRINT_IGNORE_DIST_MULT*SPRINT_MAX_DIST)**2:
				Utils.create_debug_mesh(SphereMesh.new(), sprint_to, preload("res://Materials/Grids/red_grid.tres"))
				return false
			else:
				Utils.create_debug_mesh(SphereMesh.new(), sprint_to, preload("res://Materials/Grids/yellow_grid.tres"))
			
			pos_delta = pos_delta.limit_length(SPRINT_MAX_DIST)
			sprint_to = global_position + pos_delta
		
		Utils.create_debug_mesh(SphereMesh.new(), sprint_to, preload("res://Materials/Grids/green_grid.tres"))
		
		var h_dir : Vector2 = Utils.vec_sub(pos_delta.normalized(), "xz")
		var h_vel := h_dir * H_SPEED * H_SPRINT_MULT
		velocity.x = h_vel.x
		velocity.z = h_vel.y
		Globals.new_debug_msg("Sprinting to: %s" % [sprint_to])
		
		return true
		
	var h_vel : Vector2 = Utils.vec_sub(velocity, "xz")
	if (sprint_to - global_position).length_squared() <= 0.1:
		Globals.new_debug_msg("Sprint done")
		velocity *= 0.
		return false
		
	return sprinting

func _physics_process(delta):
	sprinting = check_sprinting()
	
	if not sprinting:
		body.rotation.y = get_body_rotation()
		
		var h_dir := get_h_direction()
		var h_vel := get_h_velocity(Utils.vec_sub(velocity, "xz"), h_dir)
		var v_vel := get_v_speed(velocity.y, delta)
		
		velocity = Vector3(h_vel.x, v_vel, h_vel.y)
		if not ISOMETRIC_WASD:
			# Why 135° ????
			velocity = velocity.rotated(Vector3.UP, TAU/2.-TAU/8.)
	else:
		var h_vel : Vector2 = Utils.vec_sub(velocity, "xz")
		h_vel = h_vel.lerp(Vector2.ZERO, 0.1)
		
		#velocity.x = h_vel.x
		#velocity.z = h_vel.y
	
	move_and_slide()
	
func _input(event):
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
			Globals.new_debug_msg("Interacted!")
			coll.interact()
