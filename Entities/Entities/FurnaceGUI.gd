## A class name lets us easily extend it without having to `preload()` it
class_name FurnaceGUI
extends BaseMachineGUI

# Reference to the ore item in the input inventory bar.
var input: BlueprintEntity
# Reference to the fuel item in the fuel inventory bar.
var fuel: BlueprintEntity

# We grab the output panel to work with its inventory directly.
# This is because the inventory bar would normally check the item filters, which we
# want to bypass without having to code a workaround.
var output_panel: Panel

# Those are references to all the nodes we'll need to access in the script.
var input_container: InventoryBar
var fuel_container: InventoryBar
var fuel_bar: ColorRect
onready var output_panel_container := $HBoxContainer/OutputInventoryBar
onready var tween := $Tween
onready var arrow := $HBoxContainer/GUISprite

func _ready() -> void:
	# The inventory panels take care of updating their size, but the arrow
	# should be sized to match the gui's scale in project settings.
	var scale: float = (
		ProjectSettings.get_setting("game_gui/inventory_size") / arrow.region_rect.size.x
	)
	arrow.scale = Vector2(scale, scale)
	# The function takes care of getting the nodes we need.
	_find_nodes()

func _find_nodes() -> void:
	fuel_container = $HBoxContainer/VBoxContainer/HBoxContainer/FuelInventoryBar
	input_container = $HBoxContainer/VBoxContainer/InputInventoryBar
	fuel_bar = $HBoxContainer/VBoxContainer/HBoxContainer/ColorRect

## We'll call this function to start the crafting animation (arrow filling up).
## The function initiates a tween animation lasting `time` seconds.
func work(time: float) -> void:
	# Tween does not work if it is not in the scene tree, so we need to check if
	# the GUI is open or not before we start animating.
	if not is_inside_tree():
		return
	
	# Since we're using a shader to animate using `set_shader_param()`, we can't
	# just use interpolate property.
	# Instead, we call a function that'll update the shader.
	tween.interpolate_method(self, "_advance_work_time", 0, 1, time)
	tween.start()

## Stops the tween animation and resets the arrow fill amount.
func abort() -> void:
	tween.stop_all()
	tween.remove_all()
	arrow.material.set_shader_param("fill_amount", 0)

## Updates the *fuel* bar's `fill_amount` shader parameter.
func set_fuel(amount: float) -> void:
	fuel_bar.material.set_shader_param("fill_amount", amount)

## If the tween is already animating, seek to the current amount of time.
## We use this when we start animating, close the inventory, and then open it
## again later. This makes sure the tween is updated to the amount of time
## left crafting.
func seek(time: float) -> void:
	if tween.is_active():
		tween.seek(time)

## Sets up all inventory slots.
func setup(gui: Control) -> void:
	input_container.setup(gui)
	fuel_container.setup(gui)
	output_panel_container.setup(gui)
	# We manually access the item panel in the output inventory bar to manually
	# insert crafted ingots in it.
	output_panel = output_panel_container.panels[0]

## Sets a newly crafted item as the output panel's item, or adds it to the
## existing crafted item stack.
func grab_output(item: BlueprintEntity) -> void:
	# If there's no item in the output slot, we assign it.
	if not output_panel.held_item:
		output_panel.held_item = item
	# If there's already an item, we increase its stack count.
	else:
		var held_item_id := Library.get_entity_name_from(output_panel.held_item)
		var item_id := Library.get_entity_name_from(item)
		if held_item_id == item_id:
			output_panel.held_item.stack_count += item.stack_count
		
		item.queue_free()
	output_panel_container.update_labels()

## Force all panel labels to update.
func update_labels() -> void:
	input_container.update_labels()
	fuel_container.update_labels()
	output_panel_container.update_labels()

## Sets the *arrow*'s `fill_amount` shader param so it fills up. Called by the
## tween node.
func _advance_work_time(amount: float) -> void:
	arrow.material.set_shader_param("fill_amount", amount)

func _on_InputInventoryBar_inventory_changed(panel, held_item):
	input = held_item
	emit_signal("gui_status_changed")

func _on_FuelInventoryBar_inventory_changed(panel, held_item):
	fuel = held_item
	emit_signal("gui_status_changed")
