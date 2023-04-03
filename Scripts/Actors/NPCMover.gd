class_name NPCMover
extends Node

var current_velocity := Vector3.ZERO

#TODO: This thing should, in the future, compute the NPC's velocity,
#maybe with some kinda state machine, and provide it to the main node
func update_velocity(delta: float) -> Vector3:
	current_velocity = Vector3.ZERO
	
	return current_velocity
