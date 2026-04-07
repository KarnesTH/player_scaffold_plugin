extends RayCast3D
 
@export var interact_input: String = "interact"
 
var _interaction_label: Label = null
 
func _ready() -> void:
	var hud := get_parent().get_node_or_null("HUD")
	if hud:
		_interaction_label = hud.get_node_or_null("Control/VBoxContainer/InteractionLbl")
 
func _process(_delta: float) -> void:
	if not _interaction_label:
		return
	if is_colliding():
		var target := get_collider()
		if target and target.has_method("interact"):
			_interaction_label.visible = true
			_interaction_label.text = target.get("interaction_text") if target.get("interaction_text") else "Press F to interact"
			return
	_interaction_label.visible = false
 
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_input):
		_try_interact()
 
func _try_interact() -> void:
	if not is_colliding():
		return
	var target := get_collider()
	if target and target.has_method("interact"):
		target.interact(owner)
