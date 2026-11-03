class_name DamageCalculator
extends RefCounted

# Spell formula: ceil(Spell Damage * (ATK * 0.25)), then
# (Base * Other) * Defence * Elemental * random factor.
static func finalize(raw: int, attacker: CombatantState,
		defender: CombatantState = null, element: int = Elements.Element.NONE,
		other_multiplier: float = BattleConfig.OTHER_MULTIPLIER_DEFAULT,
		terrain: TerrainDefinition = null) -> int:
	var base := ceili(raw * ceili(maxi(1, attacker.attack) * attacker.attack_multiplier)
 		* _attack_multiplier(attacker, element, terrain)
		* BattleConfig.SPELL_ATTACK_FACTOR)
	return _apply_multipliers(base, defender, element, other_multiplier, terrain)

static func _apply_multipliers(base: int, defender: CombatantState, element: int,
		other_multiplier: float, terrain: TerrainDefinition = null) -> int:
	var defence_multiplier := defence_multiplier_of(defender, element, terrain)
	var elemental_multiplier := elemental_multiplier_of(defender, element)
	var break_multiplier := 1.0 + BattleConfig.BREAK_DAMAGE_BONUS \
		if defender != null and defender.is_broken() else 1.0
	var random_multiplier := randf_range(
		BattleConfig.DAMAGE_RANDOM_MIN, BattleConfig.DAMAGE_RANDOM_MAX)
	return maxi(0, ceili(base * other_multiplier * defence_multiplier
		* elemental_multiplier * break_multiplier * random_multiplier))

static func basic_attack(tile_count: int, attacker: CombatantState,
		defender: CombatantState = null, terrain: TerrainDefinition = null) -> int:
	var effective_attack := ceili(maxi(1, attacker.attack) * attacker.attack_multiplier)
	var base := tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE * effective_attack
	base = ceili(base * _attack_multiplier(attacker, Elements.Element.NONE, terrain))
	return _apply_multipliers(base, defender, Elements.Element.NONE,
		BattleConfig.OTHER_MULTIPLIER_DEFAULT, terrain)

static func explain_basic_attack(tile_count: int, attacker: CombatantState,
		defender: CombatantState, terrain: TerrainDefinition = null) -> Dictionary:
	var effective_attack := ceili(maxi(1, attacker.attack) * attacker.attack_multiplier)
	var attack_terrain: float = _attack_multiplier(attacker, Elements.Element.NONE, terrain)
	var base := ceili(tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE * effective_attack
		* attack_terrain)
	var defence: float = defence_multiplier_of(defender, Elements.Element.NONE, terrain)
	var elemental: float = elemental_multiplier_of(defender, Elements.Element.NONE)
	var broken: float = 1.0 + BattleConfig.BREAK_DAMAGE_BONUS \
		if defender.is_broken() else 1.0
	var expected_random: float = (BattleConfig.DAMAGE_RANDOM_MIN
		+ BattleConfig.DAMAGE_RANDOM_MAX) * 0.5
	var expected := maxi(0, ceili(base * defence * elemental * broken * expected_random))
	return {
		"tiles": tile_count,
		"effective_attack": effective_attack,
		"attack_factor": 1.0,
		"attack_terrain": attack_terrain,
		"base": base,
		"other": BattleConfig.OTHER_MULTIPLIER_DEFAULT,
		"defence": defence,
		"elemental": elemental,
		"break": broken,
		"random": expected_random,
		"expected": expected,
	}

static func explain_spell(raw: int, attacker: CombatantState,
		defender: CombatantState, element: int, other_multiplier: float,
		terrain: TerrainDefinition = null) -> Dictionary:
	var effective_attack := ceili(maxi(1, attacker.attack) * attacker.attack_multiplier)
	var attack_terrain: float = _attack_multiplier(attacker, element, terrain)
	var base := ceili(raw * effective_attack * attack_terrain
		* BattleConfig.SPELL_ATTACK_FACTOR)
	var defence: float = defence_multiplier_of(defender, element, terrain)
	var elemental: float = elemental_multiplier_of(defender, element)
	var broken: float = 1.0 + BattleConfig.BREAK_DAMAGE_BONUS \
		if defender.is_broken() else 1.0
	var expected_random: float = (BattleConfig.DAMAGE_RANDOM_MIN
		+ BattleConfig.DAMAGE_RANDOM_MAX) * 0.5
	var expected := maxi(0, ceili(base * other_multiplier * defence
		* elemental * broken * expected_random))
	return {
		"base": base,
		"effective_attack": effective_attack,
		"attack_factor": BattleConfig.SPELL_ATTACK_FACTOR,
		"attack_terrain": attack_terrain,
		"other": other_multiplier,
		"defence": defence,
		"elemental": elemental,
		"break": broken,
		"random": expected_random,
		"expected": expected,
	}

static func defence_multiplier_of(defender: CombatantState,
		element: int = Elements.Element.NONE, terrain: TerrainDefinition = null) -> float:
	if defender == null:
		return 1.0
	var defence := ceili(defender.defence * defender.defence_multiplier)
	if terrain != null:
		defence = ceili(defence * terrain.defence_multiplier_for(element))
	return BattleConfig.DEFENCE_MULTIPLIER_BASE / (
		BattleConfig.DEFENCE_MULTIPLIER_BASE + maxi(0, defence))

static func _attack_multiplier(attacker: CombatantState, element: int,
		terrain: TerrainDefinition) -> float:
	if terrain == null:
		return 1.0
	return terrain.attack_multiplier_for(element)

static func elemental_multiplier_of(defender: CombatantState, element: int) -> float:
	if defender == null or element == Elements.Element.NONE:
		return BattleConfig.ELEMENTAL_MULTIPLIER_DEFAULT
	if element in defender.elemental_weaknesses:
		return BattleConfig.ELEMENTAL_MULTIPLIER_COUNTERED
	if element in defender.elemental_strengths:
		return BattleConfig.ELEMENTAL_MULTIPLIER_COUNTERING
	return BattleConfig.ELEMENTAL_MULTIPLIER_DEFAULT