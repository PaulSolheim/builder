extends Node

signal entity_placed(entity, cellv)
signal entity_removed(entity, cellv)

## Signal emitted when the simulation triggers the systems for updates.
signal systems_ticked(delta)

## Signal emitted when the player has arrived at an item that can be picked up
signal entered_pickup_area(entity, player)
