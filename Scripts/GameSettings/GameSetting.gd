class_name GameSetting
extends Object

var category := ""
var name := ""
var stored_value : Variant = null
var current_value : Variant = null
var changed : bool :
	get:
		return current_value != stored_value
var config_file : ConfigFile = null
var on_apply : Callable

func _init(_category : String, _name: String, cfile: ConfigFile, _on_apply: Callable):
	category = _category
	name = _name
	
	current_value = null
	config_file = cfile
	on_apply = _on_apply
	
func load_value(source_file : ConfigFile = config_file):
	if not source_file:
		push_error("Tried reading setting '%s/%s' from null ConfigFile" % [category, name])
		return null
		
	stored_value = source_file.get_value(category, name)
	current_value = stored_value
	
	return current_value
	
func store_value(destination_file : ConfigFile = config_file):
	if not destination_file:
		push_error("Tried writing setting '%s/%s' to null ConfigFile" % [category, name])
		return false
		
	if changed:
		destination_file.set_value(category, name, current_value)
		stored_value = current_value
		return true
		
	return false

func reset_value():
	current_value = stored_value
	
func apply_value(no_store := false, dest_file: ConfigFile = config_file):
	if not no_store:
		store_value(dest_file)
		
	if on_apply:
		on_apply.call(self)
