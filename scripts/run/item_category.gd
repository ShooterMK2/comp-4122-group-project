class_name ItemCategory
extends RefCounted

enum Kind { CONSUMABLE, EQUIPMENT, IMPORTANT, SPELL, FRAGMENT }

# Display / All-tab grouping order (Equipments before Consumables).
const ALL_GROUP_ORDER := [
	Kind.EQUIPMENT,
	Kind.CONSUMABLE,
	Kind.SPELL,
	Kind.FRAGMENT,
	Kind.IMPORTANT,
]

static func display_name(kind: int) -> String:
	match kind:
		Kind.EQUIPMENT:
			return "Equipments"
		Kind.CONSUMABLE:
			return "Consumables"
		Kind.SPELL:
			return "Spells"
		Kind.FRAGMENT:
			return "Fragments"
		Kind.IMPORTANT:
			return "Importants"
		_:
			return "Items"

static func group_rank(kind: int) -> int:
	var idx := ALL_GROUP_ORDER.find(kind)
	return idx if idx >= 0 else 99
