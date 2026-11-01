extends Control
const HAND_COLUMN_WIDTH := 118*3   # 2 cards per row; use 118 for a single column

var state: BattleState
var board := CastingBoardModel.new()
var spells: Array[SpellDefinition] = []
var hand: Array[FragmentData] = []
var queue: Array[QueuedSpell] = []
var selected := -1

var _outlined: Dictionary = {}
var _ghosts: Dictionary = {}
var _snapshot_hand: Array[FragmentData] = []
var _snapshot_board := PackedInt32Array()
var _placed_this_turn := 0   # only used to detect deadlock (nothing placed yet this turn)

# targeted casting (player's turn)
var _casting := false
var _cast_steps: Array[Dictionary] = []   # {"kind": "spell" | "basic", "spell": QueuedSpell}
var _cast_index := 0
var _cast_spell_total := 0
var _cast_basic_total := 0

# optional "Continue" prompt before each enemy spell
var _awaiting_enemy := -1   # enemy actor id waiting for the player's Continue

var _battlefield: BattlefieldView
var _order_bar: TurnOrderBar
var _info: Label
var _board_view: CastingBoardView
var _deadlock_overlay: DeadlockOverlay
var _hand_view: FragmentZone
var _debug: DebugPanel
var _turn_bar: TurnIndicator
var _target_prompt: TargetPrompt
var _queue_view: SpellQueueView
var _log: BattleLogView

func _ready() -> void:
	randomize()
	DisplayServer.window_set_min_size(Vector2i(1300, 720))
	spells = DemoSpellLibrary.build()
	state = BattleState.new(TestEncounter.enemies())
	_build_layout()
	_board_view.bind(board, _fragment_at)
	_battlefield.setup(state)
	_connect_signals()
	_advance()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _casting or _awaiting_enemy >= 0:
		if event.is_action_pressed("ui_accept"):
			_on_target_confirmed()
		elif event.is_action_pressed("ui_cancel"):
			_on_target_cancelled()
		return
	if event.keycode == KEY_R:
		_rotate(selected)

