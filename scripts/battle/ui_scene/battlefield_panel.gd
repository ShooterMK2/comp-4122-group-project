class_name BattlefieldPanel
extends Control
# Glue between the battle controller and the stage.
# Owns: the two zones, the click/drop layer over the world, and the player panel.

signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition: SpellDefinition)

const NO_TARGET := -2
const PLAYER_HIT_HALF_WIDTH := 70.0

@export var show_zones := true          # untick once the zones are tuned

@onready var _world: BattleWorld = %World
@onready var _world_view: SubViewportContainer = %WorldView
@onready var _player_panel: PlayerPanel = %PlayerPanel
@onready var _player_zone: ReferenceRect = %PlayerZone
@onready var _enemy_zone: ReferenceRect = %EnemyZone
@onready var _hit_layer: Control = %HitLayer

var _drop_enabled := false


func _ready() -> void:
	_player_zone.visible = show_zones
	_enemy_zone.visible = show_zones

	_player_panel.ultimate_pressed.connect(func(): ultimate_pressed.emit())

	_hit_layer.gui_input.connect(_on_hit_input)
	_hit_layer.set_drag_forwarding(Callable(), _hit_can_drop, _hit_drop)

	_world_view.resized.connect(_layout)
	_player_zone.resized.connect(_layout)
	_enemy_zone.resized.connect(_layout)
	_layout.call_deferred()


# ---------- public API used by the battle controller ----------
func setup(state: BattleState) -> void:
	var pd := PlayerDefinition.default_player()
	_world.player_actor.setup(pd.art_name, pd.placeholder_color, "PLAYER", BattleWorld.PLAYER_HEIGHT)
	_player_panel.setup(pd.art_name, pd.placeholder_color)
	_world.spawn_enemies(state.enemy_defs)
	_layout()
	refresh(state)


func set_floor_texture(tex: Texture2D) -> void:
	_world.set_floor(tex)


func set_drop_enabled(on: bool) -> void:
	_drop_enabled = on


func refresh(state: BattleState) -> void:
	_player_panel.refresh(state.player, state.charge_gauge,
		not state.over and state.charge_gauge >= 100.0)
	_world.player_actor.set_dead(state.player.is_dead())

	for i in _world.enemy_actors.size():
		var actor := _world.enemy_actors[i]
		var e: CombatantState = state.enemies[i]
		if actor.has_method("refresh"):
			actor.refresh(e, _intent_text(state, i), i == state.target_index)
		if actor.has_method("set_dead"):
			actor.set_dead(e.is_dead())


# ---------- layout ----------
func _layout() -> void:
	if not is_node_ready():
		return
	_world.layout(_world_view.size, _zone_rect(_player_zone), _zone_rect(_enemy_zone))


func _zone_rect(zone: Control) -> Rect2:
	return Rect2(zone.global_position - _world_view.global_position, zone.size)


# ---------- clicks and spell drops over the world ----------
# Returns an enemy index, -1 for the player, or NO_TARGET.
func _target_at(pos: Vector2) -> int:
	if pos.y > _world.ground_y:
		return NO_TARGET
	var half := _world.enemy_spacing * 0.5
	for i in _world.enemy_actors.size():
		if absf(pos.x - _world.enemy_actors[i].position.x) <= half:
			return i
	if absf(pos.x - _world.player_actor.position.x) <= PLAYER_HIT_HALF_WIDTH:
		return -1
	return NO_TARGET


func _on_hit_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var t := _target_at(event.position - _world_view.position)
	if t >= 0:
		enemy_clicked.emit(t)
	elif t == -1:
		player_clicked.emit()


func _hit_can_drop(at_position: Vector2, data: Variant) -> bool:
	return _drop_enabled and data is Dictionary and data.has("definition") \
		and _target_at(at_position - _world_view.position) != NO_TARGET


func _hit_drop(at_position: Vector2, data: Variant) -> void:
	var t := _target_at(at_position - _world_view.position)
	if t != NO_TARGET:
		spell_dropped_on.emit(t, data["definition"])


# ---------- helpers ----------
func _intent_text(state: BattleState, i: int) -> String:
	var e: CombatantState = state.enemies[i]
	if e.is_dead():
		return "Destroyed"
	if e.is_broken():
		return "BROKEN (skips turn)"
	if e.get_status(StatusTypes.Status.FREEZE) > 0:
		return "FROZEN (skips turn)"
	var info = EnemyIntentSystem.get_intent(state.enemy_defs[i], state.turn)
	return str(info.name)
