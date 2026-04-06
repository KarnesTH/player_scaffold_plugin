extends CharacterBody3D

@export var base_speed := 6.0
@export var sprint_multiplier := 1.5

@export_category("Camera")
@export var mouse_sensitivity: float = 0.00075
@export var camera_speed: float = 30.0
@export var pitch_min: float = -90.0
@export var pitch_max: float = 90.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _look := Vector2.ZERO
var _is_crouching := false

@onready var camera: Camera3D = $Camera3D
@onready var camera_target: Node3D = $CameraTarget

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	camera.global_transform = camera.global_transform.interpolate_with(
		camera_target.global_transform, clamp(camera_speed * delta, 0.0, 1.0))
	camera.global_position = camera_target.global_position

func _physics_process(delta: float) -> void:
	_apply_camera_rotation()
	if not is_on_floor():
		velocity.y -= gravity * delta
	var direction := _get_movement_direction()
	var speed := base_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)
	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, speed * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, speed * delta * 5.0)
	if Input.is_action_just_pressed("crouch"):
		_toggle_crouch()
	move_and_slide()

func _get_movement_direction() -> Vector3:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func _apply_camera_rotation() -> void:
	rotate_y(_look.x)
	camera_target.rotate_x(_look.y)
	camera_target.rotation.x = clamp(camera_target.rotation.x, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
	_look = Vector2.ZERO

func _toggle_crouch() -> void:
	_is_crouching = not _is_crouching
	pass # TODO: CollisionShape anpassen + Camera senken

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			_look = -event.relative * mouse_sensitivity
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
