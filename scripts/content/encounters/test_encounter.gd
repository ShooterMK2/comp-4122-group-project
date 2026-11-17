class_name TestEncounter
extends RefCounted

static func enemies() -> Array[EnemyDefinition]:
	return [
		EnemyDefinition.ash_hound(),
		EnemyDefinition.wooden_dummy_variant(0),
		EnemyDefinition.wooden_dummy_variant(1),
	]
