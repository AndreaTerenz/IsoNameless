class_name PlayerStats
extends Node

signal stat_changed(s, from, to)
signal stat_reset(s)

class Stat extends Node:
	var default_val : float
	var min_val : float
	var max_val : float
	var _curr : float
	var current :
		get:
			return _curr
		set(new_val):
			_curr = clamp(new_val, min_val, max_val)
				
	var on_process = null
	
	func _init(_name : String, _default := 1., _min := 0., _max := 1., _onproc = null):
		self.name = _name
		self.default_val = _default
		self.min_val = _min
		self.max_val = _max
		
		reset()
		
		self.on_process = _onproc
		
	func reset():
		self.current = self.default_val
		
	func _physics_process(delta):
		if self.on_process:
			self.on_process.call(delta)

var stats := {
	"health": Stat.new("health", 1., 0., 1.),
	"armor": Stat.new("armor", 0., 0., 1.),
	"stamina": Stat.new("stamina", 1., 0., 1.,
		func (delta):
			self.change_stat_value("stamina", Globals.player.STAMINA_RATE * delta)\
	)
}

func _ready():
	for s in stats.values():
		add_child(s)

func get_stat_value(s_name: String) -> float:
	var s : Stat = stats.get(s_name.to_lower())
	if s:
		return s.current
	
	push_error("Failed to get value for PlayerStat '%s' [Not found]" % s_name)
	return 0.

func set_stat_value(s_name: String, new_val: float) -> bool:
	var s : Stat = stats.get(s_name.to_lower())
	if s:
		var old = s.current
		s.current = new_val
		stat_changed.emit(s, old, s.current)
		return true
	
	push_error("Failed to set value for PlayerStat '%s' [Not found]" % s_name)
	return false

func change_stat_value(s_name: String, delta: float) -> bool:
	var s : Stat = stats.get(s_name.to_lower())
	if s:
		var new_val = s.current + delta
		return set_stat_value(s_name, new_val)
	
	push_error("Failed to change value for PlayerStat '%s' [Not found]" % s_name)
	return false

func reset_stat(s_name: String) -> bool:
	var s : Stat = stats.get(s_name.to_lower())
	if s:
		s.reset()
		stat_reset.emit(s)
		return true
	
	push_error("Failed to reset value for PlayerStat '%s' [Not found]" % s_name)
	return false
