class_name QueuedSpell
extends RefCounted

var definition: SpellDefinition
var source_elements: Array[int] = []

func _init(p_definition: SpellDefinition = null, p_elements: Array = []) -> void:
	definition = p_definition
	for e in p_elements:
		source_elements.append(e)
