class_name AilmentSystem
extends RefCounted

const A := AilmentTypes.Ailment

static func describe(c: CombatantState) -> String:
	if c.ailments.is_empty():
		return ""
	var parts: Array[String] = []
	for a in c.ailments.keys():
		parts.append("%s(%d)" % [AilmentTypes.ailment_name(a), c.ailments[a]])
	return ", ".join(parts)

# End of afflicted unit's turn: Poison damage, then tick all ailment durations.
static func end_turn(c: CombatantState, _log: Array[String]) -> void:
	if c.has_ailment(A.POISON):
		var dmg := StatusSystem.deal_direct(c, BattleConfig.AILMENT_POISON_DAMAGE)
		_log.append("%s takes %d Poison damage." % [c.display_name, dmg])
	c.tick_ailments()
