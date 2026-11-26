class_name ConsumableDefinition
extends ItemDefinition

@export var use_effect: UseEffect.Kind = UseEffect.Kind.NONE
@export var use_amount: int = 0
## Used with ELEMENT_SPELL_DAMAGE (Elements.Element).
@export var use_element: int = Elements.Element.NONE

func category() -> int:
	return ItemCategory.Kind.CONSUMABLE
