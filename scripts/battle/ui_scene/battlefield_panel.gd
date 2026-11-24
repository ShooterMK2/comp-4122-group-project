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
	var ult_name := "ULTIMATE"
	var ult: UltimateDefinition = RunState.equipped_ultimate()
	if ult != null:
		ult_name = ult.display_name.to_upper()
	_player.refresh(state.player, "", false, state.charge_gauge,
		state.charge_gauge >= 100.0 and not state.ultimate_active, ult_name)
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
			if str(info.get("kind", "")) != "":
				intent = "%s [%s]" % [intent, info["kind"]]
		var panel: CombatantPanel = _panels[i]
		panel.refresh(e, intent, i == state.target_index)
