extends Node2D

@onready var cast_left_right: ShapeCast2D = $Cast_left_right
@onready var cast_up_down: ShapeCast2D = $Cast_up_down

@export var collision_exceptions: Array[CollisionObject2D]

func _ready() -> void:
	for e in collision_exceptions:
		cast_left_right.add_exception(e)
		cast_up_down.add_exception(e)

func _on_player_on_grap_rope() -> void:
	cast_left_right.enabled = true
	cast_up_down.enabled = true

func _on_player_on_leave_rope() -> void:
	cast_left_right.enabled = false
	cast_up_down.enabled = false


# ---------------------------------------------------------------------
func is_colliding_right() -> bool:
	return (cast_left_right.get_collision_point(0).x > position.x  if cast_left_right.is_colliding() else false)


func is_colliding_left() -> bool:
	return cast_left_right.get_collision_point(0).x > position.x  if cast_left_right.is_colliding() else false


func is_colliding_up() -> bool:
	return cast_up_down.get_collision_point(0).y < position.y  if cast_up_down.is_colliding() else false


func is_colliding_down() -> bool:
	return cast_up_down.get_collision_point(0).y > position.y  if cast_up_down.is_colliding() else false

