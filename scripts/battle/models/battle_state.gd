class_name BattleState
extends RefCounted

var player: CombatantState
var enemies: Array[CombatantState] = []
var enemy_defs: Array[EnemyDefinition] = []
var terrain: TerrainDefinition
var target_index := 0          # remembered cast target (last choice)
var turn := 0                  # round counter
var over := false
var overload_debt := 0
var backlash_uses := 0         # Backlash uses this battle (drives the HP cost progression)
var charge_gauge := 0.0
var ultimate_active := false

# Speed / turn order (actor ids: 0 = player, enemy i = i + 1)
var player_speed: float = 1.0
var enemy_speeds: Array[float] = []
var pending_actors: Array[int] = []
var acted_actors: Array[int] = []
var current_actor := -1
var encounter_level: int = 1

func _init(defs: Array[EnemyDefinition] = [], p_terrain: TerrainDefinition = null,
		from_run: bool = true) -> void:
	terrain = p_terrain if p_terrain != null else TerrainSystem.plain()
	if from_run and Engine.get_main_loop() != null and Engine.get_main_loop().root != null \
			and Engine.get_main_loop().root.get_node_or_null("RunState") != null:
		_init_player_from_run(Engine.get_main_loop().root.get_node("RunState"))
	else:
		_init_player_from_definition(PlayerDefinition.default_player())
	encounter_level = 1
	for i in defs.size():
		enemy_defs.append(defs[i])
		enemy_speeds.append(defs[i].speed)
		encounter_level = maxi(encounter_level, defs[i].level)
		enemies.append(CombatantState.from_definition(defs[i],
			"%s %s" % [defs[i].display_name, char(65 + i)]))
	_apply_overlevel_compare_levels()

func _init_player_from_run(run: Node) -> void:
	var snap: PlayerStatSnapshot = run.snapshot()
	player = CombatantState.new(snap.display_name, snap.max_hp(), snap.level,
		snap.attack(), snap.defence())
	player.hp = clampi(run.run_hp, 1, snap.max_hp())
	player.elemental_weaknesses = snap.elemental_weaknesses.duplicate()
	player.elemental_strengths = snap.elemental_strengths.duplicate()
	player.shield = snap.start_shield
	player.damage_taken_multiplier = snap.damage_taken_multiplier
	player.fire_spell_damage_mult = snap.fire_spell_damage_mult
	player.is_player = true
	player.compare_level = player.level
	player_speed = snap.speed()

func _init_player_from_definition(player_definition: PlayerDefinition) -> void:
	player = CombatantState.from_definition(player_definition)
	player.is_player = true
	player.compare_level = player.level
	player_speed = player_definition.speed

func _apply_overlevel_compare_levels() -> void:
	if player == null:
		return
	player.is_player = true
	player.compare_level = encounter_level
	for e in enemies:
		e.is_player = false
		e.compare_level = player.level

func living_encounter_level() -> int:
	var lv := 1
	var any := false
	for e in enemies:
		if e.is_dead():
			continue
		any = true
		lv = maxi(lv, e.level)
	return lv if any else encounter_level

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
	var s := BattleState.new([], terrain, false)
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
	s.charge_gauge = charge_gauge
	s.ultimate_active = ultimate_active
	s.player_speed = player_speed
	s.terrain = terrain
	s.encounter_level = encounter_level
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
