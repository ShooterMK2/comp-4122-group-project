class_name BattleSession
extends RefCounted
# All battle rules for one fight, with no nodes and no UI. The controller calls these methods
# after checking BattleFlow, and redraws afterwards. Methods that can be refused return an
# error text ("" = success).

signal log_line(kind: String, text: String)

const ULTIMATE_MIN_CHARGE := 100.0   # must equal the literal in UltimateResolver.charge_ratio
const STAT_NAMES := ["ATK", "DEF", "SPD"]

var state: BattleState
var board := CastingBoardModel.new()
var deck: TurnDeck
var spells: Array[SpellDefinition] = []
var queue: Array[QueuedSpell] = []
var outlined: Dictionary = {}          # cell -> colour, the matched cells shown on the board
var ghosts: Dictionary = {}            # cell -> element of those cells
var placed_this_turn := 0
var spell_damage_total := 0
var basic_damage_total := 0


func _init(p_state: BattleState, p_draw: FragmentDeckDraw, p_spells: Array[SpellDefinition]) -> void:
	state = p_state
	deck = TurnDeck.new(p_draw)
	spells = p_spells


# ---------- outcome and turn order ----------

func outcome() -> int:
	if state.player.is_dead():
		return -1
	if state.all_enemies_dead():
		return 1
	return 0


func next_actor() -> int:
	var lines: Array[String] = []
	var actor := TurnOrderSystem.next_actor(state, lines)
	say_lines(lines)
	return actor


func run_enemy_turn(actor: int) -> String:
	var index := actor - 1
	var text := intent_text(index)
	var lines: Array[String] = []
	TurnResolver.run_enemy_action(state, index, lines)
	say_lines(lines)
	TurnOrderSystem.finish_action(state, actor)
	return text


func intent_text(index: int) -> String:
	var enemy := state.enemies[index]
	if enemy.is_dead():
		return "Destroyed"
	if enemy.is_broken():
		return "BROKEN (skips turn)"
	if enemy.get_status(StatusTypes.Status.FREEZE) > 0:
		return "FROZEN (skips turn)"
	var skill: SkillDefinition = EnemyIntentSystem.pick_skill(state.enemy_defs[index], state.turn)
	return skill.display_name if skill != null else "Idle"


# ---------- player turn ----------

func begin_player_turn() -> void:
	state.ultimate_active = false
	state.player.set_damage_output_multiplier(1.0)
	board.advance_special_tiles()
	state.player.advance_stat_tile_turn()
	for enemy in state.enemies:
		enemy.advance_stat_tile_turn()
	state.ensure_valid_target()
	say("round", "--- Your turn (round %d) ---" % state.turn)
	var tiles := board.spawn_special_tiles()
	if not tiles.is_empty():
		var names: Array[String] = []
		for tile in tiles:
			names.append(_special_name(tile))
		say("system", "Special tiles appeared: %s." % ", ".join(names))
	var count := maxi(1, BattleConfig.HAND_SIZE - state.overload_debt)
	if state.overload_debt > 0:
		say("system", "Overload: you draw %d fewer fragments this turn." % state.overload_debt)
		state.overload_debt = 0
	deck.draw_hand(count)
	placed_this_turn = 0
	spell_damage_total = 0
	basic_damage_total = 0
	outlined.clear()
	ghosts.clear()


func finish_player_turn(lines: Array[String] = []) -> void:
	TurnResolver.end_turn_effects(state.player, lines)
	say_lines(lines)
	TurnOrderSystem.finish_action(state, TurnOrderSystem.PLAYER)
	deck.end_turn()
	queue.clear()
	outlined.clear()
	ghosts.clear()


# ---------- chanting: fragments and matching ----------

func place_fragment(index: int, anchor: Vector2i) -> String:
	var fragment := deck.fragment_at(index)
	if fragment == null:
		return "Select a fragment first."
	if not board.place(fragment, anchor):
		return "Can't place there."
	deck.play(index)
	placed_this_turn += fragment.cells.size()
	outlined.clear()
	ghosts.clear()
	_resolve_matches()
	return ""


func _resolve_matches() -> void:
	var match_index := 0
	while true:
		var choices: Array = SpellMatcher.find_matches(board, spells)
		if choices.is_empty():
			break
		_commit_match(_best_match(choices), match_index)
		match_index += 1


