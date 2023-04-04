class_name DamageTrigger
extends Trigger

# negative value == instant death
@export var dps := .2
@export var oneshot_damage := false

var keep_going := true

func _process(delta):
	if not player_inside or not keep_going:
		return
		
	if dps < 0.:
		Globals.player.set_stat("health", 0.)
	else:
		var dmg := -dps
		if not oneshot_damage:
			dmg *= delta
		else:
			keep_going = false
		
		Globals.player.change_stat("health", dmg)
		
func _on_player_left():
	keep_going = true
