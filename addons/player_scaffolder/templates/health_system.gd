extends Node

@export var max_health: float = 100.0

var health: float = max_health

signal died
signal health_changed(new_health: float, max_health: float)

func _ready() -> void:
	health = max_health

func take_damage(amount: float) -> void:
	health = clamp(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	health = clamp(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)

func is_alive() -> bool:
	return health > 0.0
