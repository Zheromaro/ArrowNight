extends CharacterBody2D

enum states { GROUNDED, JUMP, FALL, HANGE}
var state = states.GROUNDED
@onready var player_an: AnimatedSprite2D = $Player_AN
var playing_jump_fall := false

@export_group("Run")
@export var max_speed := 100
@export var acceleration := 50
@export_range(0, 1) var deceleration := 0.2

@export_group("Jump")
@export var jump_peak_time := 0.5
@export var jump_fall_time := 0.5
@export var jump_height := 2.0 :
	set(value):
		jump_height = value * 8
		print("jump_height :" + str(jump_height))
@export var jump_distance := 4.0:
	set(value):
		jump_distance = value * 8
		print("jump_distance :" + str(jump_distance))

@onready var jump_velocity : float = -((2.0 * jump_height) / jump_peak_time)                    # physics
@onready var jump_gravity: float = -((-2.0 * jump_height) / pow(jump_peak_time, 2))             # physics
@onready var fall_gravity: float = -((-2.0 * jump_height) / pow(jump_fall_time, 2))             # physics
@onready var air_speed : float  = float(jump_distance) / float(jump_peak_time + jump_fall_time)            # physics

@export var coyote_time := 0.2
@export var jump_buffer_time := 0.15
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

var jump_available := false
var can_jump_buffer := false

@export_group("Grap Rope")
@export var rope_hanging_move_speed: float = 0.1
@export var rope_detector_head: Area2D 
@export var rope_detector_legs: Area2D 
@export var cast_ground_on_rope: RayCast2D 

var attached_rope_part_id : int = -INF
var attached_rope : Object = null
var rope_section_progress := 0.0
var attached_rop_face_left := false
var last_pos := Vector2.ZERO

func _physics_process(delta: float) -> void:
	last_pos = position
	
	match state:
		states.GROUNDED: # -------------------------------------------------
			jump_available = true
			playing_jump_fall = false
			
			
			if !is_on_floor():
				state = states.FALL
			
			if Input.is_action_just_pressed("Jump") && jump_available:
					state = states.JUMP
			
		states.JUMP:     # -------------------------------------------------
			Jump()
			playing_jump_fall = true
			
			state = states.FALL
			
		states.FALL:     # -------------------------------------------------
			Fall(delta)
			playing_jump_fall = true
			
			
			# -- Start coyote timer --
			if jump_available and coyote_timer.is_stopped():
				coyote_timer.start(coyote_time)
				coyote_timer.connect("timeout", 
				func(): jump_available = false
				)
			
			if Input.is_action_just_pressed("Jump"):
				if jump_available:
					state = states.JUMP
				else:
					# -- Start jump buffer timer --
					can_jump_buffer = true
					
					jump_buffer_timer.start(jump_buffer_time)
					jump_buffer_timer.connect("timeout", 
					func(): 
						can_jump_buffer = false
					)
			
			if is_on_floor():
				if can_jump_buffer:
					can_jump_buffer = false
					state = states.JUMP
				else:
					state = states.GROUNDED
			
		states.HANGE:    # -------------------------------------------------
			Grap_rope()
			
			if cast_ground_on_rope.is_colliding():
				Leave_rope()
				state = states.GROUNDED
				return
			
			if Input.is_action_just_pressed("Down"):
				Leave_rope()
				state = states.FALL
				return
			
			if Input.is_action_just_pressed("Jump"):
				Leave_rope()
				state = states.JUMP
				return
	
	if state != states.HANGE:
		Move()
	
	move_and_slide()
	

func Move() -> void:
	var speed = max_speed if is_on_floor() else air_speed
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x += direction * acceleration
		
		if !playing_jump_fall:
			player_an.play("Run")
		
		if direction > 0:
			player_an.flip_h = false
		else:
			player_an.flip_h = true
		
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration)
		if !playing_jump_fall:
			player_an.play("Idel")
	
	velocity.x = clamp(velocity.x, -speed, speed)

func Jump() -> void:
	velocity.y = jump_velocity
	player_an.play("Jump")
	jump_available = false

func Fall(delta: float) -> void:
	var get_gravity = jump_gravity if velocity.y < 0.0 else fall_gravity
	velocity.y += get_gravity * delta
	
	if get_gravity == fall_gravity:
		player_an.play("Fall")

# rope

func _on_rope_detector_body_entered(body: Node2D) -> void:
	if state != states.HANGE && state != states.GROUNDED && body.is_in_group("rope"):
		state = states.HANGE
		rope_section_progress = 0.0
		attached_rope_part_id = body.id
		attached_rope = body.parent
		attached_rop_face_left = attached_rope.rope_face_left
		
		# effect the rope when player is atached to it
		(body as RigidBody2D).apply_central_impulse((last_pos - position) * 20)

func Grap_rope():
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
	
	# Get player position on rope
	attached_rope.active_rope_id = attached_rope_part_id
	var current_piece_pos = attached_rope.rope_parts[attached_rope_part_id].global_position 
	var next_piece_id = clamp( attached_rope_part_id +1, 0, attached_rope.rope_parts.size() -1)
	var next_piece_pos = attached_rope.rope_parts[next_piece_id].global_position 
	var new_pos = lerp(current_piece_pos, next_piece_pos, rope_section_progress)
	
	global_position = new_pos

func Leave_rope():
	attached_rope_part_id = -INF
	attached_rope.active_rope_id = -INF
	attached_rope = null
