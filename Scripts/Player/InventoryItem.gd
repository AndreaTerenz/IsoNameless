class_name InventoryItem
extends Resource

@export var name : String = "gigio"
@export var icon : Texture = preload("res://icon.png")
@export_range(1,64) var max_stack : int = 32
@export_range(.0001, 200.0, .0001) var weight := .001

func _init(n: String = "gigio", i: Texture = null, ms := 32, w := .001):
	name = n
	icon = i
	max_stack = ms
	weight = w

func _to_string():
	return "[Item '%s']" % name
