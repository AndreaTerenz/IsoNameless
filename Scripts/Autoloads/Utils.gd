extends Node

static func vec_sub(v, s: String):
	# WHY IS THERE NO VECTIR BASE CLASS DIOCANEEEEE
	if not (v is Vector2 or v is Vector3 or v is Vector4):
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
