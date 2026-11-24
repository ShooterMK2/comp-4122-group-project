class_name ConsumableDefinition
extends ItemDefinition

@export var use_effect: UseEffect.Kind = UseEffect.Kind.NONE
@export var use_amount: int = 0

func category() -> int:
	return ItemCategory.Kind.CONSUMABLE
