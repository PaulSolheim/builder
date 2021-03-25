class_name InventoryBar
extends HBoxContainer

export var InventoryPanelScene: PackedScene
export var slot_count := 10

## A textual representation of the possible items or categories of items the
## panels can accept, separated by spaces.
export var item_filters := ""
## The list split into an array of names. The second parameter prevents us from
## having empty strings ("") in the array.
onready var _filter_list := item_filters.split(" ", false)

signal inventory_changed(panel, held_item)

var panels := []
var setup := false

func _ready() -> void:
	_make_panels()

func _make_panels() -> void:
	for _i in slot_count:
		var panel := InventoryPanelScene.instance()
		add_child(panel)
		panels.append(panel)

func setup(gui: Control) -> void:
	if setup:
		return
	
	setup = true
	
	# For each panel we've created in '_ready()', we forward the reference to the gui node
	# and connect to their signal.
	for panel in panels:
		panel.setup(gui, _filter_list)
		panel.connect("held_item_changed", self, "_on_Panel_held_item_changed")

# Bubbles up the signal from the inventory bar up to the inventory window.
func _on_Panel_held_item_changed(panel: Control, held_item: BlueprintEntity) -> void:
	emit_signal("inventory_changed", panel, held_item)

## Returns an array of inventory panels that have a held item that have a name that
## matches the item id provided.
func find_panels_with(item_id: String) -> Array:
	var output := []
	for panel in panels:
		# Check if there is an item and its name matches.
		if panel.held_item and Library.get_entity_name_from(panel.held_item) == item_id:
			output.push_back(panel)
			
	return output

## Tries to add the provided item to the first available empty space. Returns
## true if it succeeds.
func add_to_first_available_inventory(item: BlueprintEntity) -> bool:
	var item_name := Library.get_entity_name_from(item)
	
	# We provide the filter list and the name of the item to a special function
	# in `Library` to report on whether this is a valid item for the bar.
	if not Library.is_valid_filter(_filter_list, item_name):
		return false
	
	for panel in panels:
		# If the panel already has an item and its name matches that of the item
		# we are trying to put in it, _and_ there is space for it, we merge the
		# stacks.
		if(
			panel.held_item
			and Library.get_entity_name_from(panel.held_item) == item_name
			and panel.held_item.stack_count < panel.held_item.stack_size
		):
			var available_space: int = panel.held_item.stack_size - panel.held_item.stack_count
			# If there is not enough space, we reduce the item count by however
			# many we can fit onto it, then move on to the next panel.
			if item.stack_count > available_space:
				# var transfer_count := item.stack_count - available_space
				panel.held_item.stack_count += available_space
				item.stack_count -= available_space
			# If there is enough space, we increment the stack, destroy the item, and 
			# report success.
			else:
				panel.held_item.stack_count += item.stack_count
				item.queue_free()
				return true
		
		# If the item is empty, then automatically put the item in it and report success.
		# This works because all panels must have stack_size >= 1.
		elif not panel.held_item:
			panel.held_item = item
			return true
	# There is no more available space in this inventory bar or it cannot pick up
	# the item. Report as much.
	return false

## Returns the combined inventory of all inventory panels.
func get_inventory() -> Array:
	var output := []
	for panel in panels:
		if panel.held_item:
			output.push_back(panel.held_item)
	
	return output

## When we consume an item like fuel, we need a way to make sure the stack count
## is up to date.
## this helper function will keep the label up to date on its panel children.
func update_labels() -> void:
	for panel in panels:
		if panel.held_item:
			panel._update_label()
