extends MarginContainer

signal inventory_changed(panel, held_item)

var gui: Control

onready var inventory_path := $PanelContainer/MarginContainer/Inventories
onready var inventories := inventory_path.get_children()

func setup(_gui: Control) -> void:
	gui = _gui
	for bar in inventories:
		bar.setup(gui)
	
	# Test code, to be removed.
	var engine: BlueprintEntity = Library.blueprints.StirlingEngine.instance()
	engine.stack_count = 4
	var battery: BlueprintEntity = Library.blueprints.Battery.instance()
	battery.stack_count = 4
	var wire: BlueprintEntity = Library.blueprints.Wire.instance()
	wire.stack_count = 12
	inventories[0].panels[0].held_item = engine
	inventories[0].panels[1].held_item = battery
	inventories[0].panels[2].held_item = wire

# Whenever we receive the 'inventory_changed' signal, bubble up the signal from the inventory bars.
func _on_InventoryBar_inventory_changed(panel, held_item) -> void:
	emit_signal("inventory_changed", panel, held_item)

