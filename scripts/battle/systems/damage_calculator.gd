class_name DamageCalculator
extends RefCounted

# Hook for attacker modifiers. Chill used to live here; it now slows turn order instead.
static func finalize(raw: int, _attacker: CombatantState) -> int:
	return maxi(0, raw)

static func basic_attack(tile_count: int, attacker: CombatantState) -> int:
	return finalize(tile_count * BattleConfig.BASIC_DAMAGE_PER_TILE, attacker)