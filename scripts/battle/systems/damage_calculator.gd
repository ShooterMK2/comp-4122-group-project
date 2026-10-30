class_name DamageCalculator
extends RefCounted

# Multiplier applied to an attacker's outgoing damage because of its own Chill.
static func chill_multiplier(attacker: CombatantState) -> float:
	var reduction := attacker.get_status(StatusTypes.Status.CHILL) * BattleConfig.CHILL_REDUCTION_PER_STACK
	return maxf(1.0 - reduction, BattleConfig.CHILL_MIN_DAMAGE_FRACTION)

# Final damage of one hit: raw * chill multiplier (rounded).
static func finalize(raw: int, attacker: CombatantState) -> int:
	if raw <= 0:
		return 0
	return maxi(1, roundi(raw * chill_multiplier(attacker)))

static func basic_attack(tile_count: int, attacker: CombatantState) -> int:
	return finalize(tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE, attacker)