class_name StatusSystem
extends RefCounted

const S := StatusTypes.Status

static func describe(c: CombatantState) -> String:
	var parts: Array[String] = []
	if c.shield > 0:
		parts.append("Shield %d" % c.shield)
	for s in c.statuses.keys():
		parts.append("%s %d" % [StatusTypes.status_name(s), c.statuses[s]])
	return ", ".join(parts) if not parts.is_empty() else "-"

# Damage that may bypass shield (DoTs, Detonate, Corruption). Returns HP/shield lost.
static func deal_direct(target: CombatantState, amount: int) -> int:
	if amount <= 0:
		return 0
	if BattleConfig.DOT_IGNORES_SHIELD:
		var lost := mini(target.hp, amount)
		target.hp -= lost
		return lost
	var r := target.take_damage(amount)
	return r["hp"] + r["absorbed"]

# Adds stacks, then handles threshold conversions. Returns extra damage dealt.
static func apply_status(target: CombatantState, status: int, n: int, _log: Array[String]) -> int:
	var dealt := 0
	target.add_status(status, n)
	match status:
		S.BURN:
			if target.get_status(S.BURN) >= BattleConfig.DETONATE_THRESHOLD:
				var stacks := target.consume_status(S.BURN)
				dealt += deal_direct(target, BattleConfig.DETONATE_FIXED_DAMAGE)
				_log.append("%s: Burn reached the Detonate threshold! %d stacks consumed, %d dmg." % [
					target.display_name, stacks, BattleConfig.DETONATE_FIXED_DAMAGE])
		S.CHILL:
			while target.get_status(S.CHILL) >= BattleConfig.FREEZE_THRESHOLD:
				target.consume_status(S.CHILL, BattleConfig.FREEZE_THRESHOLD)
				target.add_status(S.FREEZE, BattleConfig.FREEZE_STACKS_PER_CONVERSION)
				_log.append("%s: Chill reached the Freeze threshold -> Frozen!" % target.display_name)
		S.DECAY:
			while target.get_status(S.DECAY) >= BattleConfig.CORRUPTION_THRESHOLD:
				target.consume_status(S.DECAY, BattleConfig.CORRUPTION_THRESHOLD)
				target.add_status(S.CORRUPTION, 1)
				_log.append("%s: Decay reached the Corruption threshold -> +1 Corruption." % target.display_name)
	return dealt