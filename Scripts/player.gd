extends CharacterBody2D

enum states { RUN, JUMP, FALL, HANGE}

@export_group("Run")
@export var max_speed := 100
@export var acceleration := 50
@export_range(0, 1) var deceleration := 0.2

@export_group("Jump")
@export var jump_peak_time := 0.5
@export var jump_fall_time := 0.5
@export var jump_height := 2.0
@export var jump_distance := 4.0

@onready var jump_velocity : float = -((2.0 * jump_height) / jump_peak_time)                    # physics
@onready var jump_gravity: float = -((-2.0 * jump_height) / pow(jump_peak_time, 2))             # physics
@onready var fall_gravity: float = -((-2.0 * jump_height) / pow(jump_fall_time, 2))             # physics
@onready var air_speed : float  = float(jump_distance) / float(jump_peak_time + jump_fall_time) # physics

@export var coyote_time := 0.2
@export var jump_buffer_time := 0.15
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

var jump_available := false
var can_jump_buffer := false

@export_group("Grap Rope")
@export var rope_hanging_move_speed: float = 0.1
@export var rope_detector: Area2D 
var is_hanging := false
var attached_rope_part_id : int = -INF
var attached_rope : Object = null
var rope_section_progress := 0.0
var attached_rop_face_left := false
var last_pos := Vector2.ZERO

func _physics_process(delta: float) -> void:
	last_pos = position
	
	if is_hanging:
		velocity = Vector2.ZERO
		
		var left = "Left" if attached_rop_face_left else "Right"
		var right = "Left" if !attached_rop_face_left else "Right"
		
		if Input.is_action_pressed(left):
			rope_section_progress -= rope_hanging_move_speed
			if rope_section_progress < 0:
				if attached_rope_part_id > 0:
					rope_section_progress = 1.0
					attached_rope_part_id = clamp( attached_rope_part_id -1, 0, attached_rope.rope_parts.size() -1)
				else:
					rope_section_progress = 0.0
			
		elif Input.is_action_pressed(right):
			rope_section_progress += rope_hanging_move_speed
			if rope_section_progress > 1:
				if attached_rope_part_id < attached_rope.rope_parts.size()-2:
					rope_section_progress = 0.0
					attached_rope_part_id = clamp( attached_rope_part_id +1, 0, attached_rope.rope_parts.size() -1)
				else:
					rope_section_progress = 1.0
		
		global_position = get_player_pos_on_rope()
		
		if Input.is_action_just_pressed("Down"):
			Leave_rope()
		elif Input.is_action_just_pressed("Jump"):
			Leave_rope()
			
			Jump()
			move_and_slide()
		
		return
	
	# /// Jump - Fall
	if not is_on_floor():
		# Add the gravity.
		velocity.y += get_gravity() * delta
		
		# Start coyote timer
		if jump_available and coyote_timer.is_stopped():
			coyote_timer.start(coyote_time)
			coyote_timer.connect("timeout", 
			func(): jump_available = false
			)
	else:
		jump_available = true
		if can_jump_buffer:
			Jump()
			can_jump_buffer = false
	
	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if jump_available:
			Jump()
		else:
			can_jump_buffer = true
			
			jump_buffer_timer.start(jump_buffer_time)
			jump_buffer_timer.connect("timeout", 
			func(): 
				can_jump_buffer = false
			)
	
	# /// Move
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x += direction * acceleration
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration)
	
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
	
	move_and_slide()

func Jump():
	velocity.y = jump_velocity
	jump_available = false

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func get_speed() -> float:
	return max_speed if is_on_floor() else air_speed

# rope
func get_player_pos_on_rope():
	attached_rope.active_rope_id = attached_rope_part_id
	var current_piece_pos = attached_rope.rope_parts[attached_rope_part_id].global_position 
	var next_piece_id = clamp( attached_rope_part_id +1, 0, attached_rope.rope_parts.size() -1)
	var next_piece_pos = attached_rope.rope_parts[next_piece_id].global_position 
	var new_pos = lerp(current_piece_pos, next_piece_pos, rope_section_progress)
	
	new_pos -= rope_detector.position
	return new_pos

func _on_rope_detector_body_entered(body: Node2D) -> void:
	if !is_hanging && body.is_in_group("rope"):
		is_hanging = true
		rope_section_progress = 0.0
		attached_rope_part_id = body.id
		attached_rope = body.parent
		attached_rop_face_left = attached_rope.rope_face_left
		
		# effect when player is atached to the rope
		(body as RigidBody2D).apply_central_impulse((last_pos - position) * 20)

func Leave_rope():
	is_hanging = false
	attached_rope_part_id = -INF
	attached_rope.active_rope_id = -INF
	attached_rope = null
