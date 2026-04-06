extends Node

@export var capacity: int = 20

var items: Array[Dictionary] = []

signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)
signal inventory_full

func add_item(item: Dictionary) -> bool:
	if items.size() >= capacity:
		inventory_full.emit()
		return false
	items.append(item)
	item_added.emit(item)
	return true

func remove_item(item: Dictionary) -> bool:
	var index := items.find(item)
	if index == -1:
		return false
	items.remove_at(index)
	item_removed.emit(item)
	return true

func has_item(item_id: String) -> bool:
	return items.any(func(i): return i.get("id") == item_id)

func get_item(item_id: String) -> Dictionary:
	for item in items:
		if item.get("id") == item_id:
			return item
	return {}
