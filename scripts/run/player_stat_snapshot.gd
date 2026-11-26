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
var level_max_hp: int = 0
var level_attack: int = 0
var level_defence: int = 0
var level_speed: float = 0.0
var start_shield: int = 0
## Incoming damage multiplier (1.0 = normal; 0.8 = 20% resistance).
var damage_taken_multiplier: float = 1.0
## Additive spell damage by element (0.20 = +20%; may be negative).
var element_spell_damage_mult: Dictionary = {}
## Extra outgoing damage from gear (0.20 = +20%).
var damage_dealt_bonus: float = 0.0
## Multiplier applied after flat max HP sum (e.g. -0.10 => ×0.9).
var max_hp_mult: float = 0.0
## Multiplier applied after flat speed sum (e.g. 0.20 => ×1.2).
var speed_mult: float = 0.0
## Equipped start-of-battle special-tile buffs (-1 none, 0/1/2, -2 random).
var start_stat_buffs: Array[int] = []
var elemental_weaknesses: Array[int] = []
var elemental_strengths: Array[int] = []
var art_name: String = ""
var placeholder_color: Color = Color(0.2, 0.45, 0.7, 1)

func flat_max_hp() -> int:
	return maxi(1, base_max_hp + equip_max_hp + item_max_hp + level_max_hp)

func max_hp() -> int:
	return maxi(1, int(floor(float(flat_max_hp()) * (1.0 + max_hp_mult))))

func attack() -> int:
	return maxi(0, base_attack + equip_attack + item_attack + level_attack)

func defence() -> int:
	return maxi(0, base_defence + equip_defence + item_defence + level_defence)

func flat_speed() -> float:
	return base_speed + equip_speed + item_speed + level_speed

func speed() -> float:
	return maxf(0.1, flat_speed() * (1.0 + speed_mult))

## Format: ATK = 9 (5 + [2] + {1} + <1>)
static func format_stat(label: String, total: float, base: float, equip: float, item: float,
		level_bonus: float = 0.0, as_int: bool = true) -> String:
	if as_int:
		return "%s = %d (%d + [%d] + {%d} + <%d>)" % [
			label, int(total), int(base), int(equip), int(item), int(level_bonus)]
	return "%s = %.0f (%.0f + [%.0f] + {%.0f} + <%.0f>)" % [
		label, total, base, equip, item, level_bonus]

func format_attack() -> String:
	return format_stat("ATK", attack(), base_attack, equip_attack, item_attack, level_attack)

func format_defence() -> String:
	return format_stat("DEF", defence(), base_defence, equip_defence, item_defence, level_defence)

func format_speed() -> String:
	var base_txt := format_stat("SPD", flat_speed(), base_speed, equip_speed, item_speed, level_speed, false)
	if is_zero_approx(speed_mult):
		return base_txt
	return "%s ×%.2f = %.0f" % [base_txt, 1.0 + speed_mult, speed()]

func format_max_hp() -> String:
	var base_txt := format_stat("MAX HP", flat_max_hp(), base_max_hp, equip_max_hp, item_max_hp, level_max_hp)
	if is_zero_approx(max_hp_mult):
		return base_txt
	return "%s ×%.2f = %d" % [base_txt, 1.0 + max_hp_mult, max_hp()]
