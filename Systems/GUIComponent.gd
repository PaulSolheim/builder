class_name GUIComponent
extends Node

## We'll bubble up signals from `MachineGUI` to make it easier to connect to
## them.
signal gui_status_changed
signal gui_opened
signal gui_closed

## This will store the instanced interfact for the machine.
var gui: BaseMachineGUI

## This is the scene we'll instance and save in the `gui` variable.
export var GuiWindow: PackedScene

func _ready() -> void:
	# We must assign a scene to the `GuiWindow` for this code to work.
	assert(GuiWindow, "You must assign a scene to the the Gui Window property.")
	gui = GuiWindow.instance()

	# We connect to the new instance's signals, but instead of using a custom
	# function, we call `emit_signal()` while passing the signal name as a
	# parameter.
	# Doing this forwards signals automatically.
	gui.connect("gui_status_changed", self, "emit_signal", ["gui_status_changed"])
	gui.connect("gui_opened", self, "emit_signal", ["gui_opened"])
	gui.connect("gui_closed", self, "emit_signal", ["gui_closed"])

func _exit_tree() -> void:
	if gui:
		# Because the gui instance is not likely to be in the scene tree when we
		# quit the game or go back to the main menu, it will not be
		# automatically be cleaned up in memory.
		#
		# Freeing it when this component exits the scene tree saves us from
		# having a memory leak.
		gui.queue_free()

# Returns an array of InventoryBar instances in the node's interface.
func get_inventory_bars() -> Array:
	var output := []
	var parent_stack := [gui]
	
	# We loop recursively over the interface and its children, exploring its
	# nodes to find all inventory bars.
	while not parent_stack.empty():
		var current: Node = parent_stack.pop_back()
		
		if current is InventoryBar:
			output.push_back(current)
		
		# Here's what keeps the loop going: we add the current node's children
		# to the stack until its empties.
		parent_stack += current.get_children()
	
	return output
