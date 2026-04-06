extends RayCast3D

@export var interact_input: String = "interact"

func _ready() -> void:
	if not InputMap.has_action(interact_input):
		push_warning("PlayerScaffolder: Action '%s' nicht in der InputMap gefunden." % interact_input)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_input):
		_try_interact()

func _try_interact() -> void:
	if not is_colliding():
		return
	var target := get_collider()
	if target and target.has_method("interact"):
		target.interact(owner)
