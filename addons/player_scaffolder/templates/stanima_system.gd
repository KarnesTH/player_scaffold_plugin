extends Node

@export var max_stamina: float = 100.0
@export var drain_rate: float = 20.0
@export var regen_rate: float = 10.0
@export var regen_delay: float = 2.0

var stamina: float = max_stamina
var _regen_timer: float = 0.0
var _draining: bool = false

signal stamina_changed(new_stamina: float, max_stamina: float)
signal stamina_depleted

func _process(delta: float) -> void:
	if _draining:
		stamina = clamp(stamina - drain_rate * delta, 0.0, max_stamina)
		stamina_changed.emit(stamina, max_stamina)
		_regen_timer = regen_delay
		if stamina <= 0.0:
			stamina_depleted.emit()
	else:
		if _regen_timer > 0.0:
			_regen_timer -= delta
		else:
			stamina = clamp(stamina + regen_rate * delta, 0.0, max_stamina)
			stamina_changed.emit(stamina, max_stamina)

func set_draining(value: bool) -> void:
	_draining = value

func has_stamina() -> bool:
	return stamina > 0.0
