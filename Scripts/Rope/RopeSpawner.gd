extends Node2D

const rope = preload("res://Scense/Rope/rope.tscn")
var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and !event.is_pressed():
		
		if start_pos == Vector2.ZERO:
			start_pos = get_global_mouse_position()
		elif end_pos == Vector2.ZERO:
			end_pos = get_global_mouse_position()
			
			# Creat the rope
			var new_rope = rope.instantiate()
			add_child(new_rope)
			new_rope.spawn_rope(start_pos, end_pos)
			
			# Reset
			start_pos = Vector2.ZERO
			end_pos = Vector2.ZERO
			
			print(start_pos)
			print(end_pos)
