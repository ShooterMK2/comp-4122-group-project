class_name SkillDefinition
extends Resource
# Enemy-only action. Not a board spell.

enum SkillKind { ATTACK, HEAL, SUPPORT, STATUS_AILMENT }
enum AttackTier { LIGHT, MEDIUM, HEAVY, VERY_HEAVY }
enum TargetKind { HOSTILE, SELF }

@export var id: StringName
@export var display_name: String = ""
@export var kind: SkillKind = SkillKind.ATTACK
@export var target_kind: TargetKind = TargetKind.HOSTILE
@export var attack_tier: AttackTier = AttackTier.MEDIUM
@export var heal_amount: int = 0
@export var effects: Array[SkillEffect] = []

static func make_attack(p_id: StringName, p_name: String, tier: AttackTier) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.kind = SkillKind.ATTACK
	s.target_kind = TargetKind.HOSTILE
	s.attack_tier = tier
	return s

static func make_heal(p_id: StringName, p_name: String, amount: int) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.kind = SkillKind.HEAL
	s.target_kind = TargetKind.SELF
	s.heal_amount = amount
	return s

static func make_support(p_id: StringName, p_name: String, target: TargetKind,
		effects: Array) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.kind = SkillKind.SUPPORT
	s.target_kind = target
	for fx in effects:
		s.effects.append(fx)
	return s

static func make_ailment(p_id: StringName, p_name: String, ailment: int,
		duration: int) -> SkillDefinition:
	var s := SkillDefinition.new()
	s.id = p_id
	s.display_name = p_name
	s.kind = SkillKind.STATUS_AILMENT
	s.target_kind = TargetKind.HOSTILE
	s.effects.append(SkillEffect.apply_ailment(ailment, duration))
	return s

func tier_power() -> int:
	match attack_tier:
		AttackTier.LIGHT:
			return BattleConfig.SKILL_ATTACK_POWER_LIGHT
		AttackTier.MEDIUM:
			return BattleConfig.SKILL_ATTACK_POWER_MEDIUM
		AttackTier.HEAVY:
			return BattleConfig.SKILL_ATTACK_POWER_HEAVY
		AttackTier.VERY_HEAVY:
			return BattleConfig.SKILL_ATTACK_POWER_VERY_HEAVY
	return BattleConfig.SKILL_ATTACK_POWER_MEDIUM

func tier_label() -> String:
	match attack_tier:
		AttackTier.LIGHT:
			return "Light"
		AttackTier.MEDIUM:
			return "Medium"
		AttackTier.HEAVY:
			return "Heavy"
		AttackTier.VERY_HEAVY:
			return "Very Heavy"
	return "Medium"
