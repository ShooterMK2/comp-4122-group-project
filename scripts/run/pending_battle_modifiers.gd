class_name PendingBattleModifiers
extends RefCounted

var start_shield: int = 0
var temp_max_hp: int = 0
var heal_amount: int = 0
var item_attack: int = 0
var item_defence: int = 0
var item_speed: float = 0.0
## Element int -> additive spell damage bonus for next battle (0.20 = +20%).
var element_spell_damage_mult: Dictionary = {}

func clear() -> void:
	start_shield = 0
	temp_max_hp = 0
	heal_amount = 0
	item_attack = 0
	item_defence = 0
	item_speed = 0.0
	element_spell_damage_mult.clear()

func add_element_bonus(element: int, amount: float) -> void:
	if is_zero_approx(amount):
		return
	element_spell_damage_mult[element] = float(element_spell_damage_mult.get(element, 0.0)) + amount

func is_empty() -> bool:
	return start_shield == 0 and temp_max_hp == 0 and heal_amount == 0 \
		and item_attack == 0 and item_defence == 0 and is_zero_approx(item_speed) \
		and element_spell_damage_mult.is_empty()
