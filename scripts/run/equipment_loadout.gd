class_name EquipmentLoadout
extends RefCounted

var slots: Dictionary = {}  # EquipmentSlot.Kind -> EquipmentDefinition

func get_equipped(slot: int) -> EquipmentDefinition:
	return slots.get(slot, null) as EquipmentDefinition

func equip(item: EquipmentDefinition) -> EquipmentDefinition:
	var previous: EquipmentDefinition = get_equipped(item.slot)
	slots[item.slot] = item
	return previous

func unequip(slot: int) -> EquipmentDefinition:
	var previous: EquipmentDefinition = get_equipped(slot)
	slots.erase(slot)
	return previous

func all_equipped() -> Array[EquipmentDefinition]:
	var out: Array[EquipmentDefinition] = []
	for slot in [EquipmentSlot.Kind.WEAPON, EquipmentSlot.Kind.ARMOUR,
			EquipmentSlot.Kind.ALT_ARMOUR, EquipmentSlot.Kind.ACCESSORY]:
		var item: EquipmentDefinition = get_equipped(slot)
		if item != null:
			out.append(item)
	return out
