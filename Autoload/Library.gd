extends Node

const BASE_PATH := "res://Entities"
const BLUEPRINT := "Blueprint.tscn"
const ENTITY := "Entity.tscn"

var entities := {}
var blueprints := {}

func _ready() -> void:
	_find_entities_in(BASE_PATH)

func get_entity_name_from(node: Node) -> String:
	if node:
		if node.has_method("get_entity_name"):
			return node.get_entity_name()
		
		var filename := node.filename.substr(node.filename.rfind("/") + 1)
		filename = filename.replace(BLUEPRINT, "").replace(ENTITY, "")
		
		return filename
	return ""

func _find_entities_in(path: String) -> void:
	var directory := Directory.new()
	var error := directory.open(path)
	
	if error != OK:
		print("Library Error: %s" %error)
		return
	
	error = directory.list_dir_begin(true, true)
	
	if error != OK:
		print("Library error: %s" %error)
		return
	
	var filename := directory.get_next()
	
	while not filename.empty():
		if directory.current_is_dir():
			_find_entities_in("%s/%s" % [directory.get_current_dir(), filename])
		else:
			if filename.ends_with(BLUEPRINT):
				blueprints[filename.replace(BLUEPRINT, "")] = load(
					"%s/%s" % [directory.get_current_dir(), filename]
				)
			if filename.ends_with(ENTITY):
				entities[filename.replace(ENTITY, "")] = load(
					"%s/%s" % [directory.get_current_dir(), filename]
				)
		filename = directory.get_next()

## Returns `true` if the provided item matches the provided filter array.
func is_valid_filter(filter_list: Array, item_name: String) -> bool:
	# If the filter list is empty, then it's automatically allowed.
	# Otherwise, we check first if the item is explicitly listed in the list.
	if filter_list.empty() or item_name in filter_list:
		return true
	
	# If it's not, we check any listed item categories in the filter list and if
	# there's one defined, we look it up in the recipes.
	if filter_list.has("Fuels") and Recipes.Fuels.has(item_name):
		return true
	
	return false
