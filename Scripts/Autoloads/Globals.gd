extends Node

signal player_set(p)

var player : Player = null

func set_player(p: Player):
	if not player:
		player = p
		player_set.emit(p)
