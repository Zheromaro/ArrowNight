extends Node2D

@onready var rope_anchor: RopeAnchor = $RopeAnchor

func _on_area_2d_body_entered(body: Node2D) -> void:
	rope_anchor.position == body.position
