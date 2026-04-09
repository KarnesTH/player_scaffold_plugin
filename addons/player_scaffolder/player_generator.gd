@tool
## Player Scaffolder - Generator
##
## Generates a genre-based player scene with scripts, input actions and HUD.
##
## @author KarnesTH
## @version 1.1
class_name PlayerGenerator

const DEFAULT_SCENE_PATH = "res://scenes/player/"
const DEFAULT_SCRIPT_PATH = "res://scripts/player/"

## Generates the complete player scene based on the provided config dictionary.
## Creates scene and script directories, writes all scripts, builds the scene tree,
## registers input actions and opens the result in the editor.
static func generate(config: Dictionary) -> void:
	var target_path = config["target_path"]
	if target_path.is_empty():
		target_path = DEFAULT_SCENE_PATH
	if not target_path.ends_with("/"):
		target_path += "/"
	var script_path = config.get("script_path", "")
	if script_path.is_empty():
		script_path = DEFAULT_SCRIPT_PATH
	if not script_path.ends_with("/"):
		script_path += "/"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_path))
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(script_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(script_path))
	_write_script("player_controller", script_path, _build_player_script(config))
	_copy_script("interact", script_path)
	if config["health"]:
		_copy_script("health_system", script_path)
	if config["stamina"]:
		_copy_script("stamina_system", script_path)
	if config["inventory"]:
		_copy_script("inventory", script_path)
	var root := CharacterBody3D.new()
	root.name = config["player_name"]
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.position = Vector3(0, 0.9, 0)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	col.shape = capsule
	root.add_child(col)
	col.owner = root
	var camera_target := Node3D.new()
	camera_target.name = "CameraTarget"
	camera_target.position = Vector3(0, 1.6, 0)
	root.add_child(camera_target)
	camera_target.owner = root
	_setup_camera(root, config["camera"])
	_add_interact(root, script_path)
	if config["health"]:
		_add_node(root, "HealthSystem", script_path)
	if config["inventory"]:
		_add_node(root, "Inventory", script_path)
	if config["stamina"]:
		_add_node(root, "StaminaSystem", script_path)
	_register_inputs(config)
	_build_hud(root)
	EditorInterface.get_resource_filesystem().scan()
	root.set_script(load(script_path + "player_controller.gd"))
	var packed := PackedScene.new()
	packed.pack(root)
	var file_path = target_path + config["player_name"].to_snake_case() + ".tscn"
	ResourceSaver.save(packed, file_path)
	EditorInterface.open_scene_from_path(file_path)
	print("Player Scaffolder: Scene generated → ", file_path)
 
## Writes a generated script string to disk. Skips if the file already exists.
static func _write_script(script_name: String, target_path: String, content: String) -> void:
	var dst = target_path + "%s.gd" % script_name
	if not FileAccess.file_exists(dst):
		var file := FileAccess.open(dst, FileAccess.WRITE)
		file.store_string(content)
		file.close()
 
## Copies a template script from the addon to the target path. Skips if already exists.
static func _copy_script(script_name: String, target_path: String) -> void:
	var src = "res://addons/player_scaffolder/templates/%s.gd" % script_name
	var dst = target_path + "%s.gd" % script_name
	if not FileAccess.file_exists(dst):
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(src),
			ProjectSettings.globalize_path(dst)
		)
 
## Adds camera nodes to the player root based on camera_type.
## 0 = FPS, 1 = Third Person, 2 = FPS + TP Toggle.
static func _setup_camera(root: Node, camera_type: int) -> void:
	match camera_type:
		0: # FPS
			var cam := Camera3D.new()
			cam.name = "Camera3D"
			cam.position = Vector3(0, 1.6, 0)
			cam.current = true
			root.add_child(cam)
			cam.owner = root
		1: # Third Person
			var arm := SpringArm3D.new()
			arm.name = "SpringArm3D"
			arm.unique_name_in_owner = true
			arm.position = Vector3(0, 1.6, 0)
			root.add_child(arm)
			arm.owner = root
			var cam := Camera3D.new()
			cam.name = "ThirdPersonCamera"
			cam.unique_name_in_owner = true
			arm.add_child(cam)
			cam.owner = root
		2: # FPS + TP Toggle
			var fps_cam := Camera3D.new()
			fps_cam.name = "Camera3D"
			fps_cam.current = true
			fps_cam.position = Vector3(0, 1.6, 0)
			root.add_child(fps_cam)
			fps_cam.owner = root
			var arm := SpringArm3D.new()
			arm.name = "SpringArm3D"
			arm.unique_name_in_owner = true
			arm.position = Vector3(0, 1.6, 0)
			root.add_child(arm)
			arm.owner = root
			var tp_cam := Camera3D.new()
			tp_cam.name = "ThirdPersonCamera"
			tp_cam.unique_name_in_owner = true
			arm.add_child(tp_cam)
			tp_cam.owner = root
 
