extends Node

var mute_debug_meshes := false

static func vec_sub(v, s: String):
	# WHY IS THERE NO VECTIR BASE CLASS DIOCANEEEEE
	if not (v is Vector2 or v is Vector3 or v is Vector4) or (v == null):
		return v
	
	if not len(s) in [2,3,4]:
		return v
	
	var regex = RegEx.new()
	
	var regex_str :=  ""
	
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

func create_debug_mesh(mesh: Mesh, global_pos: Vector3, material : Material = preload("res://Materials/Grids/white_grid.tres")):
	if mute_debug_meshes:
		return
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.set_surface_override_material(0, material)
	
	get_tree().root.add_child(mesh_inst)
	mesh_inst.global_position = global_pos
	
func length_geq(vec, dist: float):	
	return vec.length_squared() >= dist**2
