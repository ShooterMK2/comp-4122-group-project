class_name FragmentDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var fragment: FragmentData

func category() -> int:
	return ItemCategory.Kind.FRAGMENT

func make_fragment() -> FragmentData:
	if fragment == null:
		return FragmentData.new()
	return FragmentData.make(fragment.cells.duplicate(), fragment.elements.duplicate())