# ---------- layout ----------
func _build_layout() -> void:
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	_battlefield = BattlefieldView.new()
	root.add_child(_battlefield)

	_order_bar = TurnOrderBar.new()
	root.add_child(_order_bar)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(864, 0)
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(left_scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	left_scroll.add_child(left)

	var play_row := HBoxContainer.new()
	play_row.add_theme_constant_override("separation", 12)
	left.add_child(play_row)

	_hand_view = FragmentZone.new()
	_hand_view.custom_minimum_size = Vector2(HAND_COLUMN_WIDTH, 110)
	_hand_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	play_row.add_child(_hand_view)

	var board_frame := MarginContainer.new()
	board_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	play_row.add_child(board_frame)
	_board_view = CastingBoardView.new()
	board_frame.add_child(_board_view)
	_deadlock_overlay = DeadlockOverlay.new()
	board_frame.add_child(_deadlock_overlay)

	_debug = DebugPanel.new()
	left.add_child(_debug)

	_info = Label.new()

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(380, 0)
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(right_scroll)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(0, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	right_scroll.add_child(right)

	_turn_bar = TurnIndicator.new()
	right.add_child(_turn_bar)
	_target_prompt = TargetPrompt.new()
	right.add_child(_target_prompt)
	_queue_view = SpellQueueView.new()
	right.add_child(_queue_view)
	_log = BattleLogView.new()
	right.add_child(_log)

func _connect_signals() -> void:
	_board_view.cell_clicked.connect(_on_cell_clicked)
	_board_view.fragment_dropped.connect(_try_place)
	_hand_view.card_selected.connect(_on_card_selected)
	_hand_view.card_rotate.connect(_on_card_rotate)
	_hand_view.card_drag_started.connect(_on_card_drag_started)
	_debug.give_element.connect(_on_debug_give)
	_debug.reroll_pressed.connect(_on_reroll)
	_battlefield.enemy_clicked.connect(_on_enemy_clicked)
	_queue_view.reorder.connect(_on_reorder)
	_turn_bar.cast_pressed.connect(_on_cast)
	_turn_bar.reset_pressed.connect(_on_reset)
	_deadlock_overlay.backlash_pressed.connect(_on_backlash)
	_deadlock_overlay.fizzle_pressed.connect(_on_fizzle)
	_target_prompt.confirmed.connect(_on_target_confirmed)
	_target_prompt.cancelled.connect(_on_target_cancelled)

# ---------- round flow ----------
# Runs enemy actions in speed order until it is the player's turn (or the battle ends).
func _advance() -> void:
	while not state.over:
		var round_lines: Array[String] = []
		var actor := TurnOrderSystem.next_actor(state, round_lines)
		_log.add_lines(round_lines)
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

# Returns false if the battle ended.
func _run_enemy_actor(actor: int) -> bool:
	var lines: Array[String] = []
	TurnResolver.run_enemy_action(state, actor - 1, lines)
	_log.add_lines(lines)
	TurnOrderSystem.finish_action(state, actor)
	var outcome := _outcome()
	if outcome != 0:
		_finish(outcome > 0, [])
		return false
	_refresh_status_ui()
	return true

func _enemy_will_cast(i: int) -> bool:
	return state.enemies[i].get_status(StatusTypes.Status.FREEZE) <= 0 \
			and EnemyIntentSystem.pick_spell(state.enemy_defs[i], state.turn) != null

func _show_enemy_prompt(i: int) -> void:
	var spell := EnemyIntentSystem.pick_spell(state.enemy_defs[i], state.turn)
	var caster := state.enemies[i]
	var hit := caster if spell.target_kind == SpellDefinition.TargetKind.SELF else state.player
	_target_prompt.show_step({
		"title": "%s casts %s" % [caster.display_name, spell.display_name],
		"target_label": "Hits",
		"target_name": hit.display_name,
		"confirm_text": "Continue",
	})

# The player's turn begins (planning phase).
func _start_turn() -> void:
	state.ensure_valid_target()
	_log.add_line("--- Your turn (round %d) ---" % state.turn)
	var n := maxi(1, BattleConfig.HAND_SIZE - state.overload_debt)
	if state.overload_debt > 0:
		_log.add_line("Overload: you draw %d fewer fragment(s) this turn." % state.overload_debt)
	state.overload_debt = 0
	hand = FragmentGenerator.draw(n)
	_snapshot_hand = _copy_hand(hand)
	_snapshot_board = board.snapshot()
	_placed_this_turn = 0
	selected = -1
	_info.text = "Drag a fragment onto the board (or click it, then click a cell). R or right-click = rotate."
	_refresh_all()
	_update_deadlock()

func _finish_turn(lines: Array[String]) -> void:
	TurnResolver.end_turn_effects(state.player, lines)
	_log.add_lines(lines)
	TurnOrderSystem.finish_action(state, TurnOrderSystem.PLAYER)
	var outcome := _outcome()
	if outcome != 0:
		_finish(outcome > 0, [])
		return
	queue.clear()
	_outlined.clear()
	_ghosts.clear()
	_advance()

func _outcome() -> int:
	if state.player.is_dead():
		return -1
	if state.all_enemies_dead():
		return 1
	return 0

func _finish(won: bool, lines: Array[String]) -> void:
	state.over = true
	_casting = false
	_awaiting_enemy = -1
	_target_prompt.hide_prompt()
	if won:
		lines.append("VICTORY! All enemies are down.")
		_info.text = "Victory! Press Reset to restart."
	else:
		lines.append("DEFEAT... you ran out of HP.")
		_info.text = "Defeat. Press Reset to restart."
	_log.add_lines(lines)
	_refresh_all()

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
	_info.text = "Turn reset."
	_refresh_all()
	_update_deadlock()

# ---------- targeted casting ----------
func _on_cast() -> void:
	if state.over or _casting or _awaiting_enemy >= 0 or _deadlock_overlay.visible:
		return
	_cast_steps.clear()
	for q in queue:
		_cast_steps.append({"kind": "spell", "spell": q})
	if board.filled_count() > 0:
		_cast_steps.append({"kind": "basic"})
	_cast_index = 0
	_cast_spell_total = 0
	_cast_basic_total = 0
	_casting = true
	_refresh_queue()
	if _cast_steps.is_empty():
		_end_casting()
	else:
		_next_cast_step()

func _next_cast_step() -> void:
	state.ensure_valid_target()
	if _living_enemy_count() <= 1:
		_run_cast_step()   # only one possible target: no need to ask
	else:
		_show_prompt()

func _show_prompt() -> void:
	var step: Dictionary = _cast_steps[_cast_index]
	var title := ""
	if step["kind"] == "spell":
		var q: QueuedSpell = step["spell"]
		title = "Cast %d/%d: %s" % [_cast_index + 1, _cast_steps.size(), q.definition.display_name]
	else:
		title = "Cast %d/%d: Basic attack (%d tiles)" % [
			_cast_index + 1, _cast_steps.size(), board.filled_count()]
	_target_prompt.show_step({
		"title": title,
		"target_name": state.enemies[state.target_index].display_name,
		"hint": "Click an enemy to change the target. Your last choice is remembered (Enter = confirm).",
		"can_cancel": _cast_index == 0,
	})

func _on_target_confirmed() -> void:
	if _awaiting_enemy >= 0:
		var actor := _awaiting_enemy
		_awaiting_enemy = -1
		_target_prompt.hide_prompt()
		if _run_enemy_actor(actor):
			_advance()
		return
	if _casting and _cast_index < _cast_steps.size():
		_run_cast_step()

func _run_cast_step() -> void:
	var step: Dictionary = _cast_steps[_cast_index]
	state.ensure_valid_target()
	var lines: Array[String] = []
	if step["kind"] == "spell":
		_cast_spell_total += SpellResolver.resolve_spell(step["spell"], state, lines)
	else:
		_cast_basic_total += SpellResolver.resolve_basic_attack(board.filled_count(), state, lines)
	_log.add_lines(lines)
	TurnOrderSystem.refresh(state)   # statuses changed: update the order now
	_cast_index += 1
	_refresh_status_ui()
	if state.all_enemies_dead() or _cast_index >= _cast_steps.size():
		_end_casting()
	else:
		_next_cast_step()

func _end_casting() -> void:
	_casting = false
	_target_prompt.hide_prompt()
	var lines: Array[String] = []
	lines.append("Turn total: spells %d + tiles %d = %d" % [
		_cast_spell_total, _cast_basic_total, _cast_spell_total + _cast_basic_total])
	_finish_turn(lines)

func _on_target_cancelled() -> void:
	if not _casting or _cast_index > 0:
		return
	_casting = false
	_target_prompt.hide_prompt()
	_info.text = "Cast cancelled."
	_refresh_queue()

func _living_enemy_count() -> int:
	var n := 0
	for e in state.enemies:
		if not e.is_dead():
			n += 1
	return n

# ---------- deadlock ----------
func _update_deadlock() -> void:
	var stuck := not state.over and not _casting and _placed_this_turn == 0 \
			and queue.is_empty() and DeadlockDetector.is_deadlocked(board, hand)
	if not stuck:
		_deadlock_overlay.hide_overlay()
		return
	var tiles := board.filled_count()
	var check := DeadlockResolver.check_backlash(state)
	if not _deadlock_overlay.visible:
		_log.add_line("Deadlock! No fragment fits the board.")
	_deadlock_overlay.show_choice({
		"tiles": tiles,
		"cost": check["cost"],
		"damage": DamageCalculator.basic_attack(tiles, state.player),
		"can_backlash": check["ok"],
		"reason": check["reason"],
	})

func _on_backlash() -> void:
	var lines: Array[String] = []
	if not DeadlockResolver.backlash(state, board, lines):
		_log.add_lines(lines)
		return
	_deadlock_overlay.hide_overlay()
	_outlined.clear()
	_ghosts.clear()
	lines.append("Backlash ends your turn.")
	_finish_turn(lines)

func _on_fizzle() -> void:
	var lines: Array[String] = []
	DeadlockResolver.fizzle(board, lines)
	_deadlock_overlay.hide_overlay()
	_outlined.clear()
	_ghosts.clear()
	lines.append("Fizzle ends your turn.")
	_finish_turn(lines)

# ---------- hand and placement ----------
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
	selected = -1 if selected == i else i
	_refresh_hand.call_deferred()

func _on_card_drag_started(i: int) -> void:
	selected = i

func _on_card_rotate(i: int) -> void:
	selected = i
	_rotate(i)

func _rotate(i: int) -> void:
	if i < 0 or i >= hand.size():
		return
	hand[i] = hand[i].rotated_cw()
	_refresh_hand.call_deferred()

func _on_cell_clicked(anchor: Vector2i) -> void:
	if selected < 0:
		_info.text = "Select a fragment first."
		return
	_try_place(selected, anchor)

func _try_place(index: int, anchor: Vector2i) -> void:
	if state.over or _casting or _awaiting_enemy >= 0 or _deadlock_overlay.visible \
			or index < 0 or index >= hand.size():
		return
	var frag := hand[index]
	if not board.place(frag, anchor):
		_info.text = "Can't place there."
		return
	hand.remove_at(index)
	selected = -1
	_placed_this_turn += frag.cells.size()
	_outlined.clear()
	_ghosts.clear()
	_info.text = "Placed %d tiles." % frag.cells.size()
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
		for i in hit_cells.size():
			var cell: Vector2i = hit_cells[i]
			_outlined[cell] = color
			_ghosts[cell] = hit_elems[i]
		board.clear_cells(hit_cells)
		var elems: Array[int] = []
		for e in hit_elems:
			elems.append(e)
		var spell: SpellDefinition = hit["spell"]
		queue.append(QueuedSpell.new(spell, elems))
		_apply_on_queue_effects(spell)
		_info.text = "Matched: %s" % spell.display_name
		match_index += 1
	_refresh_board()
	_refresh_queue()

func _apply_on_queue_effects(spell: SpellDefinition) -> void:
	for fx in spell.effects:
		if fx.kind == SpellEffect.Kind.OVERLOAD:
			for i in fx.amount:
				hand.append(FragmentGenerator.random_fragment())
			state.overload_debt += fx.amount2
			_log.add_line("Overload! Drew %d extra fragment(s); next turn -%d." % [
				fx.amount, fx.amount2])

# ---------- queue and targeting ----------
func _on_reorder(from_i: int, to_i: int) -> void:
	if _casting or _awaiting_enemy >= 0:
		return
	if from_i < 0 or from_i >= queue.size() or to_i < 0 or to_i >= queue.size():
		return
	var q: QueuedSpell = queue.pop_at(from_i)
	queue.insert(to_i, q)
	_refresh_queue()

func _on_enemy_clicked(i: int) -> void:
	if state.over or i < 0 or i >= state.enemies.size() or state.enemies[i].is_dead():
		return
	state.target_index = i
	_refresh_status_ui()
	_refresh_queue()
	if _casting and _cast_index < _cast_steps.size():
		_show_prompt()

# ---------- debug ----------
func _on_debug_give(element: int) -> void:
	if _casting or _awaiting_enemy >= 0:
		return
	var f := FragmentGenerator.single_element(element)
	hand.append(f)
	_snapshot_hand.append(f)
	_refresh_hand.call_deferred()
	_update_deadlock()

func _on_reroll() -> void:
	if _casting or _awaiting_enemy >= 0:
		return
	hand = FragmentGenerator.draw(BattleConfig.HAND_SIZE)
	_snapshot_hand = _copy_hand(hand)
	selected = -1
	_refresh_hand.call_deferred()
	_update_deadlock()

# ---------- refresh ----------
func _refresh_all() -> void:
	_refresh_status_ui()
	_refresh_board()
	_refresh_hand()
	_refresh_queue()
	_turn_bar.set_turn(state.turn)

func _refresh_status_ui() -> void:
	_battlefield.refresh(state)
	_order_bar.show_order(TurnOrderSystem.summary(state))

func _refresh_board() -> void:
	_board_view.outlined = _outlined
	_board_view.ghosts = _ghosts
	_board_view.refresh()

func _refresh_hand() -> void:
	_hand_view.show_hand(hand, selected)

func _refresh_queue() -> void:
	_queue_view.show_queue(queue)
	# The preview assumes every spell hits the remembered target.
	_queue_view.show_preview(SpellResolver.preview(queue, board.filled_count(), state))
	var has_work := not queue.is_empty() or board.filled_count() > 0
	_turn_bar.set_cast_label("CAST" if has_work else "End Turn")
	_turn_bar.set_cast_enabled(not state.over and not _casting and _awaiting_enemy < 0)