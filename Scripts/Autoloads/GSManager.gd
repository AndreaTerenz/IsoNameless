extends Node

signal reset
signal loaded(from)
signal loaded_defaults
signal applied
signal setting_changed(c, n, v)

const CONFIG_PATH := "user://settings.cfg"
const DEFAULT_CONFIG_PATH := "res://default_settings.cfg"

var config_file : ConfigFile = ConfigFile.new()

var settings = {
	"Graphics:SSIL": GameSetting.new("Graphics", "SSIL", config_file, \
		func (setting : GameSetting):
			Globals.set_env_property("ssil_enabled", setting.current_value)
			pass\
	),
	"Graphics:SSAO": GameSetting.new("Graphics", "SSAO", config_file, \
		func (setting : GameSetting):
			Globals.set_env_property("ssao_enabled", setting.current_value)
			pass\
	),
	"Graphics:Glow": GameSetting.new("Graphics", "Glow", config_file, \
		func (setting : GameSetting):
			Globals.set_env_property("glow_enabled", setting.current_value)
			pass\
	),
	"Graphics:Vsync": GameSetting.new("Graphics", "Vsync", config_file, \
		func (setting : GameSetting):
			var vsync_mode := DisplayServer.VSYNC_ENABLED if setting.current_value else DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(vsync_mode)
			pass\
	),
	"Graphics:Max_fps": GameSetting.new("Graphics", "Max_fps", config_file, \
		func (setting : GameSetting):
			Engine.max_fps = setting.current_value
			pass\
	),
}

var debug_force_default := false

func _ready():
	var config_exists := FileAccess.file_exists(CONFIG_PATH)
	
	if debug_force_default or not config_exists:
		push_warning("Config file '%s' not found" % CONFIG_PATH)
		load_settings(DEFAULT_CONFIG_PATH)
	else:
		load_settings(CONFIG_PATH)
	
	if not Globals.started:
		await Globals.level_started
	
	apply_settings()
	
func load_settings(path := CONFIG_PATH):
	config_file.load(path)
	_foreach_setting(func (setting): setting.load_value())
	
	loaded.emit(path)
	
func load_default_settings():
	load_settings(DEFAULT_CONFIG_PATH)
	loaded_defaults.emit()
	
func apply_settings(path := CONFIG_PATH):
	_foreach_setting(func (setting): setting.apply_value())
	config_file.save(path)
	
	applied.emit()
		
func reset_settings():
	_foreach_setting(func (setting): setting.reset_value())
	
	reset.emit()
	
func _foreach_setting(f: Callable):
	for setting in settings.values():
		f.call(setting)
	
func set_value(s_category: String, s_name: String, value : Variant = null):
	var key := "%s:%s" % [s_category, s_name]
	var setting = settings.get(key)
	
	if setting:
		setting.current_value = value
		setting_changed.emit(s_category, s_name, value)
		return true
		
	return false
	
func reset_value(s_category: String, s_name: String):
	var key := "%s:%s" % [s_category, s_name]
	var setting = settings.get(key)
	
	if setting:
		setting.reset_value()
		setting_changed.emit(s_category, s_name, setting.current_value)
		return true
		
	return false
	
func get_setting_key(s_category: String, s_name: String):
	var key := "%s:%s" % [s_category, s_name]
	
	if key in settings.keys():
		return key
		
	return ""
	
func get_setting(s_category: String, s_name: String):
	var setting_key = get_setting_key(s_category, s_name)
	return settings.get(setting_key)
