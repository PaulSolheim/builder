extends PanelContainer

const CUSTOM_PANEL_PROPERTY := "custom_styles/panel"

export var regular_style: StyleBoxFlat
export var highlight_style: StyleBoxFlat

onready var recipe_name := $MarginContainer/HBoxContainer/Label
onready var sprite := $MarginContainer/HBoxContainer/GUISprite

signal recipe_activated(recipe, output)

# If we set styles in the inspector, we should use it as soon as the item is
# instanced. We define the `_ready()` function to do that.
func _ready() -> void:
	if regular_style:
		set(CUSTOM_PANEL_PROPERTY, regular_style)
	 
	var gui_size: float = ProjectSettings.get_setting("game_gui/inventory_size")
	# Blueprint sprites are 100 pixels in size. We calcualte the desired scale
	# modifier by dividing the provided size by 100.
	var scale := gui_size / 100.0
	
	# Then we can scale the sprite's size and the minimum size of the crafting
	# window based on a constant 300 pixels, our desired base width.
	sprite.scale *= Vector2(scale, scale)
	rect_min_size = Vector2(300, 0) * scale

## Sets up the sprite and label with the provided recipe data.
func setup(name: String, texture: Texture, uses_region_rect: bool, region_rect: Rect2) -> void:
	recipe_name.recipe_name = name
	sprite.texture = texture
	sprite.region_enabled = uses_region_rect
	sprite.region_rect = region_rect

# Here, we retrieve the recipe's ID from the label and emit it along with its 
# data.
func _on_CraftingRecipeItem_mouse_entered():
	var recipe_filename: String = recipe_name.recipe_name
	Events.emit_signal("hovered_over_recipe", recipe_filename, Recipes.Crafting[recipe_filename])
	set(CUSTOM_PANEL_PROPERTY, highlight_style)

func _on_CraftingRecipeItem_mouse_exited():
	# We use the existing `hovered_over_entity` signal as a simple way to clear
	# the tooltip.
	Events.emit_signal("hovered_over_entity", null)
	set(CUSTOM_PANEL_PROPERTY, regular_style)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		var recipe_filename: String = recipe_name.recipe_name
		var recipe: Dictionary = Recipes.Crafting[recipe_filename]
		
		emit_signal("recipe_activated", recipe, recipe_filename)

