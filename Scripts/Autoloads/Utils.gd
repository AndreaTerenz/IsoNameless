extends Node

var mute_debug_meshes := false
var phys_layers : Dictionary = {}
var render_layers : Dictionary = {}

static func vec_sub(v, s: String):
	# WHY IS THERE NO VECTIR BASE CLASS DIOCANEEEEE
	if not (v is Vector2 or v is Vector3 or v is Vector4) or (v == null):
		return v
	
	if not len(s) in [2,3,4]:
		return v
	
	var regex = RegEx.new()
	
	if v is Vector2:
		regex.compile("^[xy0]{2,4}$")
	elif v is Vector3:
		regex.compile("^[xyz0]{2,4}$")
	elif v is Vector4:
		regex.compile("^[xyzw0]{2,4}$")
	
	if not regex.search(s):
		return v
		
	var output_arr : Array[float] = []
	
	for c in s:
		match c:
			"0":
				output_arr.append(0.)
			"x":
				output_arr.append(v.x)
			"y":
				output_arr.append(v.y)
			"z":
				output_arr.append(v.z)
			"w":
				output_arr.append(v.w)
				
	match len(output_arr):
		2:
			return Vector2(output_arr[0], output_arr[1])
		3:
			return Vector3(output_arr[0], output_arr[1], output_arr[2])
		4:
			return Vector4(output_arr[0], output_arr[1], output_arr[2], output_arr[3])
			
	return v
	
func project_on_line(a: Vector3, b: Vector3, p: Vector3) -> Vector3:
	var ap := p-a
	var ab := (b-a)#.normalized()
	var result = a + (ap.dot(ab) / ab.dot(ab)) * ab
	return result

# intersection function
func isect_line_plane_v3(p0: Vector3, p1: Vector3, p_co: Vector3, p_no: Vector3, epsilon=1e-8):
#	p0, p1: Define the line.
#	p_co, p_no: define the plane:
#		p_co Is a point on the plane (plane coordinate).
#		p_no Is a normal vector defining the plane direction;
#			 (does not need to be normalized).
#
#	Return a Vector or None (when the intersection can't be found).

	var u = p1-p0
	var dot = p_no.dot(u)

	if abs(dot) > epsilon:
		# The factor of the point between p0 -> p1 (0 - 1)
		# if 'fac' is between (0 - 1) the point intersects with the segment.
		# Otherwise:
		#  < 0.0: behind p0.
		#  > 1.0: infront of p1.
		var w = p0 - p_co
		var fac = -p_no.dot(w) / dot
		u *= fac
		return p0 + u

	# The segment is parallel to plane.
	return null

func create_debug_mesh(global_pos: Vector3, mesh: Mesh = SphereMesh.new(), material : Material = preload("res://Materials/Grids/white_grid.tres")):
	if mute_debug_meshes:
		return null
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.set_surface_override_material(0, material)
	
	get_tree().root.add_child(mesh_inst)
	
	mesh_inst.global_position = global_pos
	
	return mesh_inst
	
func length_geq(vec, dist: float):
	return vec.length_squared() >= dist**2
	
func make_background_colorrect(parent : Node = get_tree().root):
	var cr := ColorRect.new()
	
	parent.add_child.call_deferred(cr)
	await cr.tree_entered
	
	cr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	return cr

############################################## LAYERS

func _ready() -> void:
	for i in range(0, 32):
		var p_layer = get_layer_name(i, "3d_physics")
		if not p_layer in [null, ""]:
			phys_layers[p_layer] = i+1
			
		var r_layer = get_layer_name(i, "3d_render")
		if not r_layer in [null, ""]:
			render_layers[r_layer] = i+1
		
func get_layer_name(idx: int, category: String):
	return ProjectSettings.get_setting("layer_names/%s/layer_%d" % [category, idx+1])
	
func get_phys_layer_idx(l_name: String) -> int:
	if not phys_layers.has(l_name):
		return -1
		
	return phys_layers[l_name]
	
func get_render_layer_idx(l_name: String) -> int:
	if not render_layers.has(l_name):
		return -1
		
	return render_layers[l_name]
	
func get_layer_bit(obj: CollisionObject3D, l_name: String) -> bool:
	if not phys_layers.has(l_name):
		push_error("Layer %s not found!" % l_name)
		return false
		
	return obj.get_collision_layer_value(phys_layers[l_name])
	
func get_mask_bit(obj: Node3D, l_name: String) -> bool:
	var has_mask := obj.has_method("get_collision_mask_value")
	
	if not has_mask:
		push_error("Object has no collision_mask property!")
		return false
	
	if not phys_layers.has(l_name):
		push_error("Layer %s not found!" % l_name)
		return false
	
	return obj.get_collision_mask_value(phys_layers[l_name])
	
func set_layer_bit(obj: CollisionObject3D, l_name: String, value := true, exclusive := false) -> bool:
	if not phys_layers.has(l_name):
		push_error("Layer %s not found!" % l_name)
		return false
	
	if exclusive:
		obj.collision_layer *= 0
	
	obj.set_collision_layer_value(phys_layers[l_name], value)
	return true
	
func set_mask_bit(obj: Node3D, l_name: String, value := true, exclusive := false) -> bool:
	var has_mask := obj.has_method("set_collision_mask_value")
	
	if not has_mask:
		push_error("Object has no collision_mask property!")
		return false
	
	if not phys_layers.has(l_name):
		push_error("Layer %s not found!" % l_name)
		return false
	
	if exclusive:
		obj.collision_mask *= 0
	
	obj.set_collision_mask_value(phys_layers[l_name], value)
	return true
	
func set_layer_bits(obj: CollisionObject3D, l_names: Array[String], value := true, exclusive := false):
	for idx in range(len(l_names)):
		var ln = l_names[idx]
		var ex = (exclusive and (idx == 0))
		if not set_layer_bit(obj, ln, value, ex):
			return
	
func set_mask_bits(obj: Node3D, l_names: Array[String], value := true, exclusive := false):
	for idx in range(len(l_names)):
		var ln = l_names[idx]
		var ex = (exclusive and (idx == 0))
		if not set_mask_bit(obj, ln, value, ex):
			return
