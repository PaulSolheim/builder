class_name WorkSystem
extends Reference

## Dictionary which maps the location of entities with a WorkComponent as keys and a
## reference to the component as their value.
##
## This allows us to know where there are machines that can craft items on the map.
var workers := {}

# We connect to global events to know when the simulation updates and when
# entities are placed or removed to see if they can craft items and 
# register with this system.
func _init() -> void:
	Events.connect("systems_ticked", self, "_on_systems_ticked")
	Events.connect("entity_placed", self, "_on_entity_placed")
	Events.connect("entity_removed", self, "_on_entity_removed")

## Calls `work()` for every entity in the workers list.
func _on_systems_ticked(delta: float) -> void:
	for worker in workers.keys():
		workers[worker].work(delta)

## Places the given entity's work component in the workers list if it is a
## worker entity.
func _on_entity_placed(entity, cellv: Vector2) -> void:
	if entity.is_in_group(Types.WORKERS):
		workers[cellv] = _get_work_component_from(entity)

## Removes the given entity from the workers list when erased from the entity
## tracker.
func _on_entity_removed(_entity, cellv: Vector2) -> void:
	var _erased := workers.erase(cellv)

## Gets the first node that is a `WorkComponent` from the entity's children.
func _get_work_component_from(entity) -> WorkComponent:
	for child in entity.get_children():
		if child is WorkComponent:
			return child
	
	return null
