extends Label

# The recipe's name comes from the Library object and will be in PascalCase. 
# We use a setter to automatically make the text readable while storing the
# original name for crafting purposes.
var recipe_name := "" setget _set_recipe_name

func _set_recipe_name(value: String) -> void:
	recipe_name = value
	# `String.capitalize()` separates words in PascalCase when it encounters capital
	# letters.
	# For example, it would turn "StirlingEngine" into "Stirling Engine."
	text = recipe_name.capitalize()
	
