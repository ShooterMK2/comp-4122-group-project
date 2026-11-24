class_name ImportantDefinition
extends ItemDefinition

@export var usable: bool = false
@export var consumed_on_use: bool = true
@export var use_effect: UseEffect.Kind = UseEffect.Kind.NONE
@export var use_amount: int = 0
@export var story_flag: StringName = &""

func category() -> int:
	return ItemCategory.Kind.IMPORTANT
