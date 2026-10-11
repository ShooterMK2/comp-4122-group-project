class_name QueuedSpell
extends RefCounted

var definition: SpellDefinition
var source_elements: Array[int] = []

func _init(d: SpellDefinition, elems: Array[int]) -> void:
	definition = d
	source_elements = elems

func summary() -> String:
	var parts: Array[String] = []
	for e in source_elements:
		parts.append(BattleTypes.letter_of(e))
	return "%s  (%d dmg)  [%s]" % [definition.display_name,
		definition.base_damage, " ".join(parts)]