class_name BaseMachineGUI
extends MarginContainer

## Emitted when a change happens, like an item being put into an inventory slot.
signal gui_status_changed

## We emit two signals to indicate when the interface opens and closes.
signal gui_opened
signal gui_closed

func _enter_tree() -> void:
	# Whenever the node appears in the scene tree, we emit "gui_opened", but we
	# emit it after one frame late using `call_deferred()`.
	# This gives us the chance to call the `setup()` function below and
	# initialize the interface first.
	call_deferred("emit_signal", "gui_opened")

func _exit_tree() -> void:
	call_deferred("emit_signal", "gui_closed")

## Sets up anything the interface needs before use. For example, we'll use the
## `InventoryBar` class, which needs a reference to the `GUI` class.
## We'll override this function in extended classes.
func setup(_gui: Control) -> void:
	pass

