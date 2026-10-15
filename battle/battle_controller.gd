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

var _battlefield: BattlefieldView
var _info: Label
var _board_view: CastingBoardView
var _hand_view: FragmentZone
var _debug: DebugPanel
var _turn_bar: TurnIndicator
var _queue_view: SpellQueueView
var _log: BattleLogView

func _ready() -> void:
	randomize()
	spells = DemoSpellLibrary.build()
	state = BattleState.new(TestEncounter.enemies())
	_build_layout()
	_board_view.bind(board, _fragment_at)
	_battlefield.setup(state)
	_connect_signals()
	_start_turn()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_R:
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

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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

	_board_view = CastingBoardView.new()
	_board_view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	play_row.add_child(_board_view)

	_debug = DebugPanel.new()
	left.add_child(_debug)
	
	_info = Label.new()

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(400, 0)
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(right_scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	right_scroll.add_child(right)

	_turn_bar = TurnIndicator.new()
	right.add_child(_turn_bar)
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

# ---------- turn flow ----------
func _start_turn() -> void:
	TurnSystem.start_player_turn(state)
	state.ensure_valid_target()
	_log.add_line("--- Turn %d ---" % state.turn)
	var n := maxi(1, BattleConfig.HAND_SIZE - state.overload_debt)
	if state.overload_debt > 0:
		_log.add_line("Overload: you draw %d fewer fragment(s) this turn." % state.overload_debt)
	state.overload_debt = 0
	hand = FragmentGenerator.draw(n)
	_snapshot_hand = _copy_hand(hand)
	selected = -1
	_info.text = "Drag a fragment onto the board (or click it, then click a cell). R or right-click = rotate."
	_refresh_all()

func _on_cast() -> void:
	if state.over:
		return
	var lines: Array[String] = []
	var tiles := board.filled_count()
	var spell_total := SpellResolver.resolve_queue(queue, state, lines)
	var basic_total := SpellResolver.resolve_basic_attack(tiles, state, lines)
	lines.append("Turn total: spells %d + tiles %d = %d" % [
		spell_total, basic_total, spell_total + basic_total])
	TurnSystem.end_turn_effects(state.player, lines)
	var outcome := _outcome()
	if outcome == 0:
		TurnSystem.run_enemies_turn(state, lines)
		outcome = _outcome()
	if outcome != 0:
		_finish(outcome > 0, lines)
		return
	_log.add_lines(lines)
	board.reset()
	queue.clear()
	_outlined.clear()
	_ghosts.clear()
	_start_turn()

func _outcome() -> int:
	if state.player.is_dead():
		return -1
	if state.all_enemies_dead():
		return 1
	return 0

func _finish(won: bool, lines: Array[String]) -> void:
	state.over = true
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
	board.reset()
	queue.clear()
	_outlined.clear()
	_ghosts.clear()
	hand = _copy_hand(_snapshot_hand)
	selected = -1
	state.overload_debt = 0
	_info.text = "Turn reset."
	_refresh_all()

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
	if state.over or index < 0 or index >= hand.size():
		return
	var frag := hand[index]
	if not board.place(frag, anchor):
		_info.text = "Can't place there."
		return
	hand.remove_at(index)
	selected = -1
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
	if from_i < 0 or from_i >= queue.size() or to_i < 0 or to_i >= queue.size():
		return
	var q: QueuedSpell = queue.pop_at(from_i)
	queue.insert(to_i, q)
	_refresh_queue()

func _on_enemy_clicked(i: int) -> void:
	if state.over or i < 0 or i >= state.enemies.size() or state.enemies[i].is_dead():
		return
	state.target_index = i
	_battlefield.refresh(state)
	_refresh_queue()

# ---------- debug ----------
func _on_debug_give(element: int) -> void:
	var f := FragmentGenerator.single_element(element)
	hand.append(f)
	_snapshot_hand.append(f)
	_refresh_hand.call_deferred()

func _on_reroll() -> void:
	hand = FragmentGenerator.draw(BattleConfig.HAND_SIZE)
	_snapshot_hand = _copy_hand(hand)
	selected = -1
	_refresh_hand.call_deferred()

# ---------- refresh ----------
func _refresh_all() -> void:
	_battlefield.refresh(state)
	_refresh_board()
	_refresh_hand()
	_refresh_queue()
	_turn_bar.set_turn(state.turn)

func _refresh_board() -> void:
	_board_view.outlined = _outlined
	_board_view.ghosts = _ghosts
	_board_view.refresh()

func _refresh_hand() -> void:
	_hand_view.show_hand(hand, selected)

func _refresh_queue() -> void:
	_queue_view.show_queue(queue)
	_queue_view.show_preview(SpellResolver.preview(queue, board.filled_count(), state))
	var has_work := not queue.is_empty() or board.filled_count() > 0
	_turn_bar.set_cast_label("CAST" if has_work else "End Turn")
	_turn_bar.set_cast_enabled(not state.over)
