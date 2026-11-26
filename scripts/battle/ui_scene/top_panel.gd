class_name TopPanel
extends Control
# Top bar: terrain, round and turn order. Call refresh(state) after every state change.
# This is the only part that reads BattleState; the three displays just show plain data.

const ORDER_COUNT := 7

@onready var _terrain: TerrainDisplay = %TerrainDisplay
@onready var _round: RoundDisplay = %RoundDisplay
@onready var _order: TurnOrderBar = %TurnOrderBar

var _player_def: PlayerDefinition


func refresh(state: BattleState) -> void:
	_terrain.show_terrain(state.terrain)
	_round.show_round(state.turn)
	var entries := TurnOrderForecast.upcoming(state, ORDER_COUNT)
	for e in entries:
		_add_art(e, state)
	_order.show_order(entries)


func _add_art(entry: Dictionary, state: BattleState) -> void:
	var actor: int = entry["actor"]
	var art := ""
	var color := HoverIcon.PLACEHOLDER_COLOR
	if actor == TurnOrderSystem.PLAYER:
		if _player_def == null:
			_player_def = PlayerDefinition.default_player()
		art = _player_def.art_name
		color = _player_def.placeholder_color
	else:
		var def: EnemyDefinition = state.enemy_defs[actor - 1]
		art = def.art_name
		color = def.placeholder_color
	entry["texture"] = _icon_texture(art)
	entry["color"] = color


# Same rule as PlayerPanel: a dedicated <art>_icon first, then the plain art.
func _icon_texture(art_name: String) -> Texture2D:
	var base := art_name.get_basename()
	var tex: Texture2D = AssetLookup.character(base + "_icon")
	if tex == null:
		tex = AssetLookup.character(base)
	return tex
