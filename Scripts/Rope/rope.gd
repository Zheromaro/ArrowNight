extends CanvasItem

const rope_piece := preload("res://Scense/Rope/rope_piece.tscn")
var piece_length := 4.0
var rope_parts := []
var rope_close_tolerance := 4.0
var rope_points : PackedVector2Array = []
var rope_face_left := true
var active_rope_id := -INF :
	set(value):
		if value == -INF:
			for p in rope_parts:
				(p as RigidBody2D).mass =1
		else:
			for p in len(rope_parts):
				if p == active_rope_id:
					(rope_parts[p] as RigidBody2D).mass = 10
				else:
					(rope_parts[p] as RigidBody2D).mass =1
		
		active_rope_id = value

@onready var rope_start_piece: StaticBody2D = $RopeStartPiece
@onready var rope_end_piece: StaticBody2D = $RopeEndPiece
@onready var rope_start_joint: PinJoint2D = $RopeStartPiece/C/J
@onready var rope_end_joint: PinJoint2D = $RopeEndPiece/C/J


func _process(_delta: float) -> void:
	update_rope_point()
	
	if !rope_points.is_empty():
		queue_redraw()

# just for testing
func spawn_rope(start_pos: Vector2, end_pos: Vector2) -> void:
	rope_start_piece.global_position = start_pos 
	rope_end_piece.global_position = end_pos
	start_pos = rope_start_joint.global_position
	end_pos = rope_end_joint.global_position
	rope_face_left = start_pos.x < end_pos.x
	
	var distance = start_pos.distance_to(end_pos)
	var pieces_amount = round(distance / piece_length)
	var spawn_angel = (start_pos - end_pos).angle() + PI/2
	
	create_rope(pieces_amount, rope_start_piece, end_pos, spawn_angel)

# for creating the rope
func create_rope(pieces_amount: int, parent: Object, end_pos: Vector2, spawn_angel: float) -> void:
	for i in pieces_amount:
		parent = add_piece(parent, i, spawn_angel)
		rope_parts.append(parent)
		
		var joint_pos: Vector2 = parent.get_node("C/J").global_position
		if joint_pos.distance_to(end_pos) < rope_close_tolerance:
			break
	
	# connect the rope to the end piece
	rope_end_joint.node_a = rope_end_piece.get_path()
	rope_end_joint.node_b = rope_parts[-1].get_path()

func add_piece(parent: Object, id: int, spawn_angle: float) -> Object:
	var joint : PinJoint2D = parent.get_node("C/J") as PinJoint2D
	var piece : Object = rope_piece.instantiate() as Object
	
	piece.global_position = joint.global_position
	piece.rotation = spawn_angle
	piece.parent = self
	piece.id = id
	add_child(piece, true)
	joint.node_a = parent.get_path()
	joint.node_b = piece.get_path()
	
	return piece

# for drawing the rope
func update_rope_point() -> void:
	rope_points.clear()
	
	# add every rope piece
	rope_points.append(rope_start_joint.global_position)
	for r in rope_parts:
		rope_points.append( r.global_position )
	rope_points.append(rope_end_joint.global_position)

func _draw() -> void:
	draw_polyline(rope_points, Color.WHITE, 1)
