class_name Battlefield
extends Control
# The battle picture: enemy and player actors, player panel, input relay.
# It never changes game state; the battle controller owns that.

signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition: SpellDefinition)

const ENEMY_ACTOR_SCENE := preload("res://scenes/battle/ui/enemy_actor.tscn")
const PLAYER_ACTOR_SCENE := preload("res://scenes/battle/ui/player_actor.tscn")
const ENEMY_HEIGHT := 128.0    # TUNABLE: on-screen enemy sprite height in pixels

# Only for opening battlefield.tscn on its own. The controller drives everything via setup().
@export var encounter: EncounterDefinition
@export var preview_on_ready := false

@onready var _enemy_slots: HBoxContainer = %EnemySlots
@onready var _player_slots: HBoxContainer = %PlayerSlots
@onready var _player_panel: PlayerPanel = %PlayerPanel

var player_actor: PlayerActor
var _drop_enabled := false


func _ready() -> void:
	_player_panel.ultimate_pressed.connect(func(): ultimate_pressed.emit())
	if preview_on_ready and encounter != null:
		spawn_enemies(encounter.make_enemies())
		var def := PlayerDefinition.default_player()
		_show_player(def)
		_player_panel.refresh(CombatantState.from_definition(def), 0.0, false)


# ---------- spawning ----------

# One actor per definition, in slot order: slot i must match state.enemies[i].
func spawn_enemies(defs: Array[EnemyDefinition]) -> void:
	_clear(_enemy_slots)
	for i in defs.size():
		var actor := ENEMY_ACTOR_SCENE.instantiate() as EnemyActor
		actor.size_flags_vertical = Control.SIZE_SHRINK_END
		_enemy_slots.add_child(actor)
		actor.setup_enemy(defs[i], ENEMY_HEIGHT)
		actor.clicked.connect(func(): enemy_clicked.emit(i))
		actor.spell_dropped.connect(func(d: SpellDefinition): spell_dropped_on.emit(i, d))
		actor.set_drop_enabled(_drop_enabled)


func spawn_player(def: PlayerDefinition = null) -> void:
	_clear(_player_slots)
	var d := def if def != null else PlayerDefinition.default_player()
	player_actor = PLAYER_ACTOR_SCENE.instantiate() as PlayerActor
	player_actor.size_flags_vertical = Control.SIZE_SHRINK_END
	_player_slots.add_child(player_actor)
	player_actor.setup(d)


func _show_player(def: PlayerDefinition) -> void:
	_player_panel.setup(def.art_name, def.placeholder_color)
	spawn_player(def)


func _clear(slots: Container) -> void:
	for c in slots.get_children():
		slots.remove_child(c)
		c.queue_free()


# ---------- API used by the battle controller ----------

func setup(state: BattleState) -> void:
	_show_player(PlayerDefinition.default_player())
	spawn_enemies(state.enemy_defs)
	refresh(state, false)


func refresh(state: BattleState, can_ultimate: bool) -> void:
	_player_panel.refresh(state.player, state.charge_gauge, can_ultimate)
	if player_actor != null:
		player_actor.set_dead(state.player.is_dead())
	for i in mini(_enemy_slots.get_child_count(), state.enemies.size()):
		var actor := _enemy_slots.get_child(i) as EnemyActor
		var enemy := state.enemies[i]
		actor.refresh(enemy)
		actor.set_alive(not enemy.is_dead())
		actor.set_selected(not enemy.is_dead() and i == state.target_index)


func set_drop_enabled(on: bool) -> void:
	_drop_enabled = on
	for a in _enemy_slots.get_children():
		a.set_drop_enabled(on)
