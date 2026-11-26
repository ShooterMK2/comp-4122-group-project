class_name BattleController
extends Control
# Wires the battle scene to a BattleSession. Rules live in BattleSession; "what is allowed
# right now" lives in BattleFlow; this node only translates UI input and redraws.
# Launch: instance the scene, set `encounter` (or call start(encounter) after add_child),
# and connect battle_finished. With no listener, the scene reloads when the result is confirmed.

signal battle_finished(result: BattleResult)
signal enemy_acted(enemy_index: int, text: String)     # for a future floating-text label

@export var encounter: EncounterDefinition
@export var enemy_action_delay := 0.6    # TUNABLE: seconds before each enemy acts; 0 = instant

@onready var _battlefield: Battlefield = %Battlefield
@onready var _top_panel: TopPanel = %TopPanel
@onready var _io: BattleIO = %BattleIO
@onready var _result: ResultOverlay = %ResultOverlay
@onready var _console: LogConsole = %LogConsole
@onready var _deadlock: _DeadlockOverlay = %DeadlockOverlay

var _session: BattleSession
var _flow := BattleFlow.new()
var _selected_fragment := -1
var _selected_spell: SpellDefinition
var _inspect_player := false
var _result_data: BattleResult
var _started := false


func _ready() -> void:
	_deadlock.hide()
	if encounter != null:
		start(encounter)


func start(p_encounter: EncounterDefinition) -> void:
	if _started:
		return
	_session = BattleSetup.create(p_encounter)
	if _session == null:
		push_error("BattleController: the battle could not be built.")
		return
	_started = true
	encounter = p_encounter
	_session.log_line.connect(_on_log_line)
	_battlefield.setup(_session.state)
	_io.board_view.bind(_session.board, _session.deck.fragment_at)
	_connect_signals()
	_refresh_all()
	_advance()