## Adds an InteractRay (RayCast3D) node with the interact script attached.
static func _add_interact(root: Node, script_path: String) -> void:
	var ray := RayCast3D.new()
	ray.name = "InteractRay"
	ray.position = Vector3(0, 1.6, 0)
	ray.target_position = Vector3(0, 0, -2.0)
	root.add_child(ray)
	ray.owner = root
	ray.set_script(load(script_path + "interact.gd"))
 
## Adds a generic Node with the matching script from script_path if it exists.
static func _add_node(root: Node, node_name: String, script_path: String) -> void:
	var node := Node.new()
	node.name = node_name
	var path = script_path + "%s.gd" % node_name.to_snake_case()
	if ResourceLoader.exists(path):
		node.set_script(load(path))
	root.add_child(node)
	node.owner = root
 
## Registers all required input actions into ProjectSettings based on config.
## Saves project.godot and reloads the InputMap immediately.
static func _register_inputs(config: Dictionary) -> void:
	var is_shooter: bool = config["genre"].begins_with("Shooter")
	var actions: Dictionary = {
		"move_forward": { "key": KEY_W },
		"move_back": { "key": KEY_S },
		"move_left": { "key": KEY_A },
		"move_right": { "key": KEY_D },
		"interact": { "key": KEY_F },
	}
	if config["sprint"]:
		actions["sprint"] = { "key": KEY_SHIFT }
	if config["crouch"]:
		actions["crouch"] = { "key": KEY_C }
	if config["jump"]:
		actions["jump"] = { "key": KEY_SPACE }
	if config["prone"]:
		actions["prone"] = { "key": KEY_Z }
	if config["lean"]:
		actions["lean_left"] = { "key": KEY_Q }
		actions["lean_right"] = { "key": KEY_E }
	if config["camera"] == 2:
		actions["toggle_view"] = { "key": KEY_V }
		if not is_shooter:
			actions["zoom_in"] = { "mouse": MOUSE_BUTTON_WHEEL_UP }
			actions["zoom_out"] = { "mouse": MOUSE_BUTTON_WHEEL_DOWN }
	for action in actions:
		if ProjectSettings.has_setting("input/" + action):
			continue
		var event
		if actions[action].has("key"):
			event = InputEventKey.new()
			event.device = -1
			event.physical_keycode = actions[action]["key"]
		else:
			event = InputEventMouseButton.new()
			event.device = -1
			event.button_index = actions[action]["mouse"]
		ProjectSettings.set_setting("input/" + action, {
			"deadzone": 0.2,
			"events": [event]
		})
	ProjectSettings.save()
	InputMap.load_from_project_settings()
	print("Player Scaffolder: Input actions have been registered — it is recommended that you restart the editor so that they appear in the Input Map Editor.")
 
