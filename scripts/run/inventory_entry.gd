class_name InventoryEntry
extends RefCounted

var id: StringName
var category: int = ItemCategory.Kind.CONSUMABLE
var quantity: int = 1
var ref: Resource  # ItemDefinition | FragmentDefinition | SpellDefinition
var acquired_at: int = 0  # higher = obtained more recently

func _init(p_id: StringName = &"", p_category: int = ItemCategory.Kind.CONSUMABLE,
		p_qty: int = 1, p_ref: Resource = null, p_acquired_at: int = 0) -> void:
	id = p_id
	category = p_category
	quantity = p_qty
	ref = p_ref
	acquired_at = p_acquired_at

func display_name() -> String:
	if ref == null:
		return String(id)
	if ref is ItemDefinition:
		return (ref as ItemDefinition).display_name
	if ref is FragmentDefinition:
		return (ref as FragmentDefinition).display_name
	if ref is SpellDefinition:
		return (ref as SpellDefinition).display_name
	if ref is UltimateDefinition:
		return (ref as UltimateDefinition).display_name
	return String(id)

func description() -> String:
	if ref is ItemDefinition:
		return (ref as ItemDefinition).description
	if ref is FragmentDefinition:
		var frag_def := ref as FragmentDefinition
		var shape := ""
		if frag_def.fragment != null:
			shape = frag_def.fragment.preview_text()
		var blurb := frag_def.description.strip_edges()
		if blurb.is_empty():
			return shape
		if shape.is_empty():
			return blurb
		return "%s\n%s" % [blurb, shape]
	if ref is SpellDefinition:
		return (ref as SpellDefinition).inventory_preview_text()
	if ref is UltimateDefinition:
		return (ref as UltimateDefinition).inventory_preview_text()
	return ""

func icon() -> Texture2D:
	if ref is ItemDefinition:
		return (ref as ItemDefinition).icon
	if ref is FragmentDefinition:
		return (ref as FragmentDefinition).icon
	if ref is UltimateDefinition:
		return (ref as UltimateDefinition).icon
	return null
