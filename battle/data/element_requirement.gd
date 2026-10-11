class_name ElementRequirement
extends Resource

@export var element: BattleTypes.Element = BattleTypes.Element.FIRE
@export var min_count: int = 1

static func make(e: int, n: int) -> ElementRequirement:
	var r := ElementRequirement.new()
	r.element = e
	r.min_count = n
	return r
