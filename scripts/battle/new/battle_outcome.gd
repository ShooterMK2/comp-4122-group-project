class_name BattleOutcome
extends RefCounted
# Writes the finished battle back into RunState and builds the BattleResult.
# Rewards (card / item choice) are the next milestone and will hook in here.


static func conclude(state: BattleState, won: bool) -> BattleResult:
	var result := BattleResult.new()
	result.won = won
	result.run_over = not won
	result.rounds = state.turn
	result.hp_left = maxi(state.player.hp, 0)
	if won:
		RunState.set_run_hp(state.player.hp)
		result.xp_gained = LevelProgression.battle_xp_for_enemies(state.enemy_defs)
		result.levels_gained = RunState.grant_battle_xp(state.enemy_defs)
		if RunState.has_pending_level_ups():
			var pending: Dictionary = RunState.peek_pending_level_up()
			result.level_up_text = "Level up! Lv %d (%s)" % [
				int(pending.get("level", 0)), str(pending.get("stat_text", ""))]
	RunState.clear_pending_after_battle()
	return result
