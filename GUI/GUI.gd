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

func _ready() -> void:
	player_inventory.setup(self)

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

## Shows the inventory window, crafting window
func _open_inventories() -> void:
	_is_open = true
	player_inventory.visible = true

## Hides the inventory window, crafting window, and any currently open machine GUI
func _close_inventories() -> void:
	_is_open = false
	player_inventory.visible = false
