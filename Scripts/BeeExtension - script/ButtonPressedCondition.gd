extends ConditionLeaf

@export var button_name : StringName 

func tick(actor: Node, blackboard: Blackboard) -> int:
	if Input.is_action_just_pressed(button_name):
		return SUCCESS
	
	return FAILURE

