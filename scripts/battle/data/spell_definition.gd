class_name SpellDefinition
extends Resource

enum TargetKind { HOSTILE, SELF }

@export var id: StringName
@export var display_name: String = ""
@export var pattern: SpellPattern
@export var requirements: Array[ElementRequirement] = []
@export var base_damage: int = 1
@export_range(0.0, 10.0, 0.05) var other_multiplier: float = BattleConfig.OTHER_MULTIPLIER_DEFAULT
@export var effects: Array[SpellEffect] = []
@export var target_kind: TargetKind = TargetKind.HOSTILE   # SELF: ignores the chosen target

static func make(p_id: StringName, p_name: String, p_pattern: SpellPattern,
		p_reqs: Array, p_damage: int, p_effects: Array = []) -> SpellDefinition:
	var s := SpellDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.pattern = p_pattern
	for r in p_reqs:
		s.requirements.append(r)
	s.base_damage = p_damage
	for fx in p_effects:
		s.effects.append(fx)
	return s

func requirement_text() -> String:
	var parts: Array[String] = []
	for r in requirements:
		parts.append("%d %s" % [r.min_count, Elements.name_of(r.element)])
	return "%s \u00b7 %d tiles" % [", ".join(parts), pattern.cells.size()]

func primary_element() -> int:
	if requirements.is_empty():
		return Elements.Element.NONE
	return requirements[0].element
