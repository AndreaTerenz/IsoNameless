class_name Door
extends Area3D

signal player_entered
signal player_exited

enum DOOR_DIR {
	X,Y,Z,nX,nY,nZ
}

@export var outside_mesh : GeometryInstance3D
@export var direction : DOOR_DIR = DOOR_DIR.Z
@export_range(.0, 1., .001) var max_transparency = .85

@onready
var shape := $CollisionShape3D

var outside_face : Vector3
var inside_face : Vector3
var door_depth := 0.
var inside := false
var dir_vec :
	get:
		return dir_to_vec3(direction)
var local_player_pos:
	get:
		return shape.to_local(Globals.player.global_position) + outside_face

func _ready():
	await Globals.await_level()

	var shape_size := (shape.shape as BoxShape3D).size
	
	outside_face = dir_vec * (shape_size / 2.)
	inside_face = outside_face * -1.
	door_depth = get_pos_depth(inside_face)
	
	body_entered.connect(
		func (body):
			if body == Globals.player:
				inside = true
				Globals.player.enter_door(self)
				player_entered.emit()
	)
	
	body_exited.connect(
		func (body):
			if body != Globals.player:
				return
				
			#outside_mesh.transparency = round(outside_mesh.transparency)
			inside = false
			Globals.player.exit_door(self)
			player_exited.emit()
	)
	
func _process(delta):
	if not inside:
		return
	
	var p_depth : float = get_player_depth()
	var factor : float = remap(p_depth / door_depth, 0., 1., max_transparency, 0.)
	
	outside_mesh.transparency = factor
	
func get_player_depth() -> float:
	if not inside:
		return -1.
	
	var p_pos : Vector3 = (local_player_pos) * dir_to_vec3(direction)
	return get_pos_depth(p_pos)

func face_closest_to_pos(p: Vector3) -> Vector3:
	var out_dist := p.distance_squared_to(outside_face)
	var in_dist := p.distance_squared_to(inside_face)
	
	if out_dist < in_dist:
		return outside_face
	elif out_dist > in_dist:
		return inside_face
	
	return Vector3.ZERO
	
func get_pos_depth(p: Vector3) -> float:
	if Utils.length_geq(p, door_depth/2.):
		p = (face_closest_to_pos(p))
		
	return ((outside_face - p) * dir_vec).length()

func dir_to_vec3(dir: DOOR_DIR) -> Vector3:
	match dir:
		DOOR_DIR.X:
			return Vector3.RIGHT
		DOOR_DIR.Y:
			return Vector3.UP
		DOOR_DIR.Z:
			return Vector3.BACK
		DOOR_DIR.nX:
			return Vector3.LEFT
		DOOR_DIR.nY:
			return Vector3.DOWN
		DOOR_DIR.nZ:
			return Vector3.FORWARD

	return Vector3.ZERO
