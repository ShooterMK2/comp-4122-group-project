class_name BattleState
extends RefCounted

var player: CombatantState
var enemies: Array[CombatantState] = []
var enemy_defs: Array[EnemyDefinition] = []
var target_index := 0
var turn := 0
var over := false
var overload_debt := 0
var discharge_uses := 0   # Backlash uses this battle (drives the HP cost progression)

func _init(defs: Array[EnemyDefinition] = []) -> void:
	player = CombatantState.new("Player", BattleConfig.PLAYER_MAX_HP)
	for i in defs.size():
		enemy_defs.append(defs[i])
		enemies.append(CombatantState.new(
			"%s %s" % [defs[i].display_name, char(65 + i)], defs[i].max_hp))

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
	s.target_index = target_index
	s.turn = turn
	s.over = over
	s.overload_debt = overload_debt
	s.discharge_uses = discharge_uses
	return s