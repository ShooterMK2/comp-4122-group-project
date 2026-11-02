class_name TerrainDefinition
extends RefCounted

enum Stat { ATTACK, DEFENCE, SPEED, OTHER }

var display_name := "Terrain"
var modifiers: Array[Dictionary] = []

static func make(p_name: String, p_modifiers: Array[Dictionary]) -> TerrainDefinition:
	var terrain := TerrainDefinition.new()
	terrain.display_name = p_name
	terrain.modifiers = p_modifiers
	return terrain

func attack_multiplier_for(element: int) -> float:
	return _multiplier_for(element, Stat.ATTACK)

func defence_multiplier_for(element: int) -> float:
	return _multiplier_for(element, Stat.DEFENCE)

func speed_multiplier_for(is_player: bool) -> float:
	var multiplier := 1.0
	for modifier in modifiers:
		if modifier["stat"] != Stat.SPEED:
			continue
		if modifier.get("player_only", false) and not is_player:
			continue
		multiplier *= 1.0 + modifier["delta"]
	return multiplier

func description() -> String:
	var parts: Array[String] = []
	for modifier in modifiers:
		var sign := "+" if modifier["delta"] >= 0.0 else "-"
		var percent := roundi(absf(modifier["delta"]) * 100.0)
		var scope := Elements.name_of(modifier["element"])
		var stat: String = ["ATK", "DEF", "SPD", "OTHER"][modifier["stat"]]
		parts.append("%s %s %s%d%%" % [scope, stat, sign, percent])
	return ", ".join(parts)

func _multiplier_for(element: int, stat: Stat) -> float:
	var multiplier := 1.0
	for modifier in modifiers:
		if modifier["stat"] == stat and modifier["element"] == element:
			multiplier *= 1.0 + modifier["delta"]
	return multiplier