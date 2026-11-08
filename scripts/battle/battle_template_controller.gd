extends Control
# Thin coordinator for Battle_Scene_Template. Wires UI signals to systems.
# TODO: deadlock overlay scene, debug panel scene, turn-order bar scene.

const DEBUG_GRANT_KEY := KEY_F3     # TUNABLE: debug key; grants one copy of every spell

var state: BattleState
var board := CastingBoardModel.new()
var spells: Array[SpellDefinition] = []
var hand: Array[FragmentData] = []
var queue: Array[QueuedSpell] = []          # built spells waiting to be cast (shown as cards with counters)
var selected := -1                          # selected hand index, -1 = none

var _outlined: Dictionary = {}
var _ghosts: Dictionary = {}
var _snapshot_hand: Array[FragmentData] = []
var _snapshot_board: Dictionary = {}
var _snapshot_charge_gauge := 0.0
var _snapshot_ultimate_active := false
var _snapshot_damage_multiplier := 1.0
var _placed_this_turn := 0                  # used to detect a deadlock (nothing placed yet this turn)

var _casting := false                       # true during the Casting Period
var _selected_spell: SpellDefinition = null
var _inspect_player := false
var _awaiting_enemy := -1
var _cast_spell_total := 0
var _cast_basic_total := 0

@onready var _battlefield: BattlefieldPanel = %Battlefield
@onready var _io: BattleIO = %BattleIO
@onready var _terrain_label: Label = %TerrainLabel
@onready var _round_label: Label = %RoundLabel
@onready var _order_label: Label = %OrderBar
@onready var _result: ResultOverlay = %ResultOverlay
@onready var _console: LogConsole = %LogConsole
@onready var _prompt: PanelContainer = %TargetPrompt

func _ready() -> void:
	randomize()
	spells = DemoSpellLibrary.build()
	state = BattleState.new(TestEncounter.enemies(), TerrainSystem.random_terrain())
	_terrain_label.text = "TERRAIN: %s  |  %s" % [
		state.terrain.display_name, state.terrain.description().replace("\n", "  ")]
	_battlefield.setup(state)
	_io.board_view.bind(board, _fragment_at)
	_connect_signals()
	_advance()

func _connect_signals() -> void:
	_io.cast_pressed.connect(_on_cast)
	_io.reset_pressed.connect(_on_reset)
	_io.end_turn_pressed.connect(_on_end_turn)
	_io.spell_zone.card_clicked.connect(_on_card_clicked)
	_io.board_view.cell_clicked.connect(_on_cell_clicked)
	_io.board_view.fragment_dropped.connect(_try_place)
	_io.hand_view.card_selected.connect(_on_card_selected)
	_io.hand_view.card_rotate.connect(_on_card_rotate)
	_io.hand_view.card_drag_started.connect(_on_card_drag_started)
	_battlefield.enemy_clicked.connect(_on_enemy_clicked)
	_battlefield.player_clicked.connect(_on_player_clicked)
	_battlefield.ultimate_pressed.connect(_on_ultimate_pressed)
	_battlefield.spell_dropped_on.connect(_on_spell_dropped)
	_result.restart_pressed.connect(func(): get_tree().reload_current_scene())
	%PromptConfirm.pressed.connect(_on_prompt_confirmed)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _awaiting_enemy >= 0 and event.is_action_pressed("ui_accept"):
		_on_prompt_confirmed()
		return
	if _casting:
		if event.is_action_pressed("ui_cancel"):
			_clear_selection()
		return
	if event.keycode == KEY_R:
		_rotate(selected)
		return
	if event.keycode == DEBUG_GRANT_KEY:
		_debug_grant_spells()

# ---------- round flow ----------
func _advance() -> void:
	while not state.over:
		var round_lines: Array[String] = []
		var actor := TurnOrderSystem.next_actor(state, round_lines)
		_log_lines(round_lines)
		if actor < 0:
			return
		if actor == TurnOrderSystem.PLAYER:
			_start_turn()
			return
		if BattleConfig.CONFIRM_ENEMY_ACTIONS and _enemy_will_cast(actor - 1):
			_awaiting_enemy = actor
			_show_enemy_prompt(actor - 1)
			return
		if not _run_enemy_actor(actor):
			return

func _run_enemy_actor(actor: int) -> bool:        # returns false if the battle ended
	var lines: Array[String] = []
	TurnResolver.run_enemy_action(state, actor - 1, lines)
	_log_lines(lines)
	TurnOrderSystem.finish_action(state, actor)
	var outcome := _outcome()
	if outcome != 0:
		_finish(outcome > 0)
		return false
	_refresh_all()
	return true