func _connect_signals() -> void:
	_io.cast_pressed.connect(_on_cast_pressed)
	_io.end_turn_pressed.connect(_on_end_turn_pressed)
	_io.spell_zone.card_clicked.connect(_on_card_clicked)
	_io.board_view.cell_clicked.connect(_on_cell_clicked)
	_io.board_view.fragment_dropped.connect(_place)
	_io.hand_view.card_selected.connect(_on_hand_selected)
	_io.hand_view.card_rotate.connect(_on_hand_rotate)
	_io.hand_view.card_drag_started.connect(_on_hand_drag_started)
	_battlefield.enemy_clicked.connect(_on_enemy_clicked)
	_battlefield.player_clicked.connect(_on_player_clicked)
	_battlefield.ultimate_pressed.connect(_on_ultimate_pressed)
	_battlefield.spell_dropped_on.connect(_on_spell_dropped)
	_deadlock.backlash_pressed.connect(_on_backlash)
	_deadlock.fizzle_pressed.connect(_on_fizzle)
	_result.restart_pressed.connect(_on_result_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if not _started or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if _flow.can_cast_spell() and event.is_action_pressed("ui_cancel"):
		_clear_spell_selection()
	elif _flow.can_place() and event.keycode == KEY_R:
		_rotate(_selected_fragment)


# ---------- turn flow ----------

func _advance() -> void:
	while not _session.state.over:
		var actor := _session.next_actor()
		if actor < 0:
			_check_outcome()
			return
		if actor == TurnOrderSystem.PLAYER:
			_begin_player_turn()
			return
		_flow.enter(BattleFlow.Phase.ENEMY_TURN)
		_io.set_hint("Enemy turn...")
		_refresh_all()
		if enemy_action_delay > 0.0:
			await get_tree().create_timer(enemy_action_delay).timeout
			if not is_inside_tree() or _flow.is_ended():
				return
		var text := _session.run_enemy_turn(actor)
		enemy_acted.emit(actor - 1, text)
		if _check_outcome():
			return
		_refresh_all()


func _begin_player_turn() -> void:
	_session.begin_player_turn()
	_selected_fragment = -1
	_selected_spell = null
	_inspect_player = false
	_flow.enter(BattleFlow.Phase.CHANTING)
	_battlefield.set_drop_enabled(false)
	_io.set_phase(BattleIO.Phase.CHANTING)
	_io.set_hint("Chanting: drag a fragment onto the board, or click it, then a cell. R or right-click rotates. Then press CAST.")
	if _session.is_deadlocked():
		_open_deadlock()
	_refresh_all()


func _finish_player_turn(extra: Array[String] = []) -> void:
	_session.finish_player_turn(extra)
	_selected_fragment = -1
	_selected_spell = null
	_flow.enter(BattleFlow.Phase.ENEMY_TURN)
	if _check_outcome():
		return
	_advance()


func _check_outcome() -> bool:
	var result := _session.outcome()
	if result == 0:
		return false
	_conclude(result > 0)
	return true


func _conclude(won: bool) -> void:
	if _flow.is_ended():
		return
	_flow.enter(BattleFlow.Phase.ENDED)
	_session.state.over = true
	_battlefield.set_drop_enabled(false)
	_deadlock.hide()
	_session.say("system", "VICTORY! All enemies are down." if won else "DEFEAT... you ran out of HP.")
	_result_data = BattleOutcome.conclude(_session.state, won)
	_refresh_all()
	_result.show_result(won, "All enemies are down." if won else "You ran out of HP.",
			_result_data.summary())


func _on_result_confirmed() -> void:
	if battle_finished.get_connections().is_empty():
		get_tree().reload_current_scene()
	else:
		battle_finished.emit(_result_data)


# ---------- chanting input ----------

func _on_hand_selected(index: int) -> void:
	if not _flow.can_place():
		return
	_selected_fragment = -1 if _selected_fragment == index else index
	_refresh_hand.call_deferred()


func _on_hand_drag_started(index: int) -> void:
	if _flow.can_place():
		_selected_fragment = index


func _on_hand_rotate(index: int) -> void:
	if not _flow.can_place():
		return
	_selected_fragment = index
	_rotate(index)


func _rotate(index: int) -> void:
	if index < 0 or index >= _session.deck.hand.size():
		return
	_session.deck.rotate_at(index)
	_refresh_hand.call_deferred()


func _on_cell_clicked(anchor: Vector2i) -> void:
	if not _flow.can_place():
		return
	if _selected_fragment < 0:
		_io.set_hint("Select a fragment first.")
		return
	_place(_selected_fragment, anchor)


func _place(index: int, anchor: Vector2i) -> void:
	if not _flow.can_place():
		return
	var fragment := _session.deck.fragment_at(index)
	var tiles := fragment.cells.size() if fragment != null else 0
	var error := _session.place_fragment(index, anchor)
	if not error.is_empty():
		_io.set_hint(error)
		return
	_selected_fragment = -1
	_io.set_hint("Placed %d tiles." % tiles)
	_refresh_all.call_deferred()


func _on_cast_pressed() -> void:
	if not _flow.can_start_casting():
		return
	_session.start_casting()
	_selected_fragment = -1
	_selected_spell = null
	_inspect_player = false
	_flow.enter(BattleFlow.Phase.CASTING)
	_io.set_phase(BattleIO.Phase.CASTING)
	_battlefield.set_drop_enabled(true)
	_io.set_hint("Casting: drag a spell card onto a target, or select a card and double-click it. Esc deselects.")
	_refresh_all()


func _on_ultimate_pressed() -> void:
	if not _flow.can_use_ultimate() or not _session.use_ultimate():
		return
	if _check_outcome():
		return
	_refresh_all()


# ---------- casting input ----------

func _on_card_clicked(definition: SpellDefinition, is_double: bool) -> void:
	if not _flow.can_cast_spell():
		return
	if is_double or _selected_spell == definition:
		var is_self := definition.target_kind == SpellDefinition.TargetKind.SELF
		_session.state.ensure_valid_target()
		_cast(-1 if is_self else _session.state.target_index, definition)
		return
	_selected_spell = definition
	_io.spell_zone.set_selected(definition)
	_refresh_detail()


func _on_spell_dropped(target_index: int, definition: SpellDefinition) -> void:
	if _flow.can_cast_spell():
		_cast(target_index, definition)


func _cast(target_index: int, definition: SpellDefinition) -> void:
	var error := _session.cast_queued(definition, target_index)
	if not error.is_empty():
		_io.set_hint(error)
		return
	if _selected_spell == definition and _session.queued_count(definition) == 0:
		_selected_spell = null
	if _check_outcome():
		return
	_refresh_all()


func _on_end_turn_pressed() -> void:
	if not _flow.can_end_turn():
		return
	_session.cast_basic_attack()
	_battlefield.set_drop_enabled(false)
	_clear_spell_selection(false)
	var lines: Array[String] = [_session.turn_total_line()]
	_finish_player_turn(lines)


func _clear_spell_selection(redraw := true) -> void:
	_selected_spell = null
	_io.spell_zone.set_selected(null)
	if redraw:
		_refresh_detail()


func _on_enemy_clicked(index: int) -> void:
	var state := _session.state
	if not _flow.can_select_target() or index < 0 or index >= state.enemies.size() \
			or state.enemies[index].is_dead():
		return
	state.target_index = index
	_inspect_player = false
	_refresh_all()


func _on_player_clicked() -> void:
	if _flow.can_cast_spell():
		_inspect_player = true
		_refresh_detail()


# ---------- deadlock ----------

func _open_deadlock() -> void:
	_flow.enter(BattleFlow.Phase.DEADLOCK)
	_io.set_hint("DEADLOCK: no fragment fits the board.")
	_session.say("system", "Deadlock! No fragment fits the board.")
	_deadlock.open(_session.board.filled_count(), _session.backlash_check())


func _on_backlash() -> void:
	if not _flow.can_resolve_deadlock() or not _session.backlash():
		return
	_deadlock.hide()
	var lines: Array[String] = ["Backlash ends your turn."]
	_finish_player_turn(lines)


func _on_fizzle() -> void:
	if not _flow.can_resolve_deadlock():
		return
	_session.fizzle()
	_deadlock.hide()
	var lines: Array[String] = ["Fizzle ends your turn."]
	_finish_player_turn(lines)


# ---------- drawing ----------

func _on_log_line(kind: String, text: String) -> void:
	_console.add_entry(kind, text if kind == "round" else "R%d %s" % [_session.state.turn, text])


func _can_use_ultimate() -> bool:
	return _flow.can_use_ultimate() and _session.can_use_ultimate()


func _refresh_all() -> void:
	var state := _session.state
	_battlefield.refresh(state, _can_use_ultimate())
	_top_panel.refresh(state)
	_refresh_board()
	_refresh_hand()
	_refresh_spells()
	_io.set_cast_enabled(_flow.can_start_casting())
	_refresh_detail()


func _refresh_board() -> void:
	_io.board_view.outlined = _session.outlined
	_io.board_view.ghosts = _session.ghosts
	_io.board_view.refresh()


func _refresh_hand() -> void:
	_io.hand_view.show_hand(_session.deck.hand, _selected_fragment)


func _refresh_spells() -> void:
	var mode := SpellZone.Mode.CASTING if _flow.phase == BattleFlow.Phase.CASTING \
			else SpellZone.Mode.CHANTING
	var entries: Array[Dictionary] = []
	for definition in _session.spells:
		var first := _session.first_queued(definition)
		var projected := -1
		if first != null:
			projected = _projected_damage(first)
		entries.append({"definition": definition, "count": _session.queued_count(definition),
				"projected": projected})
	_io.spell_zone.show_spells(entries, mode)
	_io.spell_zone.set_selected(_selected_spell)


func _projected_damage(q: QueuedSpell) -> int:
	var one: Array[QueuedSpell] = [q]
	var preview := SpellResolver.preview(one, 0, _session.state)
	var damages: Array = preview["spell_damages"]
	return int(damages[0]) if not damages.is_empty() else 0


func _refresh_detail() -> void:
	var state := _session.state
	if _flow.phase != BattleFlow.Phase.CASTING or state.enemies.is_empty():
		return
	state.ensure_valid_target()
	var spell := _selected_spell
	var self_spell := spell != null and spell.target_kind == SpellDefinition.TargetKind.SELF
	var on_player := _inspect_player or self_spell
	var index := state.target_index
	var subject: CombatantState = state.player if on_player else state.enemies[index]
	var data := {"role": "YOU" if on_player else "TARGET"}
	if not on_player:
		data["intent"] = _session.intent_text(index)
	var tiles := _session.board.filled_count()
	if tiles > 0:
		var none: Array[QueuedSpell] = []
		data["basic_tiles"] = tiles
		data["basic_info"] = "Projected %d damage" % int(SpellResolver.preview(none, tiles, state)["basic"])
	if spell != null:
		data["spell_name"] = spell.display_name
		var fx: Array[String] = []
		for effect in spell.effects:
			fx.append(effect.describe())
		data["spell_effects"] = ", ".join(fx)
		var first := _session.first_queued(spell)
		if first != null and spell.base_damage > 0 and not on_player:
			data["spell_info"] = "Projected %d damage" % _projected_damage(first)
	_io.target_detail.show_data(subject, data)
