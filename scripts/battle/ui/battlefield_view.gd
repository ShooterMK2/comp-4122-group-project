class_name BattlefieldView
extends HBoxContainer

signal enemy_clicked(index: int)

var _player_view: CombatantView
var _enemy_views: Array[CombatantView] = []
var _damage_previews: Array[DamagePreview] = []

func _init() -> void:
	custom_minimum_size = Vector2(0, 260)
	add_theme_constant_override("separation", 12)

func setup(state: BattleState) -> void:
	_player_view = CombatantView.new()
	var player_definition := PlayerDefinition.default_player()
	_player_view.setup(player_definition.art_name, player_definition.placeholder_color,
		"PLAYER", false)
	add_child(_player_view)
	add_child(VSeparator.new())
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	for i in state.enemies.size():
		var def: EnemyDefinition = state.enemy_defs[i]
		var view := CombatantView.new()
		view.setup(def.art_name, def.placeholder_color, "DUMMY", true)
		view.clicked.connect(_on_enemy_clicked.bind(i))
		var enemy_column := HBoxContainer.new()
		enemy_column.add_theme_constant_override("separation", 4)
		enemy_column.add_child(view)
		var preview := DamagePreview.new()
		enemy_column.add_child(preview)
		row.add_child(enemy_column)
		_enemy_views.append(view)
		_damage_previews.append(preview)
	refresh(state)

func _on_enemy_clicked(index: int) -> void:
	enemy_clicked.emit(index)

func refresh(state: BattleState, tile_count: int = 0,
		queue: Array[QueuedSpell] = []) -> void:
	_player_view.refresh(state.player, "", false)
	for i in _enemy_views.size():
		var e: CombatantState = state.enemies[i]
		var intent := ""
		if e.is_dead():
			intent = "Destroyed"
		elif e.is_broken():
			intent = "BROKEN (skips turn)"
		elif e.get_status(StatusTypes.Status.FREEZE) > 0:
			intent = "FROZEN (skips turn)"
		else:
			var info := EnemyIntentSystem.get_intent(state.enemy_defs[i], state.turn)
			intent = str(info["name"])
		_enemy_views[i].refresh(e, intent, i == state.target_index)
		_damage_previews[i].show_preview(
			_build_damage_actions(state, i, tile_count, queue))

func _build_damage_actions(state: BattleState, enemy_index: int,
		tile_count: int, queue: Array[QueuedSpell]) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for q in queue:
		var sim := state.duplicate_state()
		sim.target_index = enemy_index
		var target: CombatantState = sim.player if q.definition.target_kind == SpellDefinition.TargetKind.SELF \
			else sim.enemies[enemy_index]
		SpellResolver.apply_special_tiles(q.special_tiles, sim.player, target, [])
		var info: Dictionary = DamageCalculator.explain_spell(q.definition.base_damage, sim.player,
			target, q.definition.primary_element(), q.definition.other_multiplier, sim.terrain)
		actions.append({"name": q.definition.display_name, "info": info})
	if tile_count > 0:
		var sim_basic := state.duplicate_state()
		sim_basic.target_index = enemy_index
		var info: Dictionary = DamageCalculator.explain_basic_attack(tile_count, sim_basic.player,
			sim_basic.enemies[enemy_index], sim_basic.terrain)
		actions.append({"name": "Basic attack (%d)" % tile_count, "info": info})
	return actions
