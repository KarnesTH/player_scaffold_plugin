## Inventory System
##
## Simple slot-based inventory backed by an Array of Dictionaries.
## Each item is a Dictionary with at minimum an "id" key.
## Connect [signal item_added] or [signal item_removed] to update the UI.
##
## @author KarnesTH
## @version 1.0
extends Node

@export var capacity: int = 20
 
var items: Array[Dictionary] = []
 
## Emitted when an item is successfully added.
signal item_added(item: Dictionary)
## Emitted when an item is successfully removed.
signal item_removed(item: Dictionary)
## Emitted when an item cannot be added because the inventory is full.
signal inventory_full
 
## Adds an item to the inventory. Returns false if at capacity.
func add_item(item: Dictionary) -> bool:
	if items.size() >= capacity:
		inventory_full.emit()
		return false
	items.append(item)
	item_added.emit(item)
	return true
 
## Removes an item from the inventory. Returns false if not found.
func remove_item(item: Dictionary) -> bool:
	var index := items.find(item)
	if index == -1:
		return false
	items.remove_at(index)
	item_removed.emit(item)
	return true
 
## Returns true if an item with the given id exists in the inventory.
func has_item(item_id: String) -> bool:
	return items.any(func(i): return i.get("id") == item_id)
 
## Returns the first item matching the given id, or an empty Dictionary if not found.
func get_item(item_id: String) -> Dictionary:
	for item in items:
		if item.get("id") == item_id:
			return item
	return {}
