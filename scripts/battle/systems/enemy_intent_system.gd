class_name EnemyIntentSystem
extends RefCounted

static func pick_spell(def: EnemyDefinition, turn: int) -> SpellDefinition:
	if def.spells.is_empty():
		return null
	return def.spells[(maxi(turn, 1) - 1) % def.spells.size()]

# {"name", "damage", "heal", "spell"}
static func get_intent(def: EnemyDefinition, turn: int) -> Dictionary:
	var spell := pick_spell(def, turn)
	if spell == null:
		return {"name": "Stands still", "damage": 0, "heal": 0, "spell": null}
	var heal := 0
	for fx in spell.effects:
		if fx.kind == SpellEffect.Kind.HEAL:
			heal += fx.amount
	return {"name": spell.display_name, "damage": spell.base_damage, "heal": heal, "spell": spell}