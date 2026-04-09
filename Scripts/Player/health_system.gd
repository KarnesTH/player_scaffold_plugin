## Health System
##
## Manages the player's health. Emits signals on damage, healing and death.
## Connect [signal health_changed] to a UI element to display current health.
##
## @author KarnesTH
## @version 1.0
extends Node

@export var max_health: float = 100.0

var health: float = max_health

## Emitted when health reaches zero.
signal died
## Emitted whenever health changes. Passes current and max health.
signal health_changed(new_health: float, max_health: float)

## Called when the node enters the scene tree. Sets health to max.
func _ready() -> void:
	health = max_health

## Applies damage to the player. Clamps health to zero and emits [signal died] if depleted.
func take_damage(amount: float) -> void:
	health = clamp(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()

## Restores health up to max_health.
func heal(amount: float) -> void:
	health = clamp(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)

## Returns true if health is above zero.
func is_alive() -> bool:
	return health > 0.0
