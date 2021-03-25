extends FurnaceGUI

## Like with the Stirling engine, when the system isn't being fed with enough
## electricity, we can slow it down with a speed parameter by affecting the
## tween's playback speed.
func update_speed(speed: float) -> void:
	if not is_inside_tree():
		return
	
	tween.playback_speed = speed

func setup(gui: Control) -> void:
	input_container.setup(gui)
	output_panel_container.setup(gui)
	output_panel = output_panel_container.panels[0]

func update_labels() -> void:
	input_container.update_labels()
	output_panel_container.update_labels()

func _find_nodes() -> void:
	input_container = $HBoxContainer/InputInventoryBar
