class_name EnemyIntentSystem
extends RefCounted

static func get_intent(def: EnemyDefinition, turn: int) -> Dictionary:
	if def.attack_damage <= 0:
		return {"name": "Stands still", "damage": 0}
	if def.heavy_every > 0 and turn % def.heavy_every == 0:
		return {"name": "Heavy Swing", "damage": def.attack_damage * 2}
	return {"name": "Flail", "damage": def.attack_damage}