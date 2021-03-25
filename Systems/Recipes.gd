class_name Recipes
extends Reference


## We store crafting recipes in this constant. We can refer to this from the
## crafting GUI to determine what the player can craft with what they have and
## then craft it.
## 
## Each recipe is keyed to the kind of entity it creates, with the value being a
## dictionary with `inputs`, a dictionary of items and their required amount.
## The `amount` key tells us how many items the recipe produces.
const Crafting := {
	StirlingEngine = {inputs = {"Ingot": 8, "Wire": 3}, amount = 1},
	Wire = {inputs = {"Ingot": 2}, amount = 5},
	Battery = {inputs = {"Ingot": 12, "Wire": 5}, amount = 1},
	Pickaxe = {inputs = {"Branches": 2, "Ingot": 3}, amount = 1},
	CrudePickaxe = {inputs = {"Branches": 2, "Stone": 5}, amount = 1},
	Axe = {inputs = {"Branches": 2, "Ingot": 3}, amount = 1},
	CrudeAxe = {inputs = {"Branches": 2, "Stone": 5}, amount = 1},
	Branches = {inputs = {"Lumber": 1, "Axe": 0}, amount = 5},
	Chest = {inputs = {"Lumber": 2, "Branches": 3, "Ingot": 1}, amount = 1}
}

## A dictionary of data for smelting machines. Keyed to the output name, with an
## inputs dictionary of input names with amounts and an amount of time it takes
## to craft.
const Smelting := {
	Ingot = {inputs = {"Ore": 1}, amount = 1, time = 5.0},
	Coal = {inputs = {"Lumber": 1}, amount = 2, time = 3.0}
}

## Holds a dictionary of the types of things that are considered fuels and how
## much work time they provide in seconds when burnt.
const Fuels := {Lumber = 50.0, Branches = 10.0, Coal = 100.0}
