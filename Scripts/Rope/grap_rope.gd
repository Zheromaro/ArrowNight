extends Node

@export var player_speed: float = 0.5

@onready var rope_interaction: RopeInteraction = $"../RopeInteraction"
@onready var up_remote: RemoteTransform2D = $"../RopeTargetPos/RopeUpPos/UpRemote"
@onready var down_remote: RemoteTransform2D = $"../RopeTargetPos/RopeDownPos/DownRemote"

var target : CharacterBody2D

var player_is_up_rope: bool = true :
	set(value):
		player_is_up_rope = value
		var remote_enable = func (remote: RemoteTransform2D, enable : bool):
			remote.update_position = enable
			remote.update_rotation = enable
			remote.update_scale = enable
		
		if value == true :
			remote_enable.call(down_remote, false)
			target.global_position = up_remote.global_position
			remote_enable.call(up_remote, true)
		else :
			remote_enable.call(up_remote, false)
			target.global_position = down_remote.global_position
			remote_enable.call(down_remote, true)


func _process(delta: float) -> void:
	
	if  rope_interaction.enable == true:
		Grap_rope(delta)
		if player_is_up_rope == false && not target.player_an.is_playing("GrapRope"):
			target.player_an.play("GrapRope")

func on_player_entered(player: CharacterBody2D) -> void:
	if not player.is_in_group("Player"):
		return
	
	player.state = player.states.GRAP
	player.velocity = Vector2.ZERO
	player.on_leave_rope.connect(Leave_rope)
	target = player
	
	# set pos of target on rope
	rope_interaction.target_node.global_position = player.global_position
	rope_interaction.enable = true
	rope_interaction.use_nearest_position()
	rope_interaction.force_snap_to_rope()
	
	# set pos of player on rope
	up_remote.remote_path = player.get_path()
	down_remote.remote_path = player.get_path()
	player_is_up_rope = true

func Grap_rope(delta: float):
	var up_collision    : bool 
	var down_collision  : bool 
	var right_collision : bool 
	var left_collision  : bool 
	var dir := Input.get_vector("Left", "Right", "Up", "Down")
	
	if (right_collision && dir.x > 0) :
		dir.x = 0
	
	if (left_collision  && dir.x < 0) :
		dir.x = 0
	
	if (!up_collision   && dir.y < 0):
		player_is_up_rope = true
	
	if (!down_collision && dir.y > 0):
		player_is_up_rope = false
	
	rope_interaction.rope_position + dir.x * delta
	rope_interaction.force_snap_to_rope()

func Leave_rope():
	rope_interaction.enable = false
