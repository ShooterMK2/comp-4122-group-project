class_name CombatantState
extends RefCounted

var display_name := ""
var max_hp := 1
var hp := 1
var level := 1
var attack := 1
var defence := 0
var attack_multiplier := 1.0
var defence_multiplier := 1.0
var speed_multiplier := 1.0
var damage_output_multiplier := 1.0
var stat_buff_turns: Array[int] = [0, 0, 0]
var stat_debuff_turns: Array[int] = [0, 0, 0]
var elemental_weaknesses: Array[int] = []
var elemental_strengths: Array[int] = []
var shield := 0
var statuses := {}
var break_rank := EnemyDefinition.Rank.MINOR
var break_hits := 0
var break_threshold := 0
var break_last_processed_turn := -1

func _init(p_name: String = "", p_max_hp: int = 1, p_level: int = 1,
		p_attack: int = 1, p_defence: int = 0) -> void:
	display_name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	level = p_level
	attack = p_attack
	defence = p_defence

static func from_definition(definition: CombatantDefinition,
		name_override: String = "") -> CombatantState:
	var name := definition.display_name if name_override.is_empty() else name_override
	var state := CombatantState.new(name, definition.max_hp, definition.level,
		definition.attack, definition.defence)
	state.elemental_weaknesses = definition.elemental_weaknesses.duplicate()
	state.elemental_strengths = definition.elemental_strengths.duplicate()
	if definition is EnemyDefinition:
		state.break_rank = definition.rank
		state.break_threshold = _break_threshold_for(definition.rank)
	return state

static func _break_threshold_for(rank: int) -> int:
	if rank == EnemyDefinition.Rank.MINOR:
		return randi_range(BattleConfig.BREAK_MINOR_HITS_MIN, BattleConfig.BREAK_MINOR_HITS_MAX)
	return randi_range(BattleConfig.BREAK_ELITE_HITS_MIN, BattleConfig.BREAK_ELITE_HITS_MAX)


func get_status(s: int) -> int:
	return statuses.get(s, 0)

func add_status(s: int, n: int) -> void:
	statuses[s] = get_status(s) + n

func consume_status(s: int, n: int = -1) -> int:
	var cur := get_status(s)
	var take := cur if n < 0 else mini(n, cur)
	if cur - take <= 0:
		statuses.erase(s)
	else:
		statuses[s] = cur - take
	return take

func take_damage(amount: int) -> Dictionary:
	var incoming := amount
	var absorbed := 0
	if shield > 0:
		incoming = ceili(amount * (1.0 - BattleConfig.SHIELD_DAMAGE_REDUCTION))
		absorbed = amount - incoming
		shield -= 1
	var lost := mini(hp, incoming)
	hp -= lost
	return {"absorbed": absorbed, "hp": lost}

func heal(n: int) -> int:
	var healed := mini(n, max_hp - hp)
	hp += healed
	return healed

func is_dead() -> bool:
	return hp <= 0

func duplicate_state() -> CombatantState:
	var c := CombatantState.new(display_name, max_hp, level, attack, defence)
	c.elemental_weaknesses = elemental_weaknesses.duplicate()
	c.elemental_strengths = elemental_strengths.duplicate()
	c.attack_multiplier = attack_multiplier
	c.defence_multiplier = defence_multiplier
	c.speed_multiplier = speed_multiplier
	c.damage_output_multiplier = damage_output_multiplier
	c.stat_buff_turns = stat_buff_turns.duplicate()
	c.stat_debuff_turns = stat_debuff_turns.duplicate()
	c.hp = hp
	c.shield = shield
	c.statuses = statuses.duplicate()
	c.break_rank = break_rank
	c.break_hits = break_hits
	c.break_threshold = break_threshold
	c.break_last_processed_turn = break_last_processed_turn
	return c

func apply_stat_tile(stat: int, is_buff: bool) -> void:
	if stat < 0 or stat >= stat_buff_turns.size():
		return
	var own_turns: Array[int] = stat_buff_turns if is_buff else stat_debuff_turns
	var opposite_turns: Array[int] = stat_debuff_turns if is_buff else stat_buff_turns
	opposite_turns[stat] = 0
	own_turns[stat] += BattleConfig.SPECIAL_TILE_EFFECT_TURNS
	_refresh_stat_multipliers()

func advance_stat_tile_turn() -> void:
	for stat in stat_buff_turns.size():
		stat_buff_turns[stat] = maxi(0, stat_buff_turns[stat] - 1)
		stat_debuff_turns[stat] = maxi(0, stat_debuff_turns[stat] - 1)
	_refresh_stat_multipliers()

func clear_stat_tiles() -> void:
	stat_buff_turns = [0, 0, 0]
	stat_debuff_turns = [0, 0, 0]
	_refresh_stat_multipliers()

func set_damage_output_multiplier(multiplier: float) -> void:
	damage_output_multiplier = multiplier

func _refresh_stat_multipliers() -> void:
	attack_multiplier = _stat_multiplier(0)
	defence_multiplier = _stat_multiplier(1)
	speed_multiplier = _stat_multiplier(2)

func _stat_multiplier(stat: int) -> float:
	if stat_buff_turns[stat] > 0:
		return 1.0 + BattleConfig.SPECIAL_TILE_STAT_MULTIPLIER
	if stat_debuff_turns[stat] > 0:
		return 1.0 - BattleConfig.SPECIAL_TILE_STAT_MULTIPLIER
	return 1.0

func is_broken() -> bool:
	return get_status(StatusTypes.Status.BREAK) > 0

func register_weakness_hit() -> bool:
	if is_broken():
		return false
	break_hits += 1
	if break_hits < break_threshold:
		return false
	add_status(StatusTypes.Status.BREAK, BattleConfig.BREAK_TURNS)
	break_last_processed_turn = -1
	return true

func finish_break_turn(turn: int) -> void:
	if break_last_processed_turn == turn:
		return
	break_last_processed_turn = turn
	consume_status(StatusTypes.Status.BREAK)
	if not is_broken():
		break_hits = 0