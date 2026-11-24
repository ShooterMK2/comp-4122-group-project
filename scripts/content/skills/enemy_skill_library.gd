class_name EnemySkillLibrary
extends RefCounted
# Loads authored enemy skill resources. Prefer referencing skills on EnemyDefinition .tres.

const SKILL_DIR := "res://resources/skills/enemies/"

static func _load_skill(file_name: String) -> SkillDefinition:
	var path := SKILL_DIR + file_name
	var skill := load(path) as SkillDefinition
	if skill == null:
		push_error("Unable to load skill resource: %s" % path)
		return SkillDefinition.new()
	return skill.duplicate(true) as SkillDefinition

static func cinder_bite() -> SkillDefinition:
	return _load_skill("cinder_bite.tres")

static func smoke_snarl() -> SkillDefinition:
	return _load_skill("smoke_snarl.tres")

static func ember_fever() -> SkillDefinition:
	return _load_skill("ember_fever.tres")

static func lick_wounds(_amount: int = 12) -> SkillDefinition:
	return _load_skill("lick_wounds.tres")

static func mend(_amount: int = BattleConfig.DUMMY_HEAL_PER_TURN) -> SkillDefinition:
	return _load_skill("mend.tres")

static func flail() -> SkillDefinition:
	return SkillDefinition.make_attack(&"flail", "Flail", SkillDefinition.AttackTier.LIGHT)

static func heavy_slam() -> SkillDefinition:
	return SkillDefinition.make_attack(&"heavy_slam", "Heavy Slam", SkillDefinition.AttackTier.HEAVY)

static func static_jolt() -> SkillDefinition:
	return SkillDefinition.make_ailment(&"static_jolt", "Static Jolt",
		AilmentTypes.Ailment.SHOCK, BattleConfig.AILMENT_SHOCK_DEFAULT_TURNS)

static func sapping_howl() -> SkillDefinition:
	return SkillDefinition.make_ailment(&"sapping_howl", "Sapping Howl",
		AilmentTypes.Ailment.WEAKEN, BattleConfig.AILMENT_WEAKEN_DEFAULT_TURNS)

static func bog_drag() -> SkillDefinition:
	return SkillDefinition.make_ailment(&"bog_drag", "Bog Drag",
		AilmentTypes.Ailment.SLOW, BattleConfig.AILMENT_SLOW_DEFAULT_TURNS)

static func open_guard() -> SkillDefinition:
	return SkillDefinition.make_ailment(&"open_guard", "Open Guard",
		AilmentTypes.Ailment.EXPOSE, BattleConfig.AILMENT_EXPOSE_DEFAULT_TURNS)

static func ash_hound_skills() -> Array[SkillDefinition]:
	return [cinder_bite(), smoke_snarl(), ember_fever(), lick_wounds()]
