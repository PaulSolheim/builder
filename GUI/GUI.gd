extends CenterContainer

var blueprint: BlueprintEntity setget _set_blueprint, _get_blueprint

## If `true`, it means the mouse is over the `GUI` at the moment.
var mouse_in_gui := false

onready var player_inventory := $HBoxContainer/InventoryWindow
onready var _drag_preview := $DragPreview

## If `true`, it means the GUI window is open.
onready var _is_open: bool = $HBoxContainer/InventoryWindow.visible

## The parent container that holds the inventory window
onready var _gui_rect := $HBoxContainer

onready var quickbar := $MarginContainer/QuickBar
onready var quickbar_container := $MarginContainer

## Prefills the player inventory with objects from this dictionary
export var debug_items := {}

## Each of the action as listed in the input map. We place them in an array so we
## can iterate over each one.
const QUICKBAR_ACTIONS := [
	"quickbar_1",
	"quickbar_2",
	"quickbar_3",
	"quickbar_4",
	"quickbar_5",
	"quickbar_6",
	"quickbar_7",
	"quickbar_8",
	"quickbar_9",
	"quickbar_0"
]

func _ready() -> void:
	player_inventory.setup(self)
	quickbar.setup(self)
	Events.connect("entered_pickup_area", self, "_on_Player_entered_pickup_area")
	
	# ----- Debug system -----
	# We loop over all the keys in the `debug_items` dictionary and ensure they exist in the `Library`.
	for item in debug_items.keys():
		if not Library.blueprints.has(item):
			continue
		
		# If so, we instantiate the item and set its stack count to the value dictionary's value.
		var item_instance: Node = Library.blueprints[item].instance()
		item_instance.stack_count = min(item_instance.stack_size, debug_items[item])
		
		# We then try to add it to the inventory and if it's full, we free the leftover blueprint.
		if not add_to_inventory(item_instance):
			item_instance.queue_free()

func _process(delta: float) -> void:
	var mouse_position := get_global_mouse_position()
	# if the mouse is inside the GUI rect and the GUI is open, set it true.
	mouse_in_gui = _is_open and _gui_rect.get_rect().has_point(mouse_position)

func destroy_blueprint() -> void:
	_drag_preview.destroy_blueprint()

func update_label() -> void:
	_drag_preview.update_label()

func _set_blueprint(value: BlueprintEntity) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	_drag_preview.blueprint = value

func _get_blueprint() -> BlueprintEntity:
	return _drag_preview.blueprint

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if _is_open:
			_close_inventories()
		else:
			_open_inventories()
	# If we pressed anything else, we can check against our quickbar actions.
	else:
		for i in QUICKBAR_ACTIONS.size():
			if InputMap.event_is_action(event, QUICKBAR_ACTIONS[i]) and event.is_pressed():
				_simulate_input(quickbar.panels[i])
				break

## Simulates a mouse click at the location of the panel.
func _simulate_input(panel: InventoryPanel) -> void:
	# Create a new InputEventMouseButton and configure it as a left button click.
	var input := InputEventMouseButton.new()
	input.button_index = BUTTON_LEFT
	input.pressed = true
	
	# Provide it directly to the panel's '_gui_input()' function, as we don't care
	# about the rest of the engine intercepting this event.
	panel._gui_input(input)

## Shows the inventory window, crafting window
func _open_inventories() -> void:
	_is_open = true
	player_inventory.visible = true
	player_inventory.claim_quickbar(quickbar)

## Hides the inventory window, crafting window, and any currently open machine GUI
func _close_inventories() -> void:
	_is_open = false
	player_inventory.visible = false
	_claim_quickbar()

func _claim_quickbar() -> void:
	quickbar.get_parent().remove_child(quickbar)
	quickbar_container.add_child(quickbar)

## Returns an array of inventory panels containing a held item that has a name
## that matches the provided item id from the player inventory and quick-bar.
func find_panels_with(item_id: String) -> Array:
	var existing_stacks: Array = (
		quickbar.find_panels_with(item_id)
		+ player_inventory.find_panels_with(item_id)
	)
	
	return existing_stacks

## Tries to add the blueprint to the inventory, starting with existing item
## stacks and then to an empty panel in the quickbar, then in the main inventory.
## Returns true if it succeeds.
func add_to_inventory(item: BlueprintEntity) -> bool:
	# If the item is already in the scene tree, remove it first.
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	
	if quickbar.add_to_first_available_inventory(item):
		return true
	
	return player_inventory.add_to_first_available_inventory(item)

## Tries to add the ground item detected by the player collision into the player's
## inventory and trigger the animation for it.
func _on_Player_entered_pickup_area(item: GroundItem, player: KinematicBody2D) -> void:
	if not (item and item.blueprint):
		return
	
	# We get the current amount inside the stack. It's possible for there to be
	# no space for the entire stack, but we could still pick up parts of the stack.
	var amount := item.blueprint.stack_count
	
	# Attempts to add the item to existing stacks and available space.
	if add_to_inventory(item.blueprint):
		# If we succed, we play the 'do_pickup()' animation, disabel collisions, etc.
		item.do_pickup(player)
	else:
		# If the attempt failed, we calculate if the stack is smaller than it
		# used to be before we tried picking it up.
		if item.blueprint.stack_count < amount:
			# If so, we need to create a new duplicate ground item whose job is to animate
			# itself flying to the player.
			var new_item := item.duplicate()
			
			# We need to use `call_deferred` to delay the new item by a frame because
			# we disable the shape's collision so it can't be picked up twice.
			#
			# As the physics engine is currently busy dealing with the collision
			# with the player's area and Godot doesn't allow us to change
			# collision states when its physics engine is busy, we need to wait
			# so it won't complain or cause errors.
			item.get_parent().call_deferred("add_child", new_item)
			new_item.call_deferred("setup", item.blueprint)
			new_item.call_deferred("do_pickup", player)

