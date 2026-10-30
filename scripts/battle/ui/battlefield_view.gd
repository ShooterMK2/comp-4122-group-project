class_name BattlefieldView
extends HBoxContainer

signal enemy_clicked(index: int)

var _player_view: CombatantView
var _enemy_views: Array[CombatantView] = []

func _init() -> void:
	custom_minimum_size = Vector2(0, 260)
	add_theme_constant_override("separation", 12)

func setup(state: BattleState) -> void:
	_player_view = CombatantView.new()
	_player_view.setup(BattleConfig.PLAYER_ART, Color(0.25, 0.4, 0.8), "PLAYER", false)
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
		row.add_child(view)
		_enemy_views.append(view)
	refresh(state)

func _on_enemy_clicked(index: int) -> void:
	enemy_clicked.emit(index)

func refresh(state: BattleState) -> void:
	_player_view.refresh(state.player, "", false)
	for i in _enemy_views.size():
		var e: CombatantState = state.enemies[i]
		var intent := ""
		if e.is_dead():
			intent = "Destroyed"
		elif e.get_status(StatusTypes.Status.FREEZE) > 0:
			intent = "FROZEN (skips turn)"
		else:
			var info := EnemyIntentSystem.get_intent(state.enemy_defs[i], state.turn)
			intent = str(info["name"])
		_enemy_views[i].refresh(e, intent, i == state.target_index)
