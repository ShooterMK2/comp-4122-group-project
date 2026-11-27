class_name BattlefieldPanel
extends Control
# Glue between the battle controller and the stage (current Control-based layout).
# It never changes game state; the battle controller owns that.

signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition: SpellDefinition)

const ENEMY_SCENE := preload("res://scenes/battle/ui/enemy_actor.tscn")
const PLAYER_ACTOR_PATH := "res://scenes/battle/ui/player_actor.tscn"
const ENEMY_HEIGHT := 128.0       # TUNABLE: on-screen enemy sprite height in pixels
const POPUP_RISE := 36.0          # TUNABLE: pixels the popup floats upward
const POPUP_TIME := 1.1           # TUNABLE: seconds before the popup has faded out
const POPUP_FONT_SIZE := 16
const POPUP_COLOR := Color(1.0, 0.45, 0.4)

@onready var _player_panel: PlayerPanel = %PlayerPanel
@onready var _enemy_slots: HBoxContainer = %EnemySlots
@onready var _player_slots: HBoxContainer = get_node_or_null("%PlayerSlots") as HBoxContainer

var player_actor: PlayerActor
var _drop_enabled := false
var _popup: Label


func _ready() -> void:
	_player_panel.ultimate_pressed.connect(func(): ultimate_pressed.emit())
	_player_panel.clicked.connect(func(): player_clicked.emit())


# ---------- spawning ----------

func setup(state: BattleState) -> void:
	var pd := PlayerDefinition.default_player()
	_player_panel.setup(pd.art_name, pd.placeholder_color)
	_spawn_player(pd)
	_spawn_enemies(state.enemy_defs)
	refresh(state, false)


# One actor per definition, in slot order: slot i must match state.enemies[i].
func _spawn_enemies(defs: Array[EnemyDefinition]) -> void:
	_clear(_enemy_slots)
	var count := mini(defs.size(), EncounterDefinition.MAX_ENEMIES)
	if defs.size() > count:
		push_warning("Encounter has %d enemies; only %d are shown." % [defs.size(), count])
	for i in count:
		var actor := ENEMY_SCENE.instantiate() as EnemyActor
		if actor == null:
			push_error("enemy_actor.tscn root is not an EnemyActor (script missing or failed to compile).")
			return
		actor.name = "Enemy%d" % (i + 1)
		actor.size_flags_vertical = Control.SIZE_SHRINK_END
		_enemy_slots.add_child(actor)
		actor.setup_enemy(defs[i], ENEMY_HEIGHT)
		actor.connect("clicked", func(): enemy_clicked.emit(i))
		actor.connect("spell_dropped", func(d: SpellDefinition): spell_dropped_on.emit(i, d))
		if actor.has_method("set_drop_enabled"):
			actor.call("set_drop_enabled", _drop_enabled)


func _spawn_player(def: PlayerDefinition) -> void:
	if _player_slots == null or not ResourceLoader.exists(PLAYER_ACTOR_PATH):
		return
	_clear(_player_slots)
	var scene := load(PLAYER_ACTOR_PATH) as PackedScene
	player_actor = scene.instantiate() as PlayerActor
	if player_actor == null:
		push_error("player_actor.tscn root is not a PlayerActor.")
		return
	player_actor.size_flags_vertical = Control.SIZE_SHRINK_END
	_player_slots.add_child(player_actor)
	player_actor.setup(def)


func _clear(slots: Container) -> void:
	for c in slots.get_children():
		slots.remove_child(c)
		c.queue_free()


# ---------- API used by the battle controller ----------

func set_drop_enabled(on: bool) -> void:
	_drop_enabled = on
	for a in _enemy_slots.get_children():
		if a.has_method("set_drop_enabled"):
			a.call("set_drop_enabled", on)


# can_ultimate is decided by the controller (phase + charge), so the panel never
# duplicates the charge threshold.
func refresh(state: BattleState, can_ultimate: bool) -> void:
	var ult_name := "NONE"
	var ult: UltimateDefinition = RunState.equipped_ultimate()
	if ult != null:
		ult_name = ult.display_name.to_upper()
	_player_panel.refresh(state.player, state.charge_gauge, can_ultimate, ult_name)
	if player_actor != null:
		player_actor.set_dead(state.player.is_dead())
	for i in mini(_enemy_slots.get_child_count(), state.enemies.size()):
		var actor := _enemy_slots.get_child(i) as EnemyActor
		var enemy := state.enemies[i]
		actor.refresh(enemy)
		if actor.has_method("set_alive"):
			actor.call("set_alive", not enemy.is_dead())
		if actor.has_method("set_selected"):
			actor.call("set_selected", not enemy.is_dead() and i == state.target_index)


# Floating message beside the player panel. One at a time; a new call replaces the old one.
func show_popup_at_player(text: String) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.queue_free()
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 50
	label.add_theme_font_size_override("font_size", POPUP_FONT_SIZE)
	label.add_theme_color_override("font_color", POPUP_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	var origin := _player_panel.global_position - global_position
	label.position = origin + Vector2(_player_panel.size.x + 8.0, 4.0)
	_popup = label
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - POPUP_RISE, POPUP_TIME)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_TIME).set_delay(POPUP_TIME * 0.4)
	tween.chain().tween_callback(label.queue_free)
