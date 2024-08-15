extends Area2D

@export var player: CharacterBody2D
signal on_rope_detected(area: Area2D)

func _process(delta: float) -> void:
	if player.state == player.states.SWING || player.state == player.states.GRAP:
		monitoring = false
	elif  player.state == player.states.GROUNDED:
		monitoring = true


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("SwingingRope") || area.is_in_group("WalkingRope"):
		on_rope_detected.emit(area)