func _enemy_will_cast(i: int) -> bool:
	return not state.enemies[i].is_broken() \
		and state.enemies[i].get_status(StatusTypes.Status.FREEZE) <= 0 \
		and EnemyIntentSystem.pick_spell(state.enemy_defs[i], state.turn) != null

func _show_enemy_prompt(i: int) -> void:
	var spell := EnemyIntentSystem.pick_spell(state.enemy_defs[i], state.turn)
	var caster := state.enemies[i]
	var hit := caster if spell.target_kind == SpellDefinition.TargetKind.SELF else state.player
	%PromptTitle.text = "%s casts %s" % [caster.display_name, spell.display_name]
	%PromptTarget.text = "Hits: %s" % hit.display_name
	%PromptHint.text = ""
	%PromptCancel.visible = false
	_prompt.visible = true
	%PromptConfirm.grab_focus()

func _on_prompt_confirmed() -> void:
	if _awaiting_enemy < 0:
		return
	var actor := _awaiting_enemy
	_awaiting_enemy = -1
	_prompt.visible = false
	if _run_enemy_actor(actor):
		_advance()

func _start_turn() -> void:
	state.ultimate_active = false
	state.player.set_damage_output_multiplier(1.0)
	board.advance_special_tiles()
	state.player.advance_stat_tile_turn()
	for enemy in state.enemies:
		enemy.advance_stat_tile_turn()
	state.ensure_valid_target()
	_casting = false
	_selected_spell = null
	_inspect_player = false
	_log_line("round", "--- Your turn (round %d) ---" % state.turn)
	var special_tiles := board.spawn_special_tiles()
	if not special_tiles.is_empty():
		var labels: Array[String] = []
		for tile in special_tiles:
			labels.append(_special_tile_name(tile))
		_log_line("system", "Special tiles appeared: %s." % ", ".join(labels))
	var n := maxi(1, BattleConfig.HAND_SIZE - state.overload_debt)
	if state.overload_debt > 0:
		_log_line("system", "Overload: you draw %d fewer fragment(s) this turn." % state.overload_debt)
	state.overload_debt = 0
	hand = FragmentGenerator.draw(n)
	_snapshot_hand = _copy_hand(hand)
	_snapshot_board = board.snapshot()
	_snapshot_charge_gauge = state.charge_gauge
	_snapshot_ultimate_active = state.ultimate_active
	_snapshot_damage_multiplier = state.player.damage_output_multiplier
	_placed_this_turn = 0
	selected = -1
	_outlined.clear()
	_ghosts.clear()
	_battlefield.set_drop_enabled(false)
	_io.set_phase(BattleIO.Phase.CHANTING)
	_io.set_hint("Chanting: drag a fragment onto the board (or click it, then a cell). R or right-click rotates. Then press CAST.")
	_refresh_all()
	_update_deadlock()

func _finish_turn(lines: Array[String]) -> void:
	TurnResolver.end_turn_effects(state.player, lines)
	_log_lines(lines)
	TurnOrderSystem.finish_action(state, TurnOrderSystem.PLAYER)
	var outcome := _outcome()
	if outcome != 0:
		_finish(outcome > 0)
		return
	queue.clear()
	_outlined.clear()
	_ghosts.clear()
	_casting = false
	_selected_spell = null
	_advance()

func _outcome() -> int:
	if state.player.is_dead():
		return -1
	if state.all_enemies_dead():
		return 1
	return 0

func _finish(won: bool) -> void:
	state.over = true
	_casting = false
	_awaiting_enemy = -1
	_prompt.visible = false
	_battlefield.set_drop_enabled(false)
	_log_line("system", "VICTORY! All enemies are down." if won else "DEFEAT... you ran out of HP.")
	_result.show_result(won,
		"All enemies are down." if won else "You ran out of HP.",
		"Rounds: %d" % state.turn)
	_refresh_all()

# ---------- chanting period: hand and board ----------
func _fragment_at(i: int) -> FragmentData:
	if i < 0 or i >= hand.size():
		return null
	return hand[i]

func _copy_hand(src: Array[FragmentData]) -> Array[FragmentData]:
	var out: Array[FragmentData] = []
	for f in src:
		out.append(f)
	return out

func _on_card_selected(i: int) -> void:
	if _casting:
		return
	selected = -1 if selected == i else i
	_refresh_hand.call_deferred()

func _on_card_drag_started(i: int) -> void:
	selected = i

func _on_card_rotate(i: int) -> void:
	if _casting:
		return
	selected = i
	_rotate(i)

