class_name EquipmentSlot
extends RefCounted

enum Kind { WEAPON, ARMOUR, ALT_ARMOUR, ACCESSORY }

static func display_name(slot: int) -> String:
	match slot:
		Kind.WEAPON:
			return "Weapon"
		Kind.ARMOUR:
			return "Armour"
		Kind.ALT_ARMOUR:
			return "Alt Armour"
		Kind.ACCESSORY:
			return "Accessory"
		_:
			return "Unknown"
