class_name BattlefieldPanel
extends HBoxContainer
# Player zone and enemy zone. Shows data, reports clicks and drops.

signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition: SpellDefinition)   # -1 = the player

@onready var _player: CombatantPanel = %PlayerPanel
@onready var _panels: Array = %EnemyRow.get_children()

func _ready() -> void:
	_player.ultimate_pressed.connect(func(): ultimate_pressed.emit())
	_player.clicked.connect(func(): player_clicked.emit())
	_player.spell_dropped.connect(func(d: SpellDefinition): spell_dropped_on.emit(-1, d))
	for i in _panels.size():
		var panel: CombatantPanel = _panels[i]
		panel.clicked.connect(func(): enemy_clicked.emit(i))
		panel.spell_dropped.connect(func(d: SpellDefinition): spell_dropped_on.emit(i, d))

func setup(state: BattleState) -> void:
	var pd := PlayerDefinition.default_player()
	_player.setup(pd.art_name, pd.placeholder_color, "PLAYER")
	for i in _panels.size():
		var panel: CombatantPanel = _panels[i]
		panel.visible = i < state.enemies.size()          # unused slots disappear
		if i < state.enemies.size():
			var def: EnemyDefinition = state.enemy_defs[i]
			panel.setup(def.art_name, def.placeholder_color, "DUMMY")
	refresh(state)

func set_drop_enabled(on: bool) -> void:
	_player.drop_enabled = on
	for panel: CombatantPanel in _panels:
		panel.drop_enabled = on

func refresh(state: BattleState) -> void:
	_player.refresh(state.player, "", false, state.charge_gauge,
		state.charge_gauge >= 100.0 and not state.ultimate_active)
	for i in _panels.size():
		if i >= state.enemies.size():
			continue
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
		var panel: CombatantPanel = _panels[i]
		panel.refresh(e, intent, i == state.target_index)
