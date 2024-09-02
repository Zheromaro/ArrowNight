extends Node

@export var player_speed: float = 0.5

@onready var rope_interaction: RopeInteraction = $"../RopeInteraction"
@onready var up_remote: RemoteTransform2D = $"../RopeTargetPos/RopeUpPos/UpRemote"
@onready var down_remote: RemoteTransform2D = $"../RopeTargetPos/RopeDownPos/DownRemote"

@onready var up_cast: ShapeCast2D = $"../RopeTargetPos/RopeUpPos/UpCast"
@onready var up_right_cast: ShapeCast2D = $"../RopeTargetPos/RopeUpPos/UpRightCast"
@onready var up_left_cast: ShapeCast2D = $"../RopeTargetPos/RopeUpPos/UpLeftCast"
@onready var down_cast: ShapeCast2D = $"../RopeTargetPos/RopeDownPos/DownCast"
@onready var down_right_cast: ShapeCast2D = $"../RopeTargetPos/RopeDownPos/DownRightCast"
@onready var down_left_cast: ShapeCast2D = $"../RopeTargetPos/RopeDownPos/DownLeftCast"

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
	print(owner.name + "'s player_is_up_rope = " + str(player_is_up_rope))
	
	if  rope_interaction.enable == true:
		rope_interaction.force_snap_to_rope()
		Grap_rope(delta)

func on_player_entered(player: CharacterBody2D) -> void:
	if not player.is_in_group("Player"):
		return
	
	player.state = player.states.GRAP
	player.velocity = Vector2.ZERO
	player.on_leave_rope.connect(Leave_rope)
	target = player
	
	# set cast exception
	up_cast.add_exception(player)
	up_left_cast.add_exception(player)
	up_right_cast.add_exception(player)
	down_cast.add_exception(player)
	down_left_cast.add_exception(player)
	down_right_cast.add_exception(player)
	
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
	var up_collision    : bool = up_cast.is_colliding()
	var down_collision  : bool = down_cast.is_colliding()
	var right_collision : bool = up_right_cast.is_colliding() if player_is_up_rope else down_right_cast.is_colliding()
	var left_collision  : bool = up_left_cast.is_colliding() if player_is_up_rope else down_left_cast.is_colliding()
	
	if (!right_collision && Input.is_action_pressed("Right") 
	|| !left_collision && Input.is_action_pressed("Left")):
		# move right & left
		var hdir := Input.get_axis("Right", "Left")
		rope_interaction.rope_position = clamp(rope_interaction.rope_position + hdir * player_speed * delta, 0.05, 0.95)
	
	
	if (!up_collision && Input.is_action_pressed("Up") 
	|| !down_collision && Input.is_action_pressed("Down")):
		if Input.is_action_just_pressed("Up"):
			player_is_up_rope = true
		elif Input.is_action_just_pressed("Down") && player_is_up_rope:
			player_is_up_rope = false
		elif Input.is_action_just_pressed("Down") && !player_is_up_rope:
			target.state = target.states.FALL
			target.on_leave_rope.emit()

func Leave_rope():
	rope_interaction.enable = false
