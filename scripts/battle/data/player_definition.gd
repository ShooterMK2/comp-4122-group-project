class_name PlayerDefinition
extends CombatantDefinition

static func default_player() -> PlayerDefinition:
	var definition := load("res://resources/characters/player.tres") as PlayerDefinition
	if definition == null:
		push_error("Unable to load player definition resource.")
		return PlayerDefinition.new()
	return definition.duplicate(true) as PlayerDefinition