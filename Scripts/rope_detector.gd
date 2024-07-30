extends Area2D

@export var player: CharacterBody2D

func _process(delta: float) -> void:
	if player.state == player.states.HANGE:
		monitoring = false
	elif  player.state == player.states.GROUNDED:
		monitoring = true
		
