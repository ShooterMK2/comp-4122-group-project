class_name BattleState
extends RefCounted

var player: CombatantState
var enemies: Array[CombatantState] = []
var enemy_defs: Array[EnemyDefinition] = []
var target_index := 0          # remembered cast target (last choice)
var turn := 0                  # round counter
var over := false
var overload_debt := 0
var backlash_uses := 0         # Backlash uses this battle (drives the HP cost progression)

# Speed / turn order (actor ids: 0 = player, enemy i = i + 1)
var player_speed: float = 1.0
var enemy_speeds: Array[float] = []
var pending_actors: Array[int] = []
var acted_actors: Array[int] = []
var current_actor := -1

func _init(defs: Array[EnemyDefinition] = []) -> void:
	var player_definition := PlayerDefinition.default_player()
	player = CombatantState.from_definition(player_definition)
	player_speed = player_definition.speed
	for i in defs.size():
		enemy_defs.append(defs[i])
		enemy_speeds.append(defs[i].speed)
		enemies.append(CombatantState.from_definition(defs[i],
			"%s %s" % [defs[i].display_name, char(65 + i)]))

func all_enemies_dead() -> bool:
	for e in enemies:
		if not e.is_dead():
			return false
	return true

func ensure_valid_target() -> void:
	if enemies.is_empty() or not enemies[target_index].is_dead():
		return
	for i in enemies.size():
		if not enemies[i].is_dead():
			target_index = i
			return

# Living enemies directly left/right of index i.
func adjacent_indices(i: int) -> Array[int]:
	var out: Array[int] = []
	for j in [i - 1, i + 1]:
		if j >= 0 and j < enemies.size() and not enemies[j].is_dead():
			out.append(j)
	return out

func duplicate_state() -> BattleState:
	var s := BattleState.new()
	s.player = player.duplicate_state()
	for i in enemies.size():
		s.enemies.append(enemies[i].duplicate_state())
		s.enemy_defs.append(enemy_defs[i])
		s.enemy_speeds.append(enemy_speeds[i])
	s.target_index = target_index
	s.turn = turn
	s.over = over
	s.overload_debt = overload_debt
	s.backlash_uses = backlash_uses
	s.player_speed = player_speed
	for a in pending_actors:
		s.pending_actors.append(a)
	for a in acted_actors:
		s.acted_actors.append(a)
	s.current_actor = current_actor
	return s

# Living neighbours of a target within its own side.
func adjacent_to(target: CombatantState) -> Array[CombatantState]:
	var out: Array[CombatantState] = []
	var i := enemies.find(target)
	if i < 0:
		return out
	for j in adjacent_indices(i):
		out.append(enemies[j])
	return out