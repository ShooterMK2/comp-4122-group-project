class_name EquipmentDefinition
extends ItemDefinition

@export var slot: EquipmentSlot.Kind = EquipmentSlot.Kind.WEAPON
@export var bonus_max_hp: int = 0
@export var bonus_attack: int = 0
@export var bonus_defence: int = 0
@export var bonus_speed: float = 0.0
@export var passive: PassiveEffect.Kind = PassiveEffect.Kind.NONE
@export var passive_amount: int = 0

func category() -> int:
	return ItemCategory.Kind.EQUIPMENT
