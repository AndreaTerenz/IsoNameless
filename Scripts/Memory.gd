class_name Memory
extends Node

signal learned(k,v)
signal forgot(k, last_v)
signal reset

var _memory_dict := {}

func get_value(key: String, default : Variant = null):
	return _memory_dict.get(key, default)

func set_value(key: String, value):
	_memory_dict[key] = value
	learned.emit(key, value)
	
func has_value(key: String):
	return key in _memory_dict.keys()
	
func forget_value(key: String):
	return _memory_dict.erase(key)

func reset_values():
	_memory_dict.clear()
	reset.emit()
