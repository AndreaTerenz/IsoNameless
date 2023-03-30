class_name Player
extends CharacterBody3D

enum MODE {
	NORMAL,
	COMBAT,
	DIALOGUE
}

signal entered_door(d)
signal exited_door(d)
signal mode_changed(md)

@export var initial_mode := MODE.NORMAL
@export_group("Movement")
# If true, W moves towards isometric forward (and so on)
# If false, W moves towards top of the screen (and so on)
@export var ISOMETRIC_WASD := false
@export_range(.001, 1., .001) var ROT_SPEED := .3
@export_subgroup("Ground movement")
@export_range(.01, 50., .005) var H_SPEED := 5.
@export_range(.01,  2., .005) var H_DECELERATION := .5
@export_range(.01,  8., .005) var H_SPRINT_MULT := 6.
@export_subgroup("Sprinting")
@export_range(.01,  30., .005) var SPRINT_MAX_DIST := 8.
@export_range(1.,  5., .005) var SPRINT_IGNORE_DIST_MULT := 2.5

@export_group("Stats")
@export_range(.001, 1., .0005) var STAMINA_RATE := .5

@onready var body := %Body
@onready var camera : Camera3D = %Camera
@onready var camera_pivot := %CameraPivot
@onready var ui := %UI
@onready var sprint_decal := %SprintDecal
@onready var stats := %Stats
@onready var interact_manager = %InteractManager
@onready var memory = %Memory
@onready var map_camera = %MapCamera
@onready var inventory : Inventory = %Inventory

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var sprinting := false
var sprint_to := Vector3.ZERO
# Helpful
var sprint_delta := Vector3.ZERO
var target_dir := Vector2.ZERO
var current_dir := Vector2.ZERO
var sprinting_collided := false

var current_door = null
var current_mode := MODE.NORMAL :
	get:
		return current_mode
	set(new_mode):
		current_mode = new_mode
		
		match current_mode:
			MODE.NORMAL, MODE.DIALOGUE:
				Globals.set_cursor_mode(Globals.CURSOR_MODE.NORMAL)
			MODE.COMBAT:
				Globals.set_cursor_mode(Globals.CURSOR_MODE.COMBAT)
		
		mode_changed.emit(current_mode)

func _ready():
	current_mode = initial_mode
	sprint_decal.visible = false
	
	Globals.player = self

func get_h_direction() -> Vector2:
	target_dir = Input.get_vector("right", "left", "backward", "forward")
	# Direction is screen-dependant, so it has to account for camera rotation
	target_dir = target_dir.rotated(-camera_pivot.target_rot)
	current_dir = current_dir.lerp(target_dir, ROT_SPEED)
	
	return current_dir
	
func dir_to_rotation(dir : Vector2) -> float:
	var rot_angle = -dir.angle()+TAU/8.
	rot_angle = snappedf(rot_angle, TAU/8.)
	
	if Utils.length_geq(dir, .001):
		return lerp_angle(rotation.y, rot_angle, ROT_SPEED)
		
	return rot_angle
	
func get_h_velocity(current: Vector3, dir := get_h_direction()) -> Vector3:
	if dir:
		return Utils.vec_sub(dir * H_SPEED, "x0y")
	
	if is_on_floor():
		return current.lerp(Vector3.ZERO, H_DECELERATION)
		
	return current
	
func get_v_velocity(current: float, delta: float) -> Vector3:
	var output := Vector3.UP
	
	# Add the gravity.
	if not is_on_floor():
		output *= current - gravity * delta
	else:
		output *= current
		
	return output

func check_sprinting():
	if not sprinting and Input.is_action_just_pressed("sprint") and current_mode == MODE.NORMAL:
		sprint_to = camera.mouse_ground_projection()
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
		sprinting_collided = false
		
		return true
	
	if sprinting:
		if sprinting_collided:
			return false
			
		var gp : Vector3 = Utils.vec_sub(global_position, "x0z")
		var st : Vector3 = Utils.vec_sub(sprint_to, "x0z")
		if not Utils.length_geq((st - gp), .4):
			return false
		
	return sprinting
	
func apply_h_velocity(h_vel: Vector2):
	velocity.x = h_vel.x
	velocity.z = h_vel.y

# FIXME: When the player is falling and reaches the sprint_to
# point, it stops completely as it istantly gets out of the
# sprinting state
func _physics_process(delta):
	if current_mode == MODE.DIALOGUE:
		return
	
	var h_vel : Vector3 = Utils.vec_sub(velocity, "x0z")
	var v_vel := Vector3.ZERO
	
	var slide := true
	
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
	
	slide = not sprinting
	
	if not sprinting:
		sprint_decal.visible = false
		
		var h_dir = get_h_direction()
		
		if current_mode == MODE.NORMAL:
			rotation.y = dir_to_rotation(h_dir)
		elif current_mode == MODE.COMBAT:
			var spot = camera.mouse_ground_projection()
			look_at(spot)
			rotate_y(TAU/2.)
		
		h_vel = get_h_velocity(velocity, h_dir)
		v_vel = get_v_velocity(velocity.y, delta)
		
	velocity = h_vel + v_vel
	
	if slide:
		move_and_slide()
	else:
		var collision := move_and_collide(velocity * delta)
		if collision:
			sprinting_collided = true
	
func _input(_event):
	if Input.is_action_just_pressed("toggle_combat"):
		if current_mode != MODE.DIALOGUE:
			current_mode = MODE.COMBAT if (current_mode == MODE.NORMAL) else MODE.NORMAL
	
func enter_door(d: Area3D):
	if not current_door:
		current_door = d
		entered_door.emit(d)
	
func exit_door(d: Area3D):
	if d == current_door:
		current_door = null
		exited_door.emit(d)

func _on_interact_manager_dialogue_start(other):
	current_mode = MODE.DIALOGUE
	ui.start_dialogue(other)
	
func interact_with(other: Interactable):
	interact_manager.interact(other)
	
func _on_interact_manager_dialogue_end():
	current_mode = MODE.NORMAL

func memory_get(key: String, default : Variant = null):
	return memory.get_value(key, default)

func player_memorize(key: String, value):
	memory.set_value(key, value)

func _on_memory_learned(k, v):
	Globals.log_msg("New Player fact: [%s | %s]" % [k, v])


func _on_inventory_item_amount_changed(idx: int, item: InventoryItem, new_amount: int, delta: int):
	Globals.log_msg("Picked up %d units of %s" % [delta, item])
	
func receive_item(item: InventoryItem, amount: int) -> bool:
	var ok := inventory.add_item(item, amount)
	
	if not ok:
		push_error("Failed to give %d of item %s to Player!" % [amount, item])
		
	return ok
		
