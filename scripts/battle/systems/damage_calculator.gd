class_name DamageCalculator
extends RefCounted

# Spell formula: ceil(Spell Damage * (ATK * 0.25)), then
# (Base * Other) * Defence * Elemental * random factor.
static func finalize(raw: int, attacker: CombatantState,
		defender: CombatantState = null, element: int = Elements.Element.NONE,
		other_multiplier: float = BattleConfig.OTHER_MULTIPLIER_DEFAULT) -> int:
	var base := ceili(raw * (maxi(1, attacker.attack)
		* BattleConfig.SPELL_ATTACK_FACTOR))
	return _apply_multipliers(base, defender, element, other_multiplier)

static func _apply_multipliers(base: int, defender: CombatantState, element: int,
		other_multiplier: float) -> int:
	var defence_multiplier := defence_multiplier_of(defender)
	var elemental_multiplier := elemental_multiplier_of(defender, element)
	var random_multiplier := randf_range(
		BattleConfig.DAMAGE_RANDOM_MIN, BattleConfig.DAMAGE_RANDOM_MAX)
	return maxi(0, ceili(base * other_multiplier * defence_multiplier
		* elemental_multiplier * random_multiplier))

static func basic_attack(tile_count: int, attacker: CombatantState,
		defender: CombatantState = null) -> int:
	var base := tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE * maxi(1, attacker.attack)
	return _apply_multipliers(base, defender, Elements.Element.NONE,
		BattleConfig.OTHER_MULTIPLIER_DEFAULT)

static func defence_multiplier_of(defender: CombatantState) -> float:
	if defender == null:
		return 1.0
	return BattleConfig.DEFENCE_MULTIPLIER_BASE / (
		BattleConfig.DEFENCE_MULTIPLIER_BASE + maxi(0, defender.defence))

static func elemental_multiplier_of(defender: CombatantState, element: int) -> float:
	if defender == null or element == Elements.Element.NONE:
		return BattleConfig.ELEMENTAL_MULTIPLIER_DEFAULT
	if element in defender.elemental_weaknesses:
		return BattleConfig.ELEMENTAL_MULTIPLIER_COUNTERED
	if element in defender.elemental_strengths:
		return BattleConfig.ELEMENTAL_MULTIPLIER_COUNTERING
	return BattleConfig.ELEMENTAL_MULTIPLIER_DEFAULT