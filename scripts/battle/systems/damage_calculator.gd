class_name DamageCalculator
extends RefCounted

# Spell base damage is scaled through the full damage formula. Effect bonuses
# are added as flat damage after that scaling to keep their values predictable.
static func finalize(raw: float, attacker: CombatantState,
		defender: CombatantState = null, element: int = Elements.Element.NONE,
		other_multiplier: float = BattleConfig.OTHER_MULTIPLIER_DEFAULT,
		terrain: TerrainDefinition = null, flat_bonus: float = 0.0) -> int:
	var effective_attack := maxf(1.0, attacker.attack) \
			* BattleConfig.SPELL_ATTACK_FACTOR
	var base := raw * effective_attack
	base *= attacker.attack_multiplier * _attack_multiplier(attacker, element, terrain)
	base *= attacker.damage_output_multiplier
	return _apply_multipliers(base, attacker, defender, element, other_multiplier,
		terrain, flat_bonus)

static func _apply_multipliers(base: float, attacker: CombatantState,
		defender: CombatantState, element: int,
		other_multiplier: float, terrain: TerrainDefinition = null,
		flat_bonus: float = 0.0) -> int:
	var defence_multiplier := defence_multiplier_of(attacker, defender, element, terrain)
	var elemental_multiplier := elemental_multiplier_of(defender, element)
	var random_multiplier := randf_range(
		BattleConfig.DAMAGE_RANDOM_MIN, BattleConfig.DAMAGE_RANDOM_MAX)
	var broken_multiplier := 1.0
	if defender != null and defender.is_broken():
		broken_multiplier += BattleConfig.BREAK_DAMAGE_BONUS
	return maxi(0, ceili((base * other_multiplier * defence_multiplier
		* elemental_multiplier * random_multiplier + flat_bonus) * broken_multiplier))

static func basic_attack(tile_count: int, attacker: CombatantState,
		defender: CombatantState = null, terrain: TerrainDefinition = null) -> int:
	var effective_attack := maxf(1.0, attacker.attack) * attacker.attack_multiplier
	var base := tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE * effective_attack
	base *= _attack_multiplier(attacker, Elements.Element.NONE, terrain)
	base *= attacker.damage_output_multiplier
	return _apply_multipliers(base, attacker, defender, Elements.Element.NONE,
		BattleConfig.OTHER_MULTIPLIER_DEFAULT, terrain)

static func explain_basic_attack(tile_count: int, attacker: CombatantState,
		defender: CombatantState, terrain: TerrainDefinition = null) -> Dictionary:
	var effective_attack := maxf(1.0, attacker.attack) * attacker.attack_multiplier
	var attack_terrain: float = _attack_multiplier(attacker, Elements.Element.NONE, terrain)
	var base := tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE * effective_attack
	base *= attack_terrain
	base *= attacker.damage_output_multiplier
	var defence: float = defence_multiplier_of(attacker, defender, Elements.Element.NONE, terrain)
	var elemental: float = elemental_multiplier_of(defender, Elements.Element.NONE)
	var expected_random: float = (BattleConfig.DAMAGE_RANDOM_MIN
		+ BattleConfig.DAMAGE_RANDOM_MAX) * 0.5
	var broken_multiplier := 1.0
	if defender.is_broken():
		broken_multiplier += BattleConfig.BREAK_DAMAGE_BONUS
	var expected := maxi(0, ceili(
		(base * defence * elemental * expected_random) * broken_multiplier))
	return {
		"damage": ceili(tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE),
		"tiles": tile_count,
		"effective_attack": effective_attack,
		"attack_factor": 1.0,
		"attack": attacker.attack_multiplier,
		"ultimate": attacker.damage_output_multiplier,
		"attack_terrain": attack_terrain,
		"base": base,
		"other": BattleConfig.OTHER_MULTIPLIER_DEFAULT,
		"defence": defence,
		"elemental": elemental,
		"break": 1.0,
		"random": expected_random,
		"expected": expected,
	}

static func explain_spell(raw: float, attacker: CombatantState,
		defender: CombatantState, element: int, other_multiplier: float,
		terrain: TerrainDefinition = null) -> Dictionary:
	var effective_attack := maxf(1.0, attacker.attack) \
		* BattleConfig.SPELL_ATTACK_FACTOR
	var attack_terrain: float = _attack_multiplier(attacker, element, terrain)
	var base := raw * effective_attack * attacker.attack_multiplier
	base *= attack_terrain
	base *= attacker.damage_output_multiplier
	var defence: float = defence_multiplier_of(attacker, defender, element, terrain)
	var elemental: float = elemental_multiplier_of(defender, element)
	var expected_random: float = (BattleConfig.DAMAGE_RANDOM_MIN
		+ BattleConfig.DAMAGE_RANDOM_MAX) * 0.5
	var broken_multiplier := 1.0
	if defender.is_broken():
		broken_multiplier += BattleConfig.BREAK_DAMAGE_BONUS
	var expected := maxi(0, ceili(
		(base * other_multiplier * defence * elemental * expected_random)
		* broken_multiplier))
	return {
		"damage": raw,
		"base": base,
		"effective_attack": effective_attack,
		"attack_factor": BattleConfig.SPELL_ATTACK_FACTOR,
		"attack": attacker.attack_multiplier,
		"ultimate": attacker.damage_output_multiplier,
		"attack_terrain": attack_terrain,
		"other": other_multiplier,
		"defence": defence,
		"elemental": elemental,
		"break": 1.0,
		"random": expected_random,
		"expected": expected,
	}

static func defence_multiplier_of(attacker: CombatantState, defender: CombatantState,
		element: int = Elements.Element.NONE, terrain: TerrainDefinition = null) -> float:
	if attacker == null or defender == null:
		return 1.0
	var effective_attack: float = maxf(1.0,
		attacker.attack * attacker.attack_multiplier)
	var effective_defence: float = maxf(0.0,
		defender.defence * defender.defence_multiplier)
	if terrain != null:
		effective_defence *= terrain.defence_multiplier_for(element)
	var compared_defence: float = effective_defence \
		* BattleConfig.DEFENCE_REFERENCE_ATTACK / effective_attack
	return BattleConfig.DEFENCE_MULTIPLIER_BASE / (
		BattleConfig.DEFENCE_MULTIPLIER_BASE + compared_defence)

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