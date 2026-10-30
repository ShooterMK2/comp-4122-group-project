class_name TurnOrderSystem
extends RefCounted
# Actor ids: PLAYER = 0, enemy i = i + 1.
# Order is re-sorted after every spell and every action, so Chill etc. update it on time.

const PLAYER := 0

static func combatant(state: BattleState, actor: int) -> CombatantState:
	return state.player if actor == PLAYER else state.enemies[actor - 1]

static func actor_name(state: BattleState, actor: int) -> String:
	return "You" if actor == PLAYER else state.enemies[actor - 1].display_name

static func is_alive(state: BattleState, actor: int) -> bool:
	return not combatant(state, actor).is_dead()

# Base speed reduced by Chill: base * max(1 - chill * per_stack, min_fraction)
static func effective_speed(state: BattleState, actor: int) -> float:
	var base: float = state.player_speed if actor == PLAYER else state.enemy_speeds[actor - 1]
	var chill := combatant(state, actor).get_status(StatusTypes.Status.CHILL)
	var mult := maxf(1.0 - chill * BattleConfig.CHILL_SPEED_REDUCTION_PER_STACK,
			BattleConfig.CHILL_MIN_SPEED_FRACTION)
	return base * mult

static func _sorted(state: BattleState, ids: Array[int]) -> Array[int]:
	ids.sort_custom(func(a: int, b: int) -> bool:
		var sa := effective_speed(state, a)
		var sb := effective_speed(state, b)
		if not is_equal_approx(sa, sb):
			return sa > sb
		return a < b)   # tie: player first, then lower enemy slot
	return ids

static func begin_round(state: BattleState, _log: Array[String]) -> void:
	state.turn += 1
	state.acted_actors.clear()
	var ids: Array[int] = []
	for a in state.enemies.size() + 1:
		if is_alive(state, a):
			ids.append(a)
	state.pending_actors = _sorted(state, ids)
	_log.append("=== Round %d ===" % state.turn)

# Returns the actor whose turn it is, starting a new round if needed. -1 = nobody left.
static func next_actor(state: BattleState, _log: Array[String]) -> int:
	refresh(state)
	if state.pending_actors.is_empty():
		begin_round(state, _log)
	if state.pending_actors.is_empty():
		state.current_actor = -1
		return -1
	state.current_actor = state.pending_actors[0]
	return state.current_actor

static func finish_action(state: BattleState, actor: int) -> void:
	state.pending_actors.erase(actor)
	state.acted_actors.append(actor)
	state.current_actor = -1
	refresh(state)

# Drop the dead and re-sort everyone who has not acted yet.
# The actor currently taking a turn always stays first.
static func refresh(state: BattleState) -> void:
	var ids: Array[int] = []
	var keep_first := false
	for a in state.pending_actors:
		if not is_alive(state, a):
			continue
		if a == state.current_actor:
			keep_first = true
		else:
			ids.append(a)
	ids = _sorted(state, ids)
	if keep_first:
		ids.push_front(state.current_actor)
	state.pending_actors = ids

# For the UI: [{"name", "speed", "state": "done" | "now" | "next"}]
static func summary(state: BattleState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a in state.acted_actors:
		if is_alive(state, a):
			out.append({"name": actor_name(state, a),
				"speed": effective_speed(state, a), "state": "done"})
	for a in state.pending_actors:
		out.append({"name": actor_name(state, a), "speed": effective_speed(state, a),
			"state": "now" if a == state.current_actor else "next"})
	return out