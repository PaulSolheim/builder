## A component that makes entities craft items over time.
class_name WorkComponent
extends Node

## Emitted when some amount of work has been accomplished.
signal work_accomplished(amount)

## Emitted when all the work has been accomplished.
signal work_done(output)

## Emitted when something causes the worker to stop working.
signal work_enabled_changed(enabled)

## The recipe we are currently using to do the automated crafting with.
var current_recipe: Dictionary

## The expected blueprint that should result from this crafting job.
var current_output: BlueprintEntity

## How much work time is available to complete in seconds.
var available_work := 0.0

## How fast the machine is working. A value of 1.0 means 100% speed.
var work_speed := 0.0

## If `true`, the worker should do work when the simulation ticks the work
## system.
var is_enabled := false setget _set_is_enabled

## Checks the amount of stuff provided in the inventory slots and compares it
## to the recipes inside the provided `recipe_map`.
##
## The `inputs` are a map of items the parent entity possesses. In other words,
## it's the contents of its inventory.
##
## The dictionary should have the form {item_name: amount}.
##
## If we find something we can craft out of it, the function returns `true` and
## configures the component with the crafting job. Otherwise, it returns
## `false`.
func setup_work(inputs: Dictionary, recipe_map: Dictionary) -> bool:
	# The `recipe_map` has an `inputs` array that's keyed to ingredient names and
	# amounts.
	#
	# So for each recipe in the `recipe_map`, we compare the recipe's inputs to
	# the `inputs` provided by the entity's inventory.
	for output in recipe_map.keys():
		# Skip any instance where we have a recipe that has a blueprint we haven't
		# created.
		if not Library.blueprints.has(output):
			continue
		
		# We default to true. In the subsequent loop, we'll set this to false
		# if we ever find something we can't craft this particular recipe.
		var can_craft := true
		var recipe_inputs: Array = recipe_map[output].inputs.keys()
		
		for input in inputs.keys():
			# The moment we find that we don't have the inputs for this recipe,
			# or not enough inputs for the recipe, set can_craft to false and
			# break so we don't keep iterating over this particular recipe.
			if not input in recipe_inputs or inputs[input] < recipe_map[output].inputs[input]:
				can_craft = false
				break
		
		# If we managed to make it to the end of the recipe list without setting
		# `can_craft` to `false`, we configure the component with the recipe,
		# instance the blueprint we want to create, and return `true`.
		if can_craft:
			current_recipe = recipe_map[output]
			current_output = Library.blueprints[output].instance()
			current_output.stack_count = current_recipe.amount
			available_work = current_recipe.time
			return true
	
	# Otherwise, no, we can't craft anything in the map, so we return `false`.
	return false

## Ticks the system and does `delta` time amount of work.
##
## If the node can complete some work through this function call, we emit
## `work_accomplished`.
##
## When it finishes crafting the item, we emit `work_done`. The parent entity
## can connect to this signal and give the component a new item to craft.
func work(delta: float) -> void:
	if is_enabled and available_work > 0.0:
		var work_done := delta * work_speed
		available_work -= work_done
		emit_signal("work_accomplished", work_done)
		if available_work <= 0.0:
			emit_signal("work_done", current_output)

## Emits the `work_enabled_changed` signal if `value` is different from the
## current `is_enabled` property.
func _set_is_enabled(value: bool) -> void:
	if is_enabled != value:
		emit_signal("work_enabled_changed", value)
	is_enabled = value
