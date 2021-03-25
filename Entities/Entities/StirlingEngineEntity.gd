extends Entity

const BOOTUP_TIME := 6.0
const SHUTDOWN_TIME := 3.0

## How much time in seconds we have left with the last piece of consumed fuel.
var available_fuel := 0.0

## How much maximum time the last piece of fuel we consumed provided
## We store this value to calculate the percentage of fuel left to burn and
## update the bar.
var last_max_fuel := 0.0

onready var gui := $GUIComponent
onready var animation_player := $AnimationPlayer
onready var tween := $Tween
onready var shaft := $PistonShaft
onready var power := $PowerSource

## Either removes `amount` of fuel from the available fuel, or attempts to take
## a piece of item from its inventory to refill the available fuel.
func _consume_fuel(amount: float) -> void:
	available_fuel = max(available_fuel - amount, 0.0)
	
	# If we run out of fuel, and there is something burn-able in the inventory
	if available_fuel <= 0.0 and gui.gui.fuel:
		# We get the amount it should give from the Recipes static class and
		# reset the available fuel to that amount.
		last_max_fuel = Recipes.Fuels[Library.get_entity_name_from(gui.gui.fuel)]
		available_fuel = last_max_fuel
		
		# We reduce the stack by 1. If it becomes 0, we destroy it. Otherwise,
		# we update its inventory label to show the reduction.
		gui.gui.fuel.stack_count -= 1
		if gui.gui.fuel.stack_count == 0:
			gui.gui.fuel.queue_free()
			gui.gui.fuel = null
		else:
			gui.gui.update_labels()
	else:
		# If we still have fuel left, we configure the power source and ensure
		# animations are running.
		_setup_work()
	
	# We set the shader on the inventory to the percentage of remaining fuel
	# compared to the maximum for the piece of fuel we last consumed.
	gui.gui.set_fuel((available_fuel / last_max_fuel) if last_max_fuel > 0.0 else 0.0)

## Plays animations and updates the power source's `efficiency` via the
## `_update_efficiency` method.
func _setup_work() -> void:
	# If the animation player is not playing and we have fuel available, we
	# first play the piston animation.
	if not animation_player.is_playing() and (gui.gui.fuel or available_fuel > 0.0):
		animation_player.play("Work")
		
		# We configure the tween to ramp up the animation speed, ramp up the
		# power source's `efficiency`, and change the shaft color.
		tween.interpolate_property(animation_player, "playback_speed", 0, 1, BOOTUP_TIME)
		tween.interpolate_method(self, "_update_efficiency", 0, 1, BOOTUP_TIME)
		tween.interpolate_property(shaft, "modulate", Color.white, Color(0.5, 1, 0.5), BOOTUP_TIME)
		tween.start()
		
		# We call `_consume_fuel()` with a value of 0 to trigger the update
		# cycle that takes one of the burnable fuels from the inventory slot.
		_consume_fuel(0.0)
	
	# If the animation is playing and we do *not* have fuel available.
	elif (
		animation_player.is_playing()
		and animation_player.current_animation == "Work"
		and not (gui.gui.fuel or available_fuel > 0.0)
	):
		# We first temporarily turn off animation looping.
		#
		# This allows the animation player to send the "animation_finished"
		# signal and puts the piston into the lower position.
		#
		# This is because our shutdown animation starts with the piston in the
		# lower position, and if we played the animation without accounting
		# for that, it'd snap into place and that would look wrong.
		var work_animation: Animation = animation_player.get_animation(
			animation_player.current_animation
		)
		work_animation.loop = false
		# We yield to make sure the piston does one full animation cycle before
		# we shut down.
		yield(animation_player, "animation_finished")
		work_animation.loop = true
		
		# Then, we play shutdown, reset the color, and ramp the power source
		# efficiency down to 0.
		animation_player.play("Shutdown")
		animation_player.playback_speed = 1.0
		tween.interpolate_property(shaft, "modulate", shaft.modulate, Color(1, 1, 1), SHUTDOWN_TIME)
		tween.interpolate_method(self, "_update_efficiency", 1, 0, SHUTDOWN_TIME)
		tween.start()

func _update_efficiency(value: float) -> void:
	power.efficiency = value
	Events.emit_signal("info_updated", self)

## Provides the current amount of power being output by the engine.
func get_info() -> String:
	# We format the power as a number with one decimal.
	return "%.1f j/s" % power.get_effective_power()

func _on_GUIComponent_gui_status_changed():
	_setup_work()

func _on_PowerSource_power_updated(power_draw, delta):
	_consume_fuel(delta)