## Builds the HUD scene tree (CanvasLayer → Control → VBoxContainer → Crosshair + InteractionLbl)
## and attaches it as a child of the player root.
static func _build_hud(root: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	root.add_child(canvas)
	canvas.owner = root
	var control := Control.new()
	control.name = "Control"
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(control)
	control.owner = root
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(vbox)
	vbox.owner = root
	var crosshair := Panel.new()
	crosshair.name = "Crosshair"
	crosshair.custom_minimum_size = Vector2(6, 6)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	crosshair.add_theme_stylebox_override("panel", style)
	vbox.add_child(crosshair)
	crosshair.owner = root
	var interaction_lbl := Label.new()
	interaction_lbl.name = "InteractionLbl"
	interaction_lbl.text = ""
	interaction_lbl.visible = false
	interaction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(interaction_lbl)
	interaction_lbl.owner = root

## Dynamically builds the player_controller.gd script content as a String
## based on the config flags. Only includes code for enabled features.
static func _build_player_script(config: Dictionary) -> String:
	var is_shooter: bool = config["genre"].begins_with("Shooter")
	var has_tp: bool = config["camera"] == 2
	var has_zoom := has_tp and not is_shooter
	var s := ""
	s += "## Player Controller\n"
	s += "##\n"
	s += "## Generated by Player Scaffolder. Handles movement, camera, and interaction.\n"
	s += "## Extend this script to add game-specific behaviour.\n"
	s += "##\n"
	s += "## @author KarnesTH\n"
	s += "## @version 1.0\n"
	s += "extends CharacterBody3D\n\n"
	s += "@export_category(\"Movement\")\n"
	s += "@export var base_speed := 6.0\n"
	if config["sprint"]:
		s += "@export var sprint_multiplier := 1.5\n"
	if config["crouch"]:
		s += "@export var crouch_speed_multiplier := 0.5\n"
	if config["prone"]:
		s += "@export var prone_speed_multiplier := 0.3\n"
	if config["jump"]:
		s += "@export var jump_height := 1.2\n"
		s += "@export var fall_multiplier := 2.5\n"
	s += "@export var step_height := 0.3\n"
	s += "\n@export_category(\"Camera\")\n"
	s += "@export var mouse_sensitivity: float = 0.00075\n"
	s += "@export var camera_speed: float = 30.0\n"
	s += "@export var pitch_min: float = -90.0\n"
	s += "@export var pitch_max: float = 90.0\n"
	if config["lean"]:
		s += "@export var lean_angle: float = 15.0\n"
		s += "@export var lean_offset: float = 0.3\n"
		s += "@export var lean_speed: float = 8.0\n"
	if has_zoom:
		s += "\n@export_category(\"Third Person\")\n"
		s += "@export var zoom_min: float = 1.5\n"
		s += "@export var zoom_max: float = 6.0\n"
		s += "@export var zoom_sensitivity: float = 0.4\n"
	s += "\nvar gravity: float = ProjectSettings.get_setting(\"physics/3d/default_gravity\")\n"
	s += "var _look := Vector2.ZERO\n"
	if config["lean"]:
		s += "var _lean_amount: float = 0.0\n"
	if config["crouch"]:
		s += "var _is_crouching := false\n"
	if config["prone"]:
		s += "var _is_prone := false\n"
	if has_tp:
		s += "\nenum VIEW { FIRST_PERSON, THIRD_PERSON }\n"
		s += "var view := VIEW.FIRST_PERSON\n"
		s += "var _has_tp := false\n"
		s += "var spring_arm: SpringArm3D = null\n"
		s += "var third_person_camera: Camera3D = null\n"
	if has_zoom:
		s += "var zoom := zoom_min\n"
	s += "\n@onready var camera: Camera3D = $Camera3D\n"
	s += "@onready var camera_target: Node3D = $CameraTarget\n"
	s += "\n## Called when the node enters the scene tree. Sets mouse to captured mode.\n"
	s += "func _ready() -> void:\n"
	s += "\tInput.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)\n"
	if has_tp:
		s += "\tif has_node(\"%SpringArm3D\") and has_node(\"%ThirdPersonCamera\"):\n"
		s += "\t\tspring_arm = %SpringArm3D\n"
		s += "\t\tthird_person_camera = %ThirdPersonCamera\n"
		s += "\t\t_has_tp = true\n"
	s += "\n## Smoothly interpolates the camera to follow the camera target each frame.\n"
	s += "func _process(delta: float) -> void:\n"
	s += "\tcamera.global_transform = camera.global_transform.interpolate_with(\n"
	s += "\t\tcamera_target.global_transform, clamp(camera_speed * delta, 0.0, 1.0))\n"
	s += "\tcamera.global_position = camera_target.global_position\n"
	s += "\n## Handles movement, gravity, jumping, crouching, prone and step logic each physics tick.\n"
	s += "func _physics_process(delta: float) -> void:\n"
	s += "\t_apply_camera_rotation()\n"
	if has_zoom:
		s += "\tif _has_tp:\n"
		s += "\t\t_smooth_zoom(delta)\n"
	if config["jump"]:
		s += "\tif not is_on_floor():\n"
		s += "\t\tif velocity.y >= 0 and Input.is_action_pressed(\"ui_accept\"):\n"
		s += "\t\t\tvelocity.y -= gravity * delta\n"
		s += "\t\telse:\n"
		s += "\t\t\tvelocity.y -= gravity * delta * fall_multiplier\n"
		s += "\tif Input.is_action_just_pressed(\"jump\") and is_on_floor():\n"
		s += "\t\tvelocity.y = sqrt(jump_height * 2.0 * gravity)\n"
	else:
		s += "\tif not is_on_floor():\n"
		s += "\t\tvelocity.y -= gravity * delta\n"
	s += "\t_check_step()\n"
	if config["lean"]:
		s += "\t_handle_lean(delta)\n"
	s += "\tvar direction := _get_movement_direction()\n"
	if config["sprint"] or config["crouch"] or config["prone"]:
		s += "\tvar speed := base_speed\n"
		if config["sprint"]:
			s += "\tif Input.is_action_pressed(\"sprint\"): speed *= sprint_multiplier\n"
		if config["crouch"]:
			s += "\tif _is_crouching: speed *= crouch_speed_multiplier\n"
		if config["prone"]:
			s += "\tif _is_prone: speed *= prone_speed_multiplier\n"
	else:
		s += "\tvar speed := base_speed\n"
	s += "\tif direction:\n"
	s += "\t\tvelocity.x = lerp(velocity.x, direction.x * speed, speed * delta)\n"
	s += "\t\tvelocity.z = lerp(velocity.z, direction.z * speed, speed * delta)\n"
	s += "\telse:\n"
	s += "\t\tvelocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)\n"
	s += "\t\tvelocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)\n"
	if config["crouch"]:
		s += "\tif Input.is_action_just_pressed(\"crouch\"):\n"
		s += "\t\t_toggle_crouch()\n"
	if config["prone"]:
		s += "\tif Input.is_action_just_pressed(\"prone\"):\n"
		s += "\t\t_toggle_prone()\n"
	s += "\tmove_and_slide()\n"
	s += "\n## Returns the locally oriented movement direction based on input.\n"
	s += "func _get_movement_direction() -> Vector3:\n"
	s += "\tvar input_dir := Input.get_vector(\"move_left\", \"move_right\", \"move_forward\", \"move_back\")\n"
	s += "\treturn (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()\n"
	s += "\n## Applies mouse look rotation to the player and camera target.\n"
	s += "func _apply_camera_rotation() -> void:\n"
	s += "\trotate_y(_look.x)\n"
	s += "\tcamera_target.rotate_x(_look.y)\n"
	s += "\tcamera_target.rotation.x = clamp(camera_target.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))\n"
	s += "\t_look = Vector2.ZERO\n"
	if config["crouch"]:
		s += "\n## Toggles crouch state, adjusting CollisionShape and camera height.\n"
		s += "func _toggle_crouch() -> void:\n"
		s += "\t_is_crouching = not _is_crouching\n"
		s += "\tvar col := $CollisionShape3D\n"
		s += "\tvar capsule := col.shape as CapsuleShape3D\n"
		s += "\tif _is_crouching:\n"
		s += "\t\tcapsule.height = 1.0\n"
		s += "\t\tcol.position.y = 0.5\n"
		s += "\t\tcamera_target.position.y = 0.9\n"
		s += "\telse:\n"
		s += "\t\tcapsule.height = 1.8\n"
		s += "\t\tcol.position.y = 0.9\n"
		s += "\t\tcamera_target.position.y = 1.6\n"
	if config["prone"]:
		s += "\n## Toggles prone state, adjusting CollisionShape and camera height.\n## Exits crouch first if active.\n"
		s += "func _toggle_prone() -> void:\n"
		if config["crouch"]:
			s += "\tif _is_crouching:\n"
			s += "\t\t_toggle_crouch()\n"
		s += "\t_is_prone = not _is_prone\n"
		s += "\tvar col := $CollisionShape3D\n"
		s += "\tvar capsule := col.shape as CapsuleShape3D\n"
		s += "\tif _is_prone:\n"
		s += "\t\tcapsule.height = 0.5\n"
		s += "\t\tcol.position.y = 0.25\n"
		s += "\t\tcamera_target.position.y = 0.3\n"
		s += "\telse:\n"
		s += "\t\tcapsule.height = 1.8\n"
		s += "\t\tcol.position.y = 0.9\n"
		s += "\t\tcamera_target.position.y = 1.6\n"
	s += "\n## Checks for small steps ahead and nudges the player upward to climb them.\n## Only active when on the floor and moving.\n"
	s += "func _check_step() -> void:\n"
	s += "\tif velocity.length() < 0.1 or not is_on_floor():\n"
	s += "\t\treturn\n"
	s += "\tvar forward := -global_transform.basis.z.normalized()\n"
	s += "\tvar step_origin := global_position + forward * 0.4\n"
	s += "\tvar space := get_world_3d().direct_space_state\n"
	s += "\tvar ray_down := PhysicsRayQueryParameters3D.create(\n"
	s += "\t\tstep_origin + Vector3.UP * step_height,\n"
	s += "\t\tstep_origin + Vector3.DOWN * 0.05,\n"
	s += "\t\tcollision_mask\n"
	s += "\t)\n"
	s += "\tray_down.exclude = [self]\n"
	s += "\tvar hit := space.intersect_ray(ray_down)\n"
	s += "\tif hit:\n"
	s += "\t\tvar step_y: float = hit.position.y - global_position.y\n"
	s += "\t\tif step_y > 0.01 and step_y <= step_height:\n"
	s += "\t\t\tglobal_position.y += step_y\n"
	s += "\n"
	if config["lean"]:
		s += "\n## Handles camera lean left/right via Q and E. Disabled while prone.\n"
		s += "func _handle_lean(delta: float) -> void:\n"
		if config["prone"]:
			s += "\tif _is_prone:\n"
			s += "\t\t_lean_amount = move_toward(_lean_amount, 0.0, lean_speed * delta)\n"
			s += "\t\tcamera_target.rotation.z = deg_to_rad(_lean_amount)\n"
			s += "\t\tcamera_target.position.x = _lean_amount / lean_angle * lean_offset\n"
			s += "\t\treturn\n"
		s += "\tvar target_lean := 0.0\n"
		s += "\tif Input.is_action_pressed(\"lean_left\"): target_lean = lean_angle\n"
		s += "\telif Input.is_action_pressed(\"lean_right\"): target_lean = -lean_angle\n"
		s += "\t_lean_amount = lerp(_lean_amount, target_lean, lean_speed * delta)\n"
		s += "\tcamera_target.rotation.z = deg_to_rad(_lean_amount)\n"
		s += "\tcamera_target.position.x = _lean_amount / lean_angle * lean_offset\n"
		s += "\n"
	if has_zoom:
		s += "\n## Smoothly interpolates the SpringArm3D length for third person zoom.\n"
		s += "func _smooth_zoom(delta: float) -> void:\n"
		s += "\tspring_arm.spring_length = lerp(spring_arm.spring_length, zoom, delta * 10.0)\n"
	if has_tp:
		s += "\n## Toggles between first and third person camera view.\n"
		s += "func _cycle_view() -> void:\n"
		s += "\tmatch view:\n"
		s += "\t\tVIEW.FIRST_PERSON:\n"
		s += "\t\t\tview = VIEW.THIRD_PERSON\n"
		if has_zoom:
			s += "\t\t\tzoom = lerp(zoom_min, zoom_max, 0.5)\n"
		s += "\t\t\tif _has_tp:\n"
		s += "\t\t\t\tthird_person_camera.fov = get_viewport().get_camera_3d().fov\n"
		s += "\t\t\t\tthird_person_camera.current = true\n"
		s += "\t\tVIEW.THIRD_PERSON:\n"
		s += "\t\t\tview = VIEW.FIRST_PERSON\n"
		s += "\t\t\tcamera.fov = get_viewport().get_camera_3d().fov\n"
		s += "\t\t\tcamera.current = true\n"
	s += "\n## Handles mouse look, escape to release mouse, view toggle and zoom input.\n"
	s += "func _unhandled_input(event: InputEvent) -> void:\n"
	s += "\tif event is InputEventMouseMotion:\n"
	s += "\t\tif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:\n"
	s += "\t\t\t_look = -event.relative * mouse_sensitivity\n"
	s += "\tif event.is_action_pressed(\"ui_cancel\"):\n"
	s += "\t\tif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:\n"
	s += "\t\t\tInput.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)\n"
	s += "\t\telse:\n"
	s += "\t\t\tInput.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)\n"
	if has_tp:
		s += "\tif _has_tp and event.is_action_pressed(\"toggle_view\"):\n"
		s += "\t\t_cycle_view()\n"
	if has_zoom:
		s += "\tif _has_tp:\n"
		s += "\t\tif event.is_action_pressed(\"zoom_in\"):\n"
		s += "\t\t\tzoom -= zoom_sensitivity\n"
		s += "\t\telif event.is_action_pressed(\"zoom_out\"):\n"
		s += "\t\t\tzoom += zoom_sensitivity\n"
	return s
