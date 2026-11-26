class_name TurnOrderForecast
extends RefCounted
# The next N actors for the turn-order bar.
# The rest of this round comes from state.pending_actors. Later rounds are projected with
# TODAY's speeds, using the same sort as TurnOrderSystem, so they can still change
# (Chill, buffs, deaths).


static func upcoming(state: BattleState, count: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var round_no := state.turn
	for a in state.pending_actors:
		if not TurnOrderSystem.is_alive(state, a):
			continue
		var when := "Acting now" if out.is_empty() else "Later this round"
		out.append(_entry(state, a, round_no, when))
		if out.size() >= count:
			return out
	for _i in count:
		if out.size() >= count:
			break
		round_no += 1
		var ids := _alive_by_speed(state)
		if ids.is_empty():
			break
		for a in ids:
			var when := "Acting now" if out.is_empty() else "Round %d (projected)" % round_no
			out.append(_entry(state, a, round_no, when))
			if out.size() >= count:
				break
	return out


static func _entry(state: BattleState, actor: int, round_no: int, when: String) -> Dictionary:
	var c := TurnOrderSystem.combatant(state, actor)
	return {
		"actor": actor,
		"name": c.display_name,
		"round": round_no,
		"when": when,
		"hp": c.hp,
		"max_hp": c.max_hp,
		"speed": TurnOrderSystem.effective_speed(state, actor),
		"status": CombatantText.status_line(c),
	}


static func _alive_by_speed(state: BattleState) -> Array[int]:
	var ids: Array[int] = []
	for a in state.enemies.size() + 1:
		if TurnOrderSystem.is_alive(state, a):
			ids.append(a)
	ids.sort_custom(func(a: int, b: int) -> bool:
		var sa := TurnOrderSystem.effective_speed(state, a)
		var sb := TurnOrderSystem.effective_speed(state, b)
		if not is_equal_approx(sa, sb):
			return sa > sb
		return a < b)       # tie: player first, then lower enemy slot
	return ids
