extends CharacterBody2D

enum states { GROUNDED, JUMP, FALL, GRAP, SWING}
var state = states.GROUNDED
@onready var player_an: AnimatedSprite2D = $Player_AN
var playing_jump_fall := false

@export_group("Run")
@export var ground_speed := 100
@export var acceleration := 50
@export_range(0, 1) var deceleration := 0.2

@export_group("Jump")
@export var jump_peak_time := 0.5
@export var jump_fall_time := 0.5
@export var jump_height := 2.0 
@export var jump_distance := 4.0
var tilesize := 8

@onready var jump_velocity : float = -((2.0 * jump_height * tilesize) / jump_peak_time)                    # physics
@onready var jump_gravity: float = -((-2.0 * jump_height * tilesize) / pow(jump_peak_time, 2))             # physics
@onready var fall_gravity: float = -((-2.0 * jump_height * tilesize) / pow(jump_fall_time, 2))             # physics
@onready var air_speed : float  = float(jump_distance * tilesize) / float(jump_peak_time + jump_fall_time) # physics

@export var coyote_time := 0.2
@export var jump_buffer_time := 0.15
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

var jump_available := false
var can_jump_buffer := false

@export_group("Grap Rope")
@export var climp_speed: float = 1.0
@export var rope_swing_speed: float = 50.0
@export var _rope_interaction: RopeInteraction
@export var not_effected_by_rope_movement: Array[Node2D]
@export var cast_on_rope: Node2D 

signal on_grap_rope
signal on_swing_rope
signal on_leave_rope

func _physics_process(delta: float) -> void:
	var on_rope := _rope_interaction.enable
	get_children()
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
			
		states.SWING:    # -------------------------------------------------
			Swing_rope(delta)
			
			if Input.is_action_just_pressed("Jump"):
				Leave_rope()
				state = states.JUMP
				return
			
			if _rope_interaction.rope_position == 0.95 && Input.is_action_pressed("Down"):
				Leave_rope()
				state = states.FALL
				return
			
		states.GRAP:    # -------------------------------------------------
			Grap_rope(delta)
			
			if Input.is_action_just_pressed("Jump"):
				Leave_rope()
				state = states.JUMP
				return
			
	
	Move()
	
	move_and_slide()


func Move() -> void:
	var max_speed : float 
	if is_on_floor():
		max_speed = ground_speed
	elif state == states.GRAP:
		max_speed = rope_swing_speed
	else:
		max_speed = air_speed
	
	var h_direction := Input.get_axis("Left", "Right")
	if h_direction:
		velocity.x += h_direction * acceleration
		
		if !playing_jump_fall:
			player_an.play("Run")
		
		if h_direction > 0:
			player_an.flip_h = false
		else:
			player_an.flip_h = true
		
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration)
		if !playing_jump_fall:
			player_an.play("Idel")
	
	velocity.x = clamp(velocity.x, -max_speed, max_speed)

func Jump() -> void:
	velocity.y = jump_velocity
	player_an.play("Jump")
	jump_available = false

func Fall(delta: float) -> void:
	var get_gravity = jump_gravity if velocity.y < 0.0 else fall_gravity
	velocity.y += get_gravity * delta
	
	if get_gravity == fall_gravity:
		player_an.play("Fall")

# ------- rope ------------


func _on_rope_detected(area) -> void:
	
	var shape_generator :=  area.get_node("RopeCollisionShapeGenerator") as RopeCollisionShapeGenerator
	_rope_interaction.rope = shape_generator.get_node(shape_generator.rope_path) as Rope
	_rope_interaction.enable = true
	_rope_interaction.use_nearest_position()
	_rope_interaction.force_snap_to_rope()
	
	
	velocity = Vector2.ZERO
	if area.is_in_group("SwingingRope"):
		state = states.SWING
	elif area.is_in_group("WalkingRope"):
		state = states.GRAP


func Grap_rope(delta: float):
	if (cast_on_rope.is_colliding_right() && Input.is_action_pressed("Right") 
	|| cast_on_rope.is_colliding_left() && Input.is_action_pressed("Left")):
		return
	
	var hdir := Input.get_axis("Right", "Left")
	
	_rope_interaction.rope_position = clamp(_rope_interaction.rope_position + hdir * climp_speed * delta, 0.05, 0.95)
	_rope_interaction.force_snap_to_rope()
	
	on_grap_rope.emit()

func Swing_rope(delta: float):
	var vdir := Input.get_axis("Up", "Down")
	_rope_interaction.rope_position = clamp(_rope_interaction.rope_position + vdir * climp_speed * delta, 0.0, 0.95)
	_rope_interaction.force_snap_to_rope()
	
	
	on_swing_rope.emit()

func Leave_rope():
	velocity += _rope_interaction.get_anchor().get_velocity()
	_rope_interaction.enable = false
	
	on_leave_rope.emit()
