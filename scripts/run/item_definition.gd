class_name ItemDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 99
@export var price: int = 0

func category() -> int:
	return ItemCategory.Kind.CONSUMABLE
