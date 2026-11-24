class_name SkillResolver
extends RefCounted
# Resolves enemy SkillDefinition actions. Does not use SpellResolver / board spells.

const K := SkillEffect.Kind
const A := AilmentTypes.Ailment

# damage = ceil(tier_power * ATK * atk_mult * weaken * defence_mult * random)
# defence_mult uses the same curve as player spells; random uses DAMAGE_RANDOM_MIN/MAX.
static func attack_damage(skill: SkillDefinition, caster: CombatantState,
		defender: CombatantState = null) -> int:
	var raw: float = skill.tier_power() * maxf(1.0, caster.attack) * caster.attack_multiplier
	raw *= caster.outgoing_ailment_multiplier()
	if defender != null:
		raw *= DamageCalculator.defence_multiplier_of(caster, defender)
	raw *= DamageCalculator.overlevel_multiplier_of(caster, defender)
	raw *= randf_range(BattleConfig.DAMAGE_RANDOM_MIN, BattleConfig.DAMAGE_RANDOM_MAX)
	return maxi(0, ceili(raw))

static func cast(skill: SkillDefinition, caster: CombatantState, chosen: CombatantState,
		_state: BattleState, _log: Array[String]) -> int:
	var target := caster if skill.target_kind == SkillDefinition.TargetKind.SELF else chosen
	var dealt := 0
	var notes: Array[String] = []

	match skill.kind:
		SkillDefinition.SkillKind.ATTACK:
			var dmg := attack_damage(skill, caster, target)
			if dmg > 0:
				var res := target.take_damage(dmg)
				dealt = res["hp"] + res["absorbed"]
			notes.append("%s (%d dmg)" % [skill.tier_label(), dealt])
		SkillDefinition.SkillKind.HEAL:
			var healed := caster.heal(skill.heal_amount)
			notes.append("heals %d HP" % healed)
		SkillDefinition.SkillKind.SUPPORT, SkillDefinition.SkillKind.STATUS_AILMENT:
			pass

	for fx in skill.effects:
		match fx.kind:
			K.STAT_BUFF:
				target.apply_stat_mod(fx.amount, true, fx.amount2)
				notes.append(fx.describe())
			K.STAT_DEBUFF:
				target.apply_stat_mod(fx.amount, false, fx.amount2)
				notes.append(fx.describe())
			K.APPLY_AILMENT:
				target.apply_ailment(fx.amount, fx.amount2)
				notes.append("applies %s" % fx.describe())

	var on := "itself" if target == caster else target.display_name
	_log.append("%s uses %s on %s%s" % [
		caster.display_name, skill.display_name, on,
		(" | " + ", ".join(notes)) if not notes.is_empty() else ""])
	return dealt

static func should_shock_skip(c: CombatantState) -> bool:
	if not c.has_ailment(A.SHOCK):
		return false
	return randf() < BattleConfig.AILMENT_SHOCK_CHANCE
