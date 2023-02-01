extends Node

signal reset
signal loaded
signal stored
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
}

var debug_force_default := true

func _ready():
	if debug_force_default or not ResourceLoader.exists(CONFIG_PATH):
		push_warning("Config file '%s' not found" % CONFIG_PATH)
		load_settings(DEFAULT_CONFIG_PATH)
		store_settings(CONFIG_PATH)
	else:
		load_settings(CONFIG_PATH)
	
	if not Globals.started:
		await Globals.level_started
	
	apply_settings()
	
func load_settings(path := CONFIG_PATH):
	config_file.load(path)
	
	_foreach_setting(func (setting): setting.load_value())
	
	loaded.emit()
		
func store_settings(path := CONFIG_PATH):
	_foreach_setting(func (setting): setting.store_value())
		
	config_file.save(path)
	
	stored.emit()
	
func apply_settings():
	_foreach_setting(func (setting): setting.apply_value())
	
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
