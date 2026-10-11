class_name SpellDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var pattern: SpellPattern
@export var requirements: Array[ElementRequirement] = []
@export var base_damage: int = 1

static func make(p_id: StringName, p_name: String, p_pattern: SpellPattern,
		p_reqs: Array, p_damage: int) -> SpellDefinition:
	var s := SpellDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.pattern = p_pattern
	for r in p_reqs:
		s.requirements.append(r)
	s.base_damage = p_damage
	return s