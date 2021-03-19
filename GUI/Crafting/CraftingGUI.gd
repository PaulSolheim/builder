extends MarginContainer

## We preload the CraftingRecipeItem scene to instantiate it.
## We load it using its relative path. As it's in the same directory as this
## script, we only need the file's name.
const CraftingItem := preload("CraftingRecipeItem.tscn")

var gui: Control

## We'll instantiate recipe panels as children of the VBoxContainer.
onready var items := $PanelContainer/CraftingList/ScrollContainer/VBoxContainer

## We use this function to get a reference to the main GUI node, which, in turn,
## will give us functions to access the inventory.
func setup(_gui: Control) -> void:
	gui = _gui

## The main function that forces an update of all recipes based on what items
## are available in the player's inventory.
func update_recipes() -> void:
	# We free all existing recipes to start from a clean state.
	for child in items.get_children():
		child.queue_free()
	
	# We loop over every available recipe name.
	for output in Recipes.Crafting.keys():
		var recipe: Dictionary = Recipes.Crafting[output]
		
		# We default to true, and then iterate over each item. If at any point
		# it turns out false, then we can skip the item.
		var can_craft := true
		
		# For each required material in the recipe, we ensure the player has enough of it.
		# If not, they can't craft the item and we move to the next recipe.
		for input in recipe.inputs.keys():
			if not gui.is_in_inventory(input, recipe.inputs[input]):
				can_craft = false
				break
		
		if not can_craft:
			continue
		
		# We temporarily instance the blueprint to acess its sprite and data.
		var temp: BlueprintEntity = Library.blueprints[output].instance()
		
		# We then instantiate the recipe item and add it to the scene tree.
		var item := CraftingItem.instance()
		items.add_child(item)
		
		# We grab the blueprint's sprite.
		var sprite: Sprite = temp.get_node("Sprite")
		
		# And we use the sprite to set up the recipe item with the name,
		# texture, and sprite region information.
		item.setup(
			Library.get_entity_name_from(temp),
			sprite.texture,
			sprite.region_enabled,
			sprite.region_rect
		)
		item.connect("recipe_activated", self, "_on_recipe_activated")
		
		# And finally, we free the temporary blueprint as we don't need it
		# anymore.
		temp.free()
	
	Events.emit_signal("hovered_over_entity", null)

## Crafts the output item by consuming the recipe's inputs from the player
## inventory.
func _on_recipe_activated(recipe: Dictionary, output: String) -> void:
	# We loop over every input and find inventory panels containing this item.
	for input in recipe.inputs.keys():
		var panels: Array = gui.find_panels_with(input)
		var count: int = recipe.inputs[input]
		
		# We then loop over the panels and update their count.
		for panel in panels:
			# If there is enough in the stack, we reduce it by the required
			# amount.
			if panel.held_item.stack_count >= count:
				panel.held_item.stack_count -= count
			# If there isn't enough, we reduce the required count by how many there
			# are, then set the stack to 0.
			else:
				count -= panel.held_item.stack_count
				panel.held_item.stack_count = 0
			
			# If the stack is now a size of 0, we delete it.
			if panel.held_item.stack_count == 0:
				panel.held_item.queue_free()
				panel.held_item = null
			
			# And we update the count label up to date if it hasn't been
			# deleted.
			panel._update_label()
	
	# Now that we've consumed all items, we can use the library to instance a
	# new blueprint for the new item, and add it to the player inventory.
	var item: BlueprintEntity = Library.blueprints[output].instance()
	item.stack_count = recipe.amount
	
	gui.add_to_inventory(item)
