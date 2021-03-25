class_name FurnaceEntity
extends Entity

## Those are variables like in the Stirling engine.
var available_fuel := 0.0
var last_max_fuel := 0.0

onready var gui := $GUIComponent
onready var work := $WorkComponent
onready var animation := $AnimationPlayer

func _ready() -> void:
	_set_initial_speed()

func _set_initial_speed() -> void:
	work.work_speed = 1.0

## If smelting, displays the current recipe being smelted and how much time is
## left on the tooltip. Otherwise, display nothing.
func get_info() -> String:
	if work.is_enabled:
		return (
			"Smelting: %s into %s\nTime left: %ss"
			% [
				Library.get_entity_name_from(gui.gui.input),
				Library.get_entity_name_from(work.current_output),
				stepify(work.available_work, 0.1)
			]
		)
	else:
		return ""

## Prepares the current job and consumes fuel, or aborts, depending on the
## inventory's state and available fuel.
func _setup_work() -> void:
	# If we have fuel in the inventory or fuel still in the tank, and we have
	# something in the input slot, and we aren't already busy with an existing
	# job
	if (gui.gui.fuel or available_fuel > 0.0) and gui.gui.input and work.available_work <= 0.0:
		
		# Get the input's name to provide it to the work component and try to
		# get an output name out of it.
		var input_id: String = Library.get_entity_name_from(gui.gui.input)
		
		# If the work component does find a job inside of the smelting recipe,
		# then we can enable work and consume fuel if needed.
		if work.setup_work({input_id: gui.gui.input.stack_count}, Recipes.Smelting):
			# We only enable work if there is nothing in the output. If there's
			# some coal we burnt out of wood in the way, we don't want to pour
			# metal on top and replace it. The user has to empty the output slot
			# first.
			#
			# Though we do allow it if the item that's in the output is the same
			# kind as the one we're about to craft.
			work.is_enabled = (
				not gui.gui.output_panel.held_item
				or (
					Library.get_entity_name_from(work.current_output)
					== Library.get_entity_name_from(gui.gui.output_panel.held_item)
				)
			)
			
			# We call the GUI's work function. This begins the animation
			# process.
			gui.gui.work(work.current_recipe.time)
			
			# If we're out of fuel in the gauge, we call `_consume_fuel()`,
			# which takes care of of consuming a piece to get energy from.
			if available_fuel <= 0.0:
				_consume_fuel(0.0)
	
	# If we're already working and we're out of things to smelt (no more input),
	elif work.available_work > 0.0 and not gui.gui.input:
		# Disable the work component and abort the GUI animation.
		work.available_work = 0.0
		work.is_enabled = false
		gui.gui.abort()
	
	# If we don't already have work and the other conditions have been skipped,
	# we disable the work component.
	#
	# It can happen that the worker is enabled at this point because we have
	# fuel but an input with no valid recipe.
	elif work.available_work <= 0.0:
		work.is_enabled = false

func _consume_fuel(amount: float) -> void:
	available_fuel = max(available_fuel - amount, 0.0)
	
	if available_fuel <= 0.0 and gui.gui.fuel:
		last_max_fuel = Recipes.Fuels[Library.get_entity_name_from(gui.gui.fuel)]
		available_fuel = last_max_fuel
		
		gui.gui.fuel.stack_count -= 1
		if gui.gui.fuel.stack_count == 0:
			gui.gui.fuel.queue_free()
			gui.gui.fuel = null
		
		gui.gui.update_labels()
	
	# If we have fuel, we enable the work component.
	work.is_enabled = available_fuel > 0.0
	gui.gui.set_fuel((available_fuel / last_max_fuel) if last_max_fuel > 0.0 else 0.0)

## Attempts to consume the recipe's requisite items from the input stack.
## Returns `true` when it manages to, returns `false` if it failed to consume
## what it needed.
func _consume_input() -> bool:
	# If we have input items in the GUI, we first get the recipe's number of
	# items for this input.
	if gui.gui.input:
		var consumption_count: int = work.current_recipe.inputs[Library.get_entity_name_from(
			gui.gui.input
		)]
		
		# If we have enough, we reduce the stack and destroy it if it reaches `0`.
		if gui.gui.input.stack_count >= consumption_count:
			gui.gui.input.stack_count -= consumption_count
			if gui.gui.input.stack_count == 0:
				gui.gui.input.queue_free()
				gui.gui.input = null
			
			# Keep the labels up to date if any changes ocurred
			gui.gui.update_labels()
			
			# And we report success.
			return true
	else:
		# If we have no input and somehow still reached this point, make sure to
		# abort the animation. They may still be playing despite the job having
		# been stopped by `_setup_work()`.
		gui.gui.abort()
	
	# If we reach this branch, we either have no input, or we don't have enough
	# input.
	# 
	# We return `false` so we don't consume anything but also don't provide any
	# output.
	return false

## Plays the proper animation based on the new state of the work component.
func _on_WorkComponent_work_enabled_changed(enabled: bool) -> void:
	if enabled:
		animation.play("Work")
	else:
		animation.play("Shutdown")

## When the job is finished, consume the requisite amount of inputs and grabs
## the output provided by the recipe into the output slot.
func _on_WorkComponent_work_done(output: BlueprintEntity) -> void:
	if _consume_input():
		gui.gui.grab_output(output)
		_setup_work()
	else:
		# If we failed to get the appropriate input, then get rid of the recipe
		# output we were going to craft and abort work until the situation is
		# fixed by the user.
		output.queue_free()
		work.is_enabled = false
	# Emitting `info_updated` keeps the tooltip up to date.
	Events.emit_signal("info_updated", self)

## Whenever the work component accomplishes any amount of work, consume some
## fuel from the fuel gauge.
func _on_WorkComponent_work_accomplished(amount: float) -> void:
	_consume_fuel(amount)
	Events.emit_signal("info_updated", self)

## Whenever the user puts or removes something from the furnace's inventory,
## make sure that the current job is setup accordingly.
func _on_GUIComponent_gui_status_changed() -> void:
	_setup_work()

## Updates the fuel gauge and progress bar arrow on the GUI
func _on_GUIComponent_gui_opened() -> void:
	gui.gui.set_fuel(available_fuel / last_max_fuel if last_max_fuel else 0.0)
	if work.is_enabled:
		# We call work to start the tween so it's properly configured.
		gui.gui.work(work.current_recipe.time)
		# With the tween running, we can seek to it. We can't seek with a tween
		# that's not running, after all.
		gui.gui.seek(work.current_recipe.time - work.available_work)
