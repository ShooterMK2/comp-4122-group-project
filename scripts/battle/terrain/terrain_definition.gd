class_name TerrainDefinition
extends RefCounted

enum Stat { ATTACK, DEFENCE, SPEED, OTHER }

var display_name := "Terrain"
var primary_id := ""
var secondary_id := ""
var modifiers: Array[Dictionary] = []

static func make(p_name: String, p_modifiers: Array[Dictionary],
		p_primary_id: String = "", p_secondary_id: String = "") -> TerrainDefinition:
	var terrain := TerrainDefinition.new()
	terrain.display_name = p_name
	terrain.primary_id = p_primary_id
	terrain.secondary_id = p_secondary_id
	terrain.modifiers = p_modifiers
	return terrain

## Element-scoped ATK. Player-only: returns 1.0 when for_player is false.
func attack_multiplier_for(element: int, for_player: bool = true) -> float:
	if not for_player:
		return 1.0
	return _multiplier_for_attack(element)

## Flat DEF (not element-scoped). Player-only: returns 1.0 when for_player is false.
func defence_multiplier_for(for_player: bool = true) -> float:
	if not for_player:
		return 1.0
	return _flat_multiplier_for(Stat.DEFENCE)

## Flat SPD (not element-scoped). Player-only: returns 1.0 when for_player is false.
func speed_multiplier_for(for_player: bool = true) -> float:
	if not for_player:
		return 1.0
	return _flat_multiplier_for(Stat.SPEED)

func description() -> String:
	var parts: Array[String] = []
	for modifier in modifiers:
		var sign_str := "+" if modifier["delta"] >= 0.0 else "-"
		var percent := roundi(absf(modifier["delta"]) * 100.0)
		var stat: String = ["ATK", "DEF", "SPD", "OTHER"][modifier["stat"]]
		if modifier["stat"] == Stat.ATTACK:
			var scope := Elements.name_of(int(modifier.get("element", Elements.Element.NONE)))
			parts.append("%s %s %s%d%%" % [scope, stat, sign_str, percent])
		else:
			parts.append("%s %s%d%%" % [stat, sign_str, percent])
	return ", ".join(parts)

func _multiplier_for_attack(element: int) -> float:
	var multiplier := 1.0
	for modifier in modifiers:
		if modifier["stat"] != Stat.ATTACK:
			continue
		if int(modifier.get("element", Elements.Element.NONE)) != element:
			continue
		multiplier *= 1.0 + float(modifier["delta"])
	return multiplier

func _flat_multiplier_for(stat: Stat) -> float:
	var multiplier := 1.0
	for modifier in modifiers:
		if modifier["stat"] != stat:
			continue
		multiplier *= 1.0 + float(modifier["delta"])
	return multiplier