func _rotate(i: int) -> void:
	if i < 0 or i >= hand.size():
		return
	hand[i] = hand[i].rotated_cw()
	_refresh_hand.call_deferred()

func _on_cell_clicked(anchor: Vector2i) -> void:
	if selected < 0:
		_io.set_hint("Select a fragment first.")
		return
	_try_place(selected, anchor)

func _try_place(index: int, anchor: Vector2i) -> void:
	if state.over or _casting or _awaiting_enemy >= 0 or index < 0 or index >= hand.size():
		return
	var frag := hand[index]
	if not board.place(frag, anchor):
		_io.set_hint("Can't place there.")
		return
	hand.remove_at(index)
	selected = -1
	_placed_this_turn += frag.cells.size()
	_outlined.clear()
	_ghosts.clear()
	_io.set_hint("Placed %d tiles." % frag.cells.size())
	_resolve_matches()
	_refresh_hand.call_deferred()

func _resolve_matches() -> void:
	var match_index := 0
	while true:
		var hit := SpellMatcher.find_first_match(board, spells)
		if hit.is_empty():
			break
		var color := Color.from_hsv(float(match_index % 12) / 12.0, 0.8, 1.0)
		var hit_cells: Array = hit["cells"]
		var hit_elems: Array = hit["elements"]
		var hit_special_tiles: Array = hit["special_tiles"]
		for i in hit_cells.size():
			var cell: Vector2i = hit_cells[i]
			_outlined[cell] = color
			_ghosts[cell] = hit_elems[i]
		board.clear_cells(hit_cells)
		var elems: Array[int] = []
		for e in hit_elems:
			elems.append(e)
		var spell: SpellDefinition = hit["spell"]
		queue.append(QueuedSpell.new(spell, elems, hit_special_tiles))
		_apply_on_queue_effects(spell)
		_io.set_hint("Matched: %s" % spell.display_name)
		_log_line("player", "Formed %s." % spell.display_name)
		match_index += 1
	_refresh_board()
	_refresh_spells()
	_update_deadlock()

func _apply_on_queue_effects(spell: SpellDefinition) -> void:
	for fx in spell.effects:
		if fx.kind == SpellEffect.Kind.OVERLOAD:
			for i in fx.amount:
				hand.append(FragmentGenerator.random_fragment())
			state.overload_debt += fx.amount2
			_log_line("system", "Overload! Drew %d extra fragment(s); next turn -%d." % [
				fx.amount, fx.amount2])

func _update_deadlock() -> void:
	var stuck := not state.over and not _casting and _placed_this_turn == 0 \
			and queue.is_empty() and DeadlockDetector.is_deadlocked(board, hand)
	if stuck:
		_io.set_hint("DEADLOCK: no fragment fits the board. (The Backlash / Fizzle overlay is not built yet.)")
		_log_line("system", "Deadlock! No fragment fits the board.")

func _on_reset() -> void:
	if state.over:
		get_tree().reload_current_scene()
		return
	if _casting or _awaiting_enemy >= 0:
		return
	board.restore(_snapshot_board)
	queue.clear()
	_outlined.clear()
	_ghosts.clear()
	hand = _copy_hand(_snapshot_hand)
	selected = -1
	_placed_this_turn = 0
	state.overload_debt = 0
	state.charge_gauge = _snapshot_charge_gauge
	state.ultimate_active = _snapshot_ultimate_active
	state.player.set_damage_output_multiplier(_snapshot_damage_multiplier)
	state.player.clear_stat_tiles()
	for enemy in state.enemies:
		enemy.clear_stat_tiles()
	_io.set_hint("Turn reset.")
	_refresh_all()
	_update_deadlock()

func _debug_grant_spells() -> void:
	if _casting or state.over:
		return
	for d in spells:
		queue.append(QueuedSpell.new(d, [], []))
	_log_line("system", "DEBUG: granted one copy of every spell.")
	_refresh_all()

# ---------- casting period ----------
func _on_cast() -> void:                    # one-way: no way back to chanting this turn
	if state.over or _casting or _awaiting_enemy >= 0:
		return
	_cast_spell_total = 0
	_cast_basic_total = 0
	_casting = true
	selected = -1
	_selected_spell = null
	_inspect_player = false
	_io.set_phase(BattleIO.Phase.CASTING)
	_battlefield.set_drop_enabled(true)
	_io.set_hint("Casting: click a target, click a card, click it again (or double-click). Esc deselects.")
	_log_line("system", "Casting begins: %d spell(s) built, %d tile(s) on the board." % [
		queue.size(), board.filled_count()])
	_refresh_all()

