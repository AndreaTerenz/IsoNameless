class_name Player
extends CharacterBody3D

# If true, W moves towards isometric forward (and so on)
# If false, W moves towards top of the screen (and so on)
@export_group("Movement")
@export var ISOMETRIC_WASD := false
@export var JUMP_ENABLED := true
@export_range(.01, 20., .005) var JUMP_VELOCITY := 4.5
@export_range(.001, 1., .001) var ROT_SPEED := .3
@export_subgroup("Ground movement")
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01,  2., .005) var H_DECELERATION := .5
@export_range(.01,  8., .005) var H_SPRINT_MULT := 6.
@export var H_SPEED_CURVE : Curve = null
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
var ui := %UI
@onready
var sprint_decal := %SprintDecal
@onready
var stats := %Stats

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var sprinting := false
var sprint_to := Vector3.ZERO
# Helpful
var sprint_delta := Vector3.ZERO
var target_dir := Vector2.ZERO
var current_dir := Vector2.ZERO

func _ready():
	Globals.set_player(self)
	sprint_decal.visible = false

func get_h_direction() -> Vector2:
	# Get the input direction and handle the movement/deceleration.
	target_dir = Input.get_vector("right", "left", "backward", "forward")
	current_dir = current_dir.lerp(target_dir, ROT_SPEED)
	
	return current_dir
	
func get_h_velocity(current: Vector3, dir := get_h_direction()) -> Vector3:
	if dir:
		var speed := H_SPEED
		
		if false and H_SPEED_CURVE:
			var mouse_proj := mouse_ground_projection()
			# HACK: SPRINT_MAX_DIST/2. here is a placeholder
			# should be a dedicated @export parameter
			var _max_dist := (SPRINT_MAX_DIST/2.)**2.
			var mproj_dist : float = min((mouse_proj - global_position).length_squared(), _max_dist)
			var fact := remap(mproj_dist, 0., _max_dist, 0., 1.)
			
			speed = H_SPEED_CURVE.sample(fact) * H_SPEED
		
		return Utils.vec_sub(dir * speed, "x0y")
	
	return current.lerp(Vector3.ZERO, H_DECELERATION) if is_on_floor() else current
	
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
	
func get_mouse_rotation() -> float:
	var viewport := get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	var screen_center = viewport.get_visible_rect().size / 2.
	var mouse_delta : Vector2 = screen_center - mouse_pos
	
	return -mouse_delta.angle() + TAU / 8.

func mouse_ground_projection() -> Vector3:
	var mouse_ray := get_mouse_ray()
	var A := mouse_ray[0]
	var B := mouse_ray[1]
	
	var P : Vector3 = global_position
	var N : Vector3 = (Vector3.UP)
	
	# FIXME : Check if point is actually reachable
	
	return Utils.isect_line_plane_v3(A,B,P,N)

func check_sprinting():
	if not sprinting and Input.is_action_just_pressed("sprint"):
		sprint_to = mouse_ground_projection()
		# There should always be a plane-ray intersection
		# so this check should be redundant
		if sprint_to == null:
			return false
		
		sprint_delta = (sprint_to - global_position)
		var sprint_dist := sprint_delta.length()
		# Change the max srpint distance based on stamina level
		var max_dist = SPRINT_MAX_DIST * stats.get_stat_value("stamina")
		
		# If the player wants to sprint too far, we limit it to the max allowed distance...
		if sprint_dist >= max_dist:
			# ...but if they try to sprint REALLY far we just ignore them
			if sprint_dist >= SPRINT_IGNORE_DIST_MULT*max_dist:
				return false
			
			sprint_delta = sprint_delta.limit_length(max_dist)
			sprint_to = global_position + sprint_delta
			
		# change stamina based on how far the player will sprint
		stats.set_stat_value("stamina", 1. - sprint_dist/max_dist)
		
		return true
	
	if sprinting:
		var gp : Vector3 = Utils.vec_sub(global_position, "x0z")
		if not Utils.length_geq((sprint_to - gp), .4):
			return false
		
	return sprinting
	
func apply_h_velocity(h_vel: Vector2):
	velocity.x = h_vel.x
	velocity.z = h_vel.y

# FIXME: When the player is falling and reaches the sprint_to
# point, it stops completely as it istantly gets out of the
# sprinting state
func _physics_process(delta):
	var h_vel : Vector3 = Utils.vec_sub(velocity, "x0z")
	var v_vel := Vector3.ZERO
	
	var _spr = check_sprinting()
	# sprint status just changed
	if _spr != sprinting:
		if _spr:
			sprint_decal.visible = true
			sprint_decal.global_position = sprint_to
			
			var h_dir : Vector3 = sprint_delta.normalized()
			
			h_vel = h_dir * H_SPEED * H_SPRINT_MULT
			v_vel *= 0.
			
			look_at(sprint_to)
			#diocane
			rotate_y(TAU/2.)
		
		sprinting = _spr
	
	if not sprinting:
		sprint_decal.visible = false
		
		var h_dir = get_h_direction()
		
		if target_dir != Vector2.ZERO:
			var rot_angle = -current_dir.angle()+TAU/8.
			rotation.y = lerp_angle(rotation.y, rot_angle, ROT_SPEED)
		
		h_vel = get_h_velocity(velocity, h_dir)
		v_vel = get_v_velocity(velocity.y, delta)
		
	velocity = h_vel + v_vel
	move_and_slide()
	
func _input(_event):
	if Input.is_action_just_pressed("fire"):
		var ray_length = global_position.distance_to(Globals.player.global_position) + 30.
		var m_ray := get_mouse_ray(ray_length)
		
		var from = m_ray[0]
		var to = m_ray[1]
		
		var interactable = interact_ray.check(from, to)
		if interactable:
			Globals.log_msg("Interacted!")
			interactable.interact()

func get_mouse_ray(length := 1.) -> Array[Vector3]:
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := camera.project_position(mouse_pos, length)
	
	return [from, to]
