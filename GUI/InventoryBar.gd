class_name InventoryBar
extends HBoxContainer

export var InventoryPanelScene: PackedScene
export var slot_count := 10

signal inventory_changed(panel, held_item)

var panels := []

func _ready() -> void:
	_make_panels()

func _make_panels() -> void:
	for _i in slot_count:
		var panel := InventoryPanelScene.instance()
		add_child(panel)
		panels.append(panel)

func setup(gui: Control) -> void:
	# For each panel we've created in '_ready()', we forward the reference to the gui node
	# and connect to their signal.
	for panel in panels:
		panel.setup(gui)
		panel.connect("held_item_changed", self, "_on_Panel_held_item_changed")

# Bubbles up the signal from the inventory bar up to the inventory window.
func _on_Panel_held_item_changed(panel: Control, held_item: BlueprintEntity) -> void:
	emit_signal("inventory_changed", panel, held_item)

