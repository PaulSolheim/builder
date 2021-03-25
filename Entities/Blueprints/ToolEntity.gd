class_name ToolEntity
extends BlueprintEntity

# This property is a multiplier for the deconstruct. With it, bad tools can be
# slower, and high-quality tools can work faster.
# `1.0` is the default speed.
export var tool_speed := 1.0

# The category the tool belongs to, like "Axe" or "Pickaxe". This lets us
# identify what kind of tool this is.
# For example, an axe can cut trees but not break boulders.
export var tool_name := ""

