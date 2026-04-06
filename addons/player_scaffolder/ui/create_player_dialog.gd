@tool
extends AcceptDialog


const PRESETS = {
	"Horror": { "sprint": true, "crouch": true, "jump": false, "prone": false, "inventory": true, "health": true, "stamina": false },
	"Survival": { "sprint": true, "crouch": true, "jump": true, "prone": false, "inventory": true, "health": true, "stamina": true },
	"Simulator": { "sprint": true, "crouch": true, "jump": false, "prone": false, "inventory": true, "health": false, "stamina": false },
	"Shooter – Classic": { "sprint": true, "crouch": true, "jump": true, "prone": false, "inventory": false, "health": true, "stamina": false },
	"Shooter – BR/Extraction": { "sprint": true, "crouch": true, "jump": true, "prone": true, "inventory": true, "health": true, "stamina": true },
}

func _ready() -> void:
	canceled.connect(hide)
	confirmed.connect(_on_generate_pressed)
	for genre in PRESETS.keys():
		$VBoxContainer/GerneOBtn.add_item(genre)
	$VBoxContainer/CameraTypeOBtn.add_item("FPS")
	$VBoxContainer/CameraTypeOBtn.add_item("Third Person")
	$VBoxContainer/CameraTypeOBtn.add_item("FPS + TP Toggle")
	$VBoxContainer/GerneOBtn.connect("item_selected", _on_genre_selected)
	_on_genre_selected(0)

func _on_genre_selected(index: int) -> void:
	var preset = PRESETS.values()[index]
	$VBoxContainer/MovementGC/SprintCB.button_pressed = preset["sprint"]
	$VBoxContainer/MovementGC/CrouchCB.button_pressed = preset["crouch"]
	$VBoxContainer/MovementGC/JumpCB.button_pressed = preset["jump"]
	$VBoxContainer/MovementGC/ProneCB.button_pressed = preset["prone"]
	$VBoxContainer/HealthSystemCB.button_pressed = preset["health"]
	$VBoxContainer/InventoryCB.button_pressed = preset["inventory"]
	$VBoxContainer/StanimaCB.button_pressed = preset["stamina"]

func _get_config() -> Dictionary:
	return {
		"genre": $VBoxContainer/GerneOBtn.get_item_text($VBoxContainer/GerneOBtn.selected),
		"camera": $VBoxContainer/CameraTypeOBtn.selected,
		"sprint": $VBoxContainer/MovementGC/SprintCB.button_pressed,
		"crouch": $VBoxContainer/MovementGC/CrouchCB.button_pressed,
		"jump": $VBoxContainer/MovementGC/JumpCB.button_pressed,
		"prone": $VBoxContainer/MovementGC/ProneCB.button_pressed,
		"health": $VBoxContainer/HealthSystemCB.button_pressed,
		"inventory": $VBoxContainer/InventoryCB.button_pressed,
		"stamina": $VBoxContainer/StanimaCB.button_pressed,
		"player_name": $VBoxContainer/PlayerNameLE.text,
		"target_path": $VBoxContainer/TargetPathLE.text,
		"script_path": $VBoxContainer/ScriptPathLE.text
	}

func _on_generate_pressed() -> void:
	var config = _get_config()
	if config["player_name"].is_empty():
		push_error("Player Scaffolder: Player Name darf nicht leer sein.")
		return
	if config["target_path"].is_empty():
		push_error("Player Scaffolder: Zielpfad darf nicht leer sein.")
		return
	PlayerGenerator.generate(config)
	hide()
	
