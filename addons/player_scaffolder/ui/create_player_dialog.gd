@tool
extends AcceptDialog
 
const PRESETS = {
	"Horror": { "sprint": true, "crouch": true, "jump": false, "prone": false, "lean": false, "inventory": true, "health": true, "stamina": false },
	"Survival": { "sprint": true, "crouch": true, "jump": true, "prone": false, "lean": false, "inventory": true, "health": true, "stamina": true },
	"Simulator": { "sprint": true, "crouch": true, "jump": false, "prone": false, "lean": false, "inventory": true, "health": false, "stamina": false },
	"Shooter – Classic": { "sprint": true, "crouch": true, "jump": true, "prone": false, "lean": true, "inventory": false, "health": true, "stamina": false },
	"Shooter – BR/Extraction": { "sprint": true, "crouch": true, "jump": true, "prone": true, "lean": true, "inventory": true, "health": true, "stamina": true },
}
 
@onready var genre_btn: OptionButton = %GerneOBtn
@onready var camera_btn: OptionButton = %CameraTypeOBtn
@onready var sprint_cb: CheckBox = %SprintCB
@onready var crouch_cb: CheckBox = %CrouchCB
@onready var jump_cb: CheckBox = %JumpCB
@onready var prone_cb: CheckBox = %ProneCB
@onready var lean_cb: CheckBox = %LeanCB
@onready var health_cb: CheckBox = %HealthSystemCB
@onready var inventory_cb: CheckBox = %InventoryCB
@onready var stamina_cb: CheckBox = %StaminaCB
@onready var player_name_le: LineEdit = %PlayerNameLE
@onready var target_path_le: LineEdit = %TargetPathLE
@onready var script_path_le: LineEdit = %ScriptPathLE
@onready var status_lbl: Label = %StatusLbl
 
func _ready() -> void:
	if genre_btn.item_count == 0:
		for genre in PRESETS.keys():
			genre_btn.add_item(genre)
		camera_btn.add_item("FPS")
		camera_btn.add_item("Third Person")
		camera_btn.add_item("FPS + TP Toggle")
		genre_btn.item_selected.connect(_on_genre_selected)
	if not canceled.is_connected(hide):
		canceled.connect(hide)
	if not confirmed.is_connected(_on_generate_pressed):
		confirmed.connect(_on_generate_pressed)
	_on_genre_selected(0)
	status_lbl.text = ""
 
func _on_genre_selected(index: int) -> void:
	var preset = PRESETS.values()[index]
	sprint_cb.button_pressed = preset["sprint"]
	crouch_cb.button_pressed = preset["crouch"]
	jump_cb.button_pressed = preset["jump"]
	prone_cb.button_pressed = preset["prone"]
	lean_cb.button_pressed = preset["lean"]
	health_cb.button_pressed = preset["health"]
	inventory_cb.button_pressed = preset["inventory"]
	stamina_cb.button_pressed = preset["stamina"]
 
func _get_config() -> Dictionary:
	return {
		"genre": genre_btn.get_item_text(genre_btn.selected),
		"camera": camera_btn.selected,
		"sprint": sprint_cb.button_pressed,
		"crouch": crouch_cb.button_pressed,
		"jump": jump_cb.button_pressed,
		"prone": prone_cb.button_pressed,
		"lean": lean_cb.button_pressed,
		"health": health_cb.button_pressed,
		"inventory": inventory_cb.button_pressed,
		"stamina": stamina_cb.button_pressed,
		"player_name": player_name_le.text,
		"target_path": target_path_le.text,
		"script_path": script_path_le.text,
	}
 
func _on_generate_pressed() -> void:
	var config = _get_config()
	if config["player_name"].is_empty():
		_set_status("⚠ Player Name cannot be empty.", true)
		return
	if config["target_path"].is_empty():
		_set_status("⚠ Scene Path cannot be empty.", true)
		return
	if config["script_path"].is_empty():
		_set_status("⚠ Script Path cannot be empty.", true)
		return
	PlayerGenerator.generate(config)
	_set_status("✓ Player '%s' created successfully." % config["player_name"], false)
	await get_tree().create_timer(1.5).timeout
	hide()
 
func _set_status(text: String, is_error: bool) -> void:
	status_lbl.text = text
	status_lbl.modulate = Color.RED if is_error else Color.GREEN