# Strategy: highest base damage, then most tiles, then earlier in the deck.
# Replace this one function to offer the player a choice instead.
func _best_match(choices: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_key: Array = []
	for hit: Dictionary in choices:
		var spell: SpellDefinition = hit["spell"]
		var key: Array = [spell.base_damage, (hit["cells"] as Array).size(), -spells.find(spell)]
		if best.is_empty() or key > best_key:
			best = hit
			best_key = key
	return best


func _commit_match(hit: Dictionary, match_index: int) -> void:
	var color := Color.from_hsv(float(match_index % 12) / 12.0, 0.8, 1.0)
	var cells: Array = hit["cells"]
	var elements: Array = hit["elements"]
	var special: Array = hit["special_tiles"]
	for i in cells.size():
		outlined[cells[i]] = color
		ghosts[cells[i]] = elements[i]
	board.clear_cells(cells)
	var element_list: Array[int] = []
	for e in elements:
		element_list.append(e)
	var special_list: Array[int] = []
	for t in special:
		special_list.append(t)
	var spell: SpellDefinition = hit["spell"]
	queue.append(QueuedSpell.new(spell, element_list, special_list))
	for fx in spell.effects:
		if fx.kind == SpellEffect.Kind.OVERLOAD:
			deck.draw_extra(fx.amount)
			state.overload_debt += fx.amount2
			say("system", "Overload! Drew %d extra fragments, next turn -%d." % [fx.amount, fx.amount2])
	say("player", "Formed %s." % spell.display_name)


func queued_count(definition: SpellDefinition) -> int:
	var n := 0
	for q in queue:
		if q.definition == definition:
			n += 1
	return n


func first_queued(definition: SpellDefinition) -> QueuedSpell:
	for q in queue:
		if q.definition == definition:
			return q
	return null


func is_deadlocked() -> bool:
	return not state.over and placed_this_turn == 0 and queue.is_empty() \
			and DeadlockDetector.is_deadlocked(board, deck.hand)


# ---------- casting ----------

func start_casting() -> void:
	spell_damage_total = 0
	basic_damage_total = 0
	say("system", "Casting begins: %d spells built, %d tiles on the board." % [
			queue.size(), board.filled_count()])


# target_index: enemy slot, or -1 for the player (self-target spells only).
func cast_queued(definition: SpellDefinition, target_index: int) -> String:
	var queue_index := -1
	for i in queue.size():
		if queue[i].definition == definition:
			queue_index = i
			break
	if queue_index < 0:
		return "That spell is not in your queue."
	var is_self := definition.target_kind == SpellDefinition.TargetKind.SELF
	if is_self != (target_index < 0):
		return "Drop this spell on yourself." if is_self else "Drop this spell on an enemy."
	if target_index >= 0:
		if target_index >= state.enemies.size() or state.enemies[target_index].is_dead():
			return "Choose a living enemy."
		state.target_index = target_index
	var q: QueuedSpell = queue.pop_at(queue_index)
	var lines: Array[String] = []
	spell_damage_total += SpellResolver.resolve_spell(q, state, lines)
	_add_charge(_charge_for(q))
	say_lines(lines)
	var hit := state.player if is_self else state.enemies[target_index]
	say("system", "- %s now at HP %d/%d" % [hit.display_name, hit.hp, hit.max_hp])
	TurnOrderSystem.refresh(state)
	return ""


func cast_basic_attack() -> void:
	var tiles := board.filled_count()
	state.ensure_valid_target()
	var lines: Array[String] = []
	basic_damage_total = SpellResolver.resolve_basic_attack(tiles, state, lines)
	if tiles > 0:
		_add_charge(BattleConfig.CHARGE_BASIC_ATTACK)
	say_lines(lines)


func turn_total_line() -> String:
	return "Turn total: spells %d + tiles %d = %d" % [spell_damage_total, basic_damage_total,
			spell_damage_total + basic_damage_total]


func _charge_for(q: QueuedSpell) -> float:
	var cells := q.definition.pattern.cells.size()
	var charge: float = BattleConfig.CHARGE_LEVEL_1
	if cells >= 8:
		charge = BattleConfig.CHARGE_LEVEL_3
	elif cells >= 5:
		charge = BattleConfig.CHARGE_LEVEL_2
	charge += q.special_tiles.size() * BattleConfig.CHARGE_SPECIAL_TILE
	return charge


func _add_charge(amount: float) -> void:
	if state.ultimate_active:
		return
	state.charge_gauge = minf(BattleConfig.CHARGE_GAUGE_MAX, state.charge_gauge + amount)


# ---------- ultimate ----------

func can_use_ultimate() -> bool:
	return not state.over and not state.ultimate_active and state.charge_gauge >= ULTIMATE_MIN_CHARGE


func use_ultimate() -> bool:
	if not can_use_ultimate():
		return false
	var spent := state.charge_gauge
	state.charge_gauge = 0.0
	var lines: Array[String] = []
	UltimateResolver.activate(state, RunState.equipped_ultimate(), spent, lines)
	say_lines(lines)
	return true


# ---------- deadlock ----------

func backlash_check() -> Dictionary:
	return DeadlockResolver.check_backlash(state)


func backlash() -> bool:
	var lines: Array[String] = []
	var ok := DeadlockResolver.backlash(state, board, lines)
	say_lines(lines)
	if ok:
		outlined.clear()
		ghosts.clear()
	return ok


func fizzle() -> void:
	var lines: Array[String] = []
	DeadlockResolver.fizzle(board, lines)
	say_lines(lines)
	outlined.clear()
	ghosts.clear()


# ---------- log ----------

func say(kind: String, text: String) -> void:
	log_line.emit(kind, text)


func say_lines(lines: Array[String]) -> void:
	for line in lines:
		log_line.emit(_classify(line), line)


func _classify(line: String) -> String:
	if line.begins_with("=") or line.begins_with("---"):
		return "round"
	if "Shield Break" in line or "SHATTER" in line:
		return "weak"
	if line.begins_with(state.player.display_name):
		return "player"
	for enemy in state.enemies:
		if line.begins_with(enemy.display_name):
			return "enemy"
	return "system"


static func _special_name(tile: int) -> String:
	if CastingBoardModel.is_heal(tile):
		return "Heal"
	var prefix := "Buff" if CastingBoardModel.is_buff(tile) else "Debuff"
	return "%s %s" % [prefix, STAT_NAMES[CastingBoardModel.special_stat(tile)]]