func _on_card_clicked(definition: SpellDefinition, is_double: bool) -> void:
	if not _casting or state.over:
		return
	if is_double or _selected_spell == definition:        # second click or double-click = cast
		var is_self := definition.target_kind == SpellDefinition.TargetKind.SELF
		state.ensure_valid_target()
		_on_spell_dropped(-1 if is_self else state.target_index, definition)
		_clear_selection()
	else:
		_selected_spell = definition
		_io.spell_zone.set_selected(definition)
		_refresh_detail()

func _clear_selection() -> void:
	_selected_spell = null
	_io.spell_zone.set_selected(null)
	_refresh_detail()

# target_index: enemy slot, or -1 for the player (self-target spells)
func _on_spell_dropped(target_index: int, definition: SpellDefinition) -> void:
	if not _casting or state.over:
		return
	var idx := -1
	for i in queue.size():
		if queue[i].definition == definition:
			idx = i
			break
	if idx < 0:
		return
	var is_self := definition.target_kind == SpellDefinition.TargetKind.SELF
	if is_self != (target_index < 0):
		_io.set_hint("Drop this spell on %s." % ("yourself" if is_self else "an enemy"))
		return
	if target_index >= 0:
		if state.enemies[target_index].is_dead():
			return
		state.target_index = target_index
	var q: QueuedSpell = queue.pop_at(idx)
	var lines: Array[String] = []
	_cast_spell_total += SpellResolver.resolve_spell(q, state, lines)
	_add_charge(_charge_for_spell(q), lines)
	_log_lines(lines)
	var hit: CombatantState = state.player if is_self else state.enemies[target_index]
	_log_line("system", "   -> %s now at HP %d/%d" % [hit.display_name, hit.hp, hit.max_hp])
	TurnOrderSystem.refresh(state)
	_refresh_all()
	if state.all_enemies_dead():
		_end_casting()

func _on_end_turn() -> void:               # basic attack on the remembered target
	if not _casting or state.over:
		return
	if board.filled_count() > 0:
		state.ensure_valid_target()
		var lines: Array[String] = []
		_cast_basic_total += SpellResolver.resolve_basic_attack(board.filled_count(), state, lines)
		_add_charge(BattleConfig.CHARGE_BASIC_ATTACK, lines)
		_log_lines(lines)
	_end_casting()

func _end_casting() -> void:
	_casting = false
	_battlefield.set_drop_enabled(false)
	var lines: Array[String] = []
	lines.append("Turn total: spells %d + tiles %d = %d" % [
		_cast_spell_total, _cast_basic_total, _cast_spell_total + _cast_basic_total])
	_finish_turn(lines)

func _on_enemy_clicked(i: int) -> void:
	if state.over or i < 0 or i >= state.enemies.size() or state.enemies[i].is_dead():
		return
	state.target_index = i
	_inspect_player = false
	_refresh_all()

func _on_player_clicked() -> void:
	if _casting:
		_inspect_player = true
		_refresh_detail()

func _on_ultimate_pressed() -> void:
	if state.over or _casting or _awaiting_enemy >= 0 or state.charge_gauge < 100.0:
		return
	var spent: float = state.charge_gauge
	var ratio: float = (spent - 100.0) / 50.0
	var multiplier: float = lerpf(BattleConfig.ULTIMATE_MIN_MULTIPLIER,
		BattleConfig.ULTIMATE_MAX_MULTIPLIER, clampf(ratio, 0.0, 1.0))
	state.charge_gauge = 0.0
	state.ultimate_active = true
	state.player.set_damage_output_multiplier(multiplier)
	_log_line("player", "Ultimate activated: %.2fx damage this turn." % multiplier)
	_refresh_all()

func _add_charge(amount: float, _lines: Array[String]) -> void:
	if state.ultimate_active:
		return
	state.charge_gauge = minf(BattleConfig.CHARGE_GAUGE_MAX, state.charge_gauge + amount)

func _charge_for_spell(q: QueuedSpell) -> float:
	var cell_count: int = q.definition.pattern.cells.size()
	var charge: float = BattleConfig.CHARGE_LEVEL_1
	if cell_count >= 8:
		charge = BattleConfig.CHARGE_LEVEL_3
	elif cell_count >= 5:
		charge = BattleConfig.CHARGE_LEVEL_2
	charge += q.special_tiles.size() * BattleConfig.CHARGE_SPECIAL_TILE
	return charge

