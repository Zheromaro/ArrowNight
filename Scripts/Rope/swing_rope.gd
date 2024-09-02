extends Node

@export var rope_climp_speed : float = 1
@export var rope_swing_speed : float = 1

@export_group("configuration")
@export var rope_interaction: RopeInteraction 
@export var remote_transform_2d: RemoteTransform2D 

var target : CharacterBody2D

func _physics_process(delta: float) -> void:
	if rope_interaction.enable:
		rope_interaction.force_snap_to_rope()
		Swing_rope(delta)

func on_player_entered(player: CharacterBody2D) -> void:
	player.velocity = Vector2.ZERO
	player.on_leave_rope.connect(func(): 
		rope_interaction.enable = false)
	player.state = player.states.SWING
	
	# set pos of target on rope
	rope_interaction.target_node.global_position = player.global_position
	rope_interaction.enable = true
	rope_interaction.use_nearest_position()
	rope_interaction.force_snap_to_rope()
	
	# set pos of player
	remote_transform_2d.remote_path = player.get_path()

func Swing_rope(delta: float):
	var dir := Input.get_vector("Up", "Down", "Left", "Right")
	
	# up-down movement
	rope_interaction.rope_position = clamp(
		rope_interaction.rope_position + dir.x * rope_climp_speed * delta,
		0, 1
		)
	rope_interaction.force_snap_to_rope()
	
	# left-right movement
	rope_interaction.target_node.position.x += dir.y * rope_swing_speed
	
	

