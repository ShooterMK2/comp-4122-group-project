class_name EquipmentDefinition
extends ItemDefinition

## start_stat_buff: -1 none, 0 ATK, 1 DEF, 2 SPD, -2 random one of ATK/DEF/SPD.
const START_BUFF_NONE := -1
const START_BUFF_ATK := 0
const START_BUFF_DEF := 1
const START_BUFF_SPD := 2
const START_BUFF_RANDOM := -2

@export var slot: EquipmentSlot.Kind = EquipmentSlot.Kind.WEAPON
@export var bonus_max_hp: int = 0
@export var bonus_attack: int = 0
@export var bonus_defence: int = 0
@export var bonus_speed: float = 0.0
@export var passive: PassiveEffect.Kind = PassiveEffect.Kind.NONE
@export var passive_amount: int = 0
@export var passive2: PassiveEffect.Kind = PassiveEffect.Kind.NONE
@export var passive2_amount: int = 0
## Element int -> additive spell damage (0.20 = +20%, can be negative).
@export var element_damage_bonuses: Dictionary = {}
## Applied to final flat max HP sum (e.g. -0.10 => ×0.9).
@export var max_hp_mult: float = 0.0
## Applied to final flat speed sum (e.g. 0.20 => ×1.2).
@export var speed_mult: float = 0.0
## Outgoing damage bonus while equipped (0.20 = +20%).
@export var damage_dealt_bonus: float = 0.0
@export var start_stat_buff: int = START_BUFF_NONE

func category() -> int:
	return ItemCategory.Kind.EQUIPMENT
