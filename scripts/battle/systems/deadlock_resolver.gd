class_name DeadlockResolver
extends RefCounted
# Resolves a deadlocked casting board. Both options end the player's turn:
#   Backlash - pay HP, clear the board, tiles deal base damage
#   Fizzle   - free clear, no damage

# HP cost = (BASE + PROGRESSION * earlier uses) * max HP, rounded up.
static func hp_cost(state: BattleState) -> int:
	var frac: float = BattleConfig.BACKLASH_BASE_FRACTION \
			+ BattleConfig.BACKLASH_PROGRESSION_FRACTION * state.backlash_uses
	return maxi(1, ceili(snappedf(state.player.max_hp * frac, 0.001)))

# Returns {"ok": bool, "cost": int, "reason": String}
static func check_backlash(state: BattleState) -> Dictionary:
	var cost := hp_cost(state)
	if state.player.hp - cost < BattleConfig.BACKLASH_MIN_HP_AFTER:
		return {"ok": false, "cost": cost,
			"reason": "Not enough HP: Backlash must leave you with at least %d." % BattleConfig.BACKLASH_MIN_HP_AFTER}
	return {"ok": true, "cost": cost, "reason": ""}

# Ends your turn (the controller calls _finish_turn afterwards).
static func backlash(state: BattleState, board: CastingBoardModel, _log: Array[String]) -> bool:
	var check := check_backlash(state)
	if not check["ok"]:
		_log.append(check["reason"])
		return false
	var cost: int = check["cost"]
	var tiles := board.filled_count()
	state.player.hp -= cost
	state.backlash_uses += 1
	board.reset()
	_log.append("Backlash! You lose %d HP and %d tile(s) discharge." % [cost, tiles])
	SpellResolver.resolve_basic_attack(tiles, state, _log)
	return true

# Also ends your turn.
static func fizzle(board: CastingBoardModel, _log: Array[String]) -> void:
	var tiles := board.filled_count()
	board.reset()
	_log.append("Fizzle: %d tile(s) fade away." % tiles)