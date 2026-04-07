@tool
extends EditorPlugin

var dialog


func _enter_tree() -> void:
	add_tool_menu_item("Player Scaffolder/Create Player...", _on_menu_pressed)

func _exit_tree() -> void:
	remove_tool_menu_item("Player Scaffolder/Create Player...")
	if dialog:
		dialog.queue_free()

func _on_menu_pressed() -> void:
	if not dialog:
		dialog = preload("res://addons/player_scaffolder/ui/create_player_dialog.tscn").instantiate()
		get_editor_interface().get_base_control().add_child(dialog)
	dialog.popup_centered()
