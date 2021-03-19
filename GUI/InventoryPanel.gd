class_name InventoryPanel
extends Panel

signal held_item_changed(panel, item)

var held_item: BlueprintEntity setget _set_held_item

var gui: Control

onready var count_label := $Label

func _ready() -> void:
	var panel_size: float = ProjectSettings.get_setting("game_gui/inventory_size")
	
	# Force the panel's size and min size to match the project setting.
	rect_min_size = Vector2(panel_size, panel_size)
	rect_size = rect_min_size

func setup(_gui: Control) -> void:
	gui = _gui

func _set_held_item(value: BlueprintEntity) -> void:
	if is_instance_valid(held_item) and held_item.get_parent() == self:
		remove_child(held_item)
	
	held_item = value
	
	if is_instance_valid(held_item):
		add_child(held_item)
		move_child(held_item, 0)
		held_item.display_as_inventory_icon()
	
	_update_label()
	
	emit_signal("held_item_changed", self, held_item)

func _update_label() -> void:
	var can_be_stacked := is_instance_valid(held_item) and held_item.stack_count > 1
	
	if can_be_stacked:
		count_label.text = str(held_item.stack_count)
		count_label.show()
	else:
		count_label.text = str(1)
		count_label.hide()

func _gui_input(event: InputEvent) -> void:
	var left_click := event.is_action_pressed("left_click")
	var right_click := event.is_action_pressed("right_click")
	
	if left_click or right_click:
		if gui.blueprint:
			var blueprint_name := Library.get_entity_name_from(gui.blueprint)
			
			if is_instance_valid(held_item):
				var held_item_name := Library.get_entity_name_from(held_item)
				var item_is_same_type: bool = held_item_name == blueprint_name
				
				var stack_has_space: bool = held_item.stack_count < held_item.stack_size
				if item_is_same_type and stack_has_space:
					# If the player left-clicked, we merge the mouse's entire stack with this one.
					if left_click:
						_stack_items()
					# With a right-click, we merge half of the mouse's stack with this one.
					elif right_click:
						_stack_items(true)
				# if the items are not the same name or there is no space, we swap the two items,
				# putting the panel's in the mouse and the mouse's in the panel.
				else:
					if left_click:
						_swap_items()
			# If this inventory slot is empty
			else:
				# If the player left-clicks on the slot, we put the item in the slot.
				if left_click:
					_grab_item()
				
				# If the player right-clicks, we either put half the mouse's stack in the slot
				# or put the mouse's item in the slot if it can't stack.
				elif right_click:
					if gui.blueprint.stack_count > 1:
						_grab_split_items()
					else:
						_grab_item()
		
		# If the mouse isn't holding any item, but there is an item in the slot.
		elif is_instance_valid(held_item):
			# On left-click, we put the slot's item in the mouse's inventory.
			if left_click:
				_release_item()
			# On right-click, we either put the item in the mouse's inventory or split the stack.
			elif right_click:
				if held_item.stack_count == 1:
					_release_item()
				else:
					_split_items()
	# Hover over entity, possibly show tooltip.
	elif event is InputEventMouseMotion and is_instance_valid(held_item):
		Events.emit_signal("hovered_over_entity", held_item)

func _stack_items(split := false) -> void:
	# We first calculate the smaller number between half the mouse's stack and the amount of space
	# left on the current stack. We don't want to go over or grab more than the mouse has,
	# which is why we pick the smaller number.
	var count:= int(
		min(
			gui.blueprint.stack_count / (2 if split else 1),
			held_item.stack_size - held_item.stack_count
		)
	)
	
	# If we are splitting the mouse's stack, we reduce its 'stack_count' by 'count'
	# and update its label.
	if split:
		gui.blueprint.stack_count -= count
		gui.update_label()
	else:
		# If we are grabbing as much of the stack as possible, we reduce it by 'count'
		# in case we don't have enough space for all of it.
		if count < gui.blueprint.stack_count:
			gui.blueprint.stack_count -= count
			gui.update_label()
		else:
			# Or, if the stack is reduced to zero, we destroy it and remove it from the mouse.
			gui.destroy_blueprint()
	
	# Finally, we increase the held item's stack count by the calculated 'count'
	# and update the label.
	held_item.stack_count += count
	_update_label()

func _swap_items() -> void:
	var item: BlueprintEntity = gui.blueprint
	# We set the mouse's blueprint to null here. This calls its setter
	# and ensures that the blueprint is removed from the scene tree,
	# making it available for the panel to add as a child.
	gui.blueprint = null
	
	var current_item := held_item
	self.held_item = item
	gui.blueprint = current_item

# Grabs the item form the mouse and puts it into the panel's inventory.
func _grab_item() -> void:
	var item: BlueprintEntity = gui.blueprint
	
	# We make sure the blueprint has been released from the mouse so we can grab it.
	gui.blueprint = null
	self.held_item = item

# Releases the item from the panel and puts it into themouse's inventory.
func _release_item() -> void:
	var item := held_item
	
	# We make sure the blueprint has been released from the panel
	# so the mouse can grab it.
	self.held_item = null
	gui.blueprint = item

# Splits the current panel's inventory stack and gives half to the mouse's inventory.
func _split_items() -> void:
	# We calculate half of the current stack.
	var count := int(held_item.stack_count / 2.0)
	
	# We then create a brand new 'BlueprintEntity' and sets its stack size
	# to what we've calculated. We also reduce the current one by that amount.
	var new_stack := held_item.duplicate()
	new_stack.stack_count = count
	held_item.stack_count -= count
	
	# Finally, we give the mouse the new stack and update the label.
	gui.blueprint = new_stack
	_update_label()

# Split's the mouse's inventory stack and takes half of it into this item slot.
# The logic is similar to '_split_items()' above, but reversed as we take the
# item from the mouse this time.
func _grab_split_items() -> void:
	var count := int(gui.blueprint.stack_count / 2.0)
	
	var new_stack: BlueprintEntity = gui.blueprint.duplicate()
	new_stack.stack_count = count
	
	gui.blueprint.stack_count -= count
	gui.update_label()
	
	self.held_item = new_stack
