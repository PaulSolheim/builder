extends Entity

## Each of the sprite regions with foliage.
const REGIONS := [
	Rect2(10, 560, 210, 210),
	Rect2(230, 560, 210, 210),
	Rect2(450, 560, 210, 210),
	Rect2(670, 560, 210, 210),
]

func _ready() -> void:
	# Assign random foliage as the region for the sprite.
	$Foliage.region_rect = REGIONS[randi() % REGIONS.size()]
	# And flip it horizontally at random for extra variety.
	# $Foliage.flip_h = rand_range(0, 10) < 5.5

## Returns the name "Lumber" so deconstructing a tree drops lumber.
func get_entity_name() -> String:
	return "Lumber"
