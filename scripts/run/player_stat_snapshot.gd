class_name PlayerStatSnapshot
extends RefCounted

var display_name: String = "Player"
var level: int = 1
var base_max_hp: int = 1
var base_attack: int = 1
var base_defence: int = 0
var base_speed: float = 1.0
var equip_max_hp: int = 0
var equip_attack: int = 0
var equip_defence: int = 0
var equip_speed: float = 0.0
var item_max_hp: int = 0
var item_attack: int = 0
var item_defence: int = 0
var item_speed: float = 0.0
var start_shield: int = 0
var elemental_weaknesses: Array[int] = []
var elemental_strengths: Array[int] = []
var art_name: String = ""
var placeholder_color: Color = Color(0.2, 0.45, 0.7, 1)

func max_hp() -> int:
	return maxi(1, base_max_hp + equip_max_hp + item_max_hp)

func attack() -> int:
	return maxi(0, base_attack + equip_attack + item_attack)

func defence() -> int:
	return maxi(0, base_defence + equip_defence + item_defence)

func speed() -> float:
	return maxf(0.1, base_speed + equip_speed + item_speed)

## Format: ATK = 8 (5 + [2] + {1})
static func format_stat(label: String, total: float, base: float, equip: float, item: float,
		as_int: bool = true) -> String:
	if as_int:
		return "%s = %d (%d + [%d] + {%d})" % [
			label, int(total), int(base), int(equip), int(item)]
	return "%s = %.0f (%.0f + [%.0f] + {%.0f})" % [label, total, base, equip, item]

func format_attack() -> String:
	return format_stat("ATK", attack(), base_attack, equip_attack, item_attack)

func format_defence() -> String:
	return format_stat("DEF", defence(), base_defence, equip_defence, item_defence)

func format_speed() -> String:
	return format_stat("SPD", speed(), base_speed, equip_speed, item_speed, false)

func format_max_hp() -> String:
	return format_stat("MAX HP", max_hp(), base_max_hp, equip_max_hp, item_max_hp)
