extends Entity

## These are the three regions in `tileset.svg` for the boulder sprites.
const REGIONS := [
	Rect2(10, 780, 100, 100),
	Rect2(120, 780, 100, 100),
	Rect2(230, 780, 100, 100)
]
func _ready() -> void:
	## We set the sprite region to a random region.
	var index := randi() % REGIONS.size()
	$Sprite.region_rect = REGIONS[index]

## Tells the Library what name it should pretend to wear instead of its scene name.
func get_entity_name() -> String:
	return "Stone"

