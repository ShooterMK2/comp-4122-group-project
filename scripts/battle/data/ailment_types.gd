class_name AilmentTypes
extends RefCounted
# Enemy-applied ailments. Duration-only, no stacks. Separate from StatusTypes.

enum Ailment { POISON, SHOCK, WEAKEN, SLOW, EXPOSE }

static func ailment_name(a: int) -> String:
	return Ailment.keys()[a].capitalize()
