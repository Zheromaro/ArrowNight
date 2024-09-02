extends Area2D

signal on_player_entered(player: CharacterBody2D)

func _on_body_entered(player: Node2D) -> void:
	if not player.is_in_group("Player"):
		return
	
	on_player_entered.emit(player as CharacterBody2D)
