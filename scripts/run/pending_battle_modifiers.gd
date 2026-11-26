class_name PendingBattleModifiers
extends RefCounted

var start_shield: int = 0
var temp_max_hp: int = 0
var heal_amount: int = 0
var item_attack: int = 0
var item_defence: int = 0
var item_speed: float = 0.0
## Additive fire spell damage bonus for next battle (0.20 = +20%).
var fire_spell_damage_mult: float = 0.0

func clear() -> void:
	start_shield = 0
	temp_max_hp = 0
	heal_amount = 0
	item_attack = 0
	item_defence = 0
	item_speed = 0.0
	fire_spell_damage_mult = 0.0

func is_empty() -> bool:
	return start_shield == 0 and temp_max_hp == 0 and heal_amount == 0 \
		and item_attack == 0 and item_defence == 0 and is_zero_approx(item_speed) \
		and is_zero_approx(fire_spell_damage_mult)
