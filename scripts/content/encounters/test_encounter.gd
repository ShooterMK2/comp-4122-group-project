class_name TestEncounter
extends RefCounted

static func enemies() -> Array[EnemyDefinition]:
	var out: Array[EnemyDefinition] = []
	for i in 3:
		out.append(EnemyDefinition.wooden_dummy())
	return out
