class_name BattlefieldPanel
extends Control
# Glue between the battle controller and the stage (current Control-based layout).

signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition: SpellDefinition)

const ENEMY_SCENE := preload("res://scenes/battle/ui/enemy_actor.tscn")

@onready var _player_panel: PlayerPanel = %PlayerPanel
@onready var _enemy_slots: HBoxContainer = %EnemySlots

var _drop_enabled := false


func _ready() -> void:
	if _player_panel != null:
		_player_panel.ultimate_pressed.connect(func(): ultimate_pressed.emit())
		if _player_panel.has_signal("clicked"):
			_player_panel.clicked.connect(func(): player_clicked.emit())


func setup(state: BattleState) -> void:
	var pd := PlayerDefinition.default_player()
	_player_panel.setup(pd.art_name, pd.placeholder_color)
	_spawn_enemies(state.enemy_defs)
	refresh(state)


func _spawn_enemies(defs: Array[EnemyDefinition]) -> void:
	for c in _enemy_slots.get_children():
		_enemy_slots.remove_child(c)
		c.queue_free()
	var count := mini(defs.size(), EncounterDefinition.MAX_ENEMIES)
	if defs.size() > count:
		push_warning("Encounter has %d enemies; only %d are shown." % [defs.size(), count])
	for i in count:
		var actor: Control = ENEMY_SCENE.instantiate()
		actor.name = "Enemy%d" % (i + 1)
		actor.size_flags_vertical = Control.SIZE_SHRINK_END
		_enemy_slots.add_child(actor)
		actor.call("setup", defs[i])
		actor.connect("clicked", func(): enemy_clicked.emit(i))
		actor.connect("spell_dropped", func(d: SpellDefinition): spell_dropped_on.emit(i, d))
		actor.call("set_drop_enabled", _drop_enabled)


func set_drop_enabled(on: bool) -> void:
	_drop_enabled = on
	for a in _enemy_slots.get_children():
		if a.has_method("set_drop_enabled"):
			a.set_drop_enabled(on)


func refresh(state: BattleState) -> void:
	var ult_name := "NONE"
	var can_ult := false
	var ult: UltimateDefinition = RunState.equipped_ultimate()
	if ult != null:
		ult_name = ult.display_name.to_upper()
		can_ult = state.charge_gauge >= 100.0 and not state.ultimate_active
	_player_panel.refresh(state.player, state.charge_gauge, can_ult, ult_name)

	for i in _enemy_slots.get_child_count():
		if i >= state.enemies.size():
			continue
		var actor: Control = _enemy_slots.get_child(i)
		var e: CombatantState = state.enemies[i]
		var dead := e.is_dead()
		actor.call("set_alive", not dead)
		actor.call("set_selected", not dead and i == state.target_index)
		if actor.has_node("%HpBar"):
			var bar: Range = actor.get_node("%HpBar")
			bar.max_value = e.max_hp
			bar.value = e.hp
		if actor.has_node("%HpLabel"):
			(actor.get_node("%HpLabel") as Label).text = "%d/%d" % [e.hp, e.max_hp]
