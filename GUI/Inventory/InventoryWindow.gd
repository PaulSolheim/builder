extends MarginContainer

signal inventory_changed(panel, held_item)

var gui: Control

onready var inventory_path := $PanelContainer/MarginContainer/Inventories
onready var inventories := inventory_path.get_children()

func setup(_gui: Control) -> void:
	gui = _gui
	for bar in inventories:
		bar.setup(gui)

# Whenever we receive the 'inventory_changed' signal, bubble up the signal from the inventory bars.
func _on_InventoryBar_inventory_changed(panel, held_item) -> void:
	emit_signal("inventory_changed", panel, held_item)

## Removes the provided quickbar from its current parent and makes it a sibling
## of the other inventory bars.
func claim_quickbar(quickbar: Control) -> void:
	quickbar.get_parent().remove_child(quickbar)
	inventory_path.add_child(quickbar)

## Returns an array of inventory panels that have a held item with a name matching
## the item id from the inventory bars.
func find_panels_with(item_id: String) -> Array:
	var output := []
	for inventory in inventories:
		output += inventory.find_panels_with(item_id)
	
	return output

## Adds the provided item to the first available spaces it can find in the
## inventory bars. Returns true if it succeeds.
func add_to_first_available_inventory(item: BlueprintEntity) -> bool:
	for inventory in inventories:
		if inventory.add_to_first_available_inventory(item):
			return true
	
	return false

