class_name NumLabel
extends Label

@export var value := 0. :
	set(v):
		value = v
		if is_int:
			value = int(value)
			
		text = str(value)
		
@export var is_int := true

