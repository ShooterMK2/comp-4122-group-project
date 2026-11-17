class_name EnemyIntentSystem
extends RefCounted

static func pick_skill(def: EnemyDefinition, turn: int) -> SkillDefinition:
	if def.skills.is_empty():
		return null
	return def.skills[(maxi(turn, 1) - 1) % def.skills.size()]

# {"name", "kind", "damage", "heal", "skill"}
static func get_intent(def: EnemyDefinition, turn: int) -> Dictionary:
	var skill := pick_skill(def, turn)
	if skill == null:
		return {"name": "Stands still", "kind": "", "damage": 0, "heal": 0, "skill": null}
	var damage := 0
	var heal := 0
	var kind_name: String = str(SkillDefinition.SkillKind.keys()[skill.kind])
	match skill.kind:
		SkillDefinition.SkillKind.ATTACK:
			damage = skill.tier_power()
			kind_name = "ATTACK/%s" % skill.tier_label()
		SkillDefinition.SkillKind.HEAL:
			heal = skill.heal_amount
		SkillDefinition.SkillKind.SUPPORT:
			kind_name = "SUPPORT"
		SkillDefinition.SkillKind.STATUS_AILMENT:
			kind_name = "AILMENT"
	return {
		"name": skill.display_name,
		"kind": kind_name,
		"damage": damage,
		"heal": heal,
		"skill": skill,
	}