# ---------- refresh ----------
func _refresh_all() -> void:
	_battlefield.refresh(state)
	_round_label.text = "Round %d" % state.turn
	_order_label.text = _order_text()
	_refresh_board()
	_refresh_hand()
	_refresh_spells()
	_io.set_cast_enabled(not state.over and not _casting and _awaiting_enemy < 0)
	_refresh_detail()

func _refresh_board() -> void:
	_io.board_view.outlined = _outlined
	_io.board_view.ghosts = _ghosts
	_io.board_view.refresh()

func _refresh_hand() -> void:
	_io.hand_view.show_hand(hand, selected)

func _order_text() -> String:
	var parts: Array[String] = []
	for e in TurnOrderSystem.summary(state):
		var s := "%s (%.1f)" % [e["name"], e["speed"]]
		if e["state"] == "now":
			s = "[" + s + "]"
		elif e["state"] == "done":
			s = "(" + s + ")"
		parts.append(s)
	return "Turn order: " + " > ".join(parts)

func _refresh_spells() -> void:
	var mode := SpellZone.Mode.CASTING if _casting else SpellZone.Mode.CHANTING
	var entries: Array[Dictionary] = []
	for d in spells:
		var n := 0
		var first: QueuedSpell = null
		for q in queue:
			if q.definition == d:
				n += 1
				if first == null:
					first = q
		var projected := -1
		if first != null:                    # projected damage versus the remembered target
			var p := SpellResolver.preview([first] as Array[QueuedSpell], 0, state)
			var dmg: Array = p["spell_damages"]
			projected = int(dmg[0]) if not dmg.is_empty() else 0
		entries.append({"definition": d, "count": n, "projected": projected})
	_io.spell_zone.show_spells(entries, mode)
	_io.spell_zone.set_selected(_selected_spell)

func _first_queued(d: SpellDefinition) -> QueuedSpell:
	for q in queue:
		if q.definition == d:
			return q
	return null

func _refresh_detail() -> void:
	if not _casting or state.enemies.is_empty():
		return
	state.ensure_valid_target()
	var d := _selected_spell
	var self_spell := d != null and d.target_kind == SpellDefinition.TargetKind.SELF
	var on_player := _inspect_player or self_spell
	var idx := state.target_index
	var sim := state.duplicate_state()
	sim.target_index = idx
	var subject: CombatantState = state.player if on_player else state.enemies[idx]
	var data := {"role": "YOU" if on_player else "TARGET"}
	if not on_player:
		var intent := EnemyIntentSystem.get_intent(state.enemy_defs[idx], state.turn)
		data["intent"] = str(intent["name"])
		if board.filled_count() > 0:
			data["basic_tiles"] = board.filled_count()
			data["basic_info"] = DamageCalculator.explain_basic_attack(
				board.filled_count(), sim.player, sim.enemies[idx], sim.terrain)
	if d != null:
		data["spell_name"] = d.display_name
		var fx: Array[String] = []
		for e in d.effects:
			fx.append(e.describe())
		data["spell_effects"] = ", ".join(fx)
		var q := _first_queued(d)
		if q != null and d.base_damage > 0 and not on_player:
			var target := sim.enemies[idx]
			SpellResolver.apply_special_tiles(q.special_tiles, sim.player, target, [])
			data["spell_info"] = DamageCalculator.explain_spell(d.base_damage, sim.player, target,
				d.primary_element(), d.other_multiplier, sim.terrain)
	_io.target_detail.show_data(subject, data)

# ---------- log ----------
func _log_line(kind: String, text: String) -> void:
	if kind == "round":
		_console.add_entry(kind, text)
	else:
		_console.add_entry(kind, "[R%d] %s" % [state.turn, text])

func _log_lines(lines: Array) -> void:
	for l in lines:
		_log_line(_classify(str(l)), str(l))

func _classify(line: String) -> String:
	if line.begins_with("===") or line.begins_with("---"):
		return "round"
	if "Shield Break" in line or "SHATTER" in line:
		return "weak"
	if line.begins_with(state.player.display_name):
		return "player"
	for e in state.enemies:
		if line.begins_with(e.display_name):
			return "enemy"
	return "system"

# ---------- helpers ----------
func _stat_name(stat: int) -> String:
	return ["ATK", "DEF", "SPD"][stat]

func _special_tile_name(tile: int) -> String:
	if CastingBoardModel.is_heal(tile):
		return "Heal"
	var prefix: String = "Buff" if CastingBoardModel.is_buff(tile) else "Debuff"
	return "%s %s" % [prefix, _stat_name(CastingBoardModel.special_stat(tile))]
