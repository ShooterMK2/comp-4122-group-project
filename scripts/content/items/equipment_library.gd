class_name EquipmentLibrary
extends RefCounted

const E := Elements.Element

static func _with_icon(item: ItemDefinition) -> ItemDefinition:
	item.icon = IconLookup.for_item_id(item.id)
	return item

static func _equip(id: StringName, name: String, desc: String, slot: int) -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = id
	e.display_name = name
	e.description = desc
	e.slot = slot
	e.max_stack = 1
	return e

static func iron_rod() -> EquipmentDefinition:
	var e := _equip(&"iron_rod", "Iron Rod", "Rod made of Iron", EquipmentSlot.Kind.WEAPON)
	e.bonus_attack = 7
	return _with_icon(e) as EquipmentDefinition

static func duo_staff() -> EquipmentDefinition:
	var e := _equip(&"duo_staff", "Duo Staff",
		"Staff carry both fire and ice conflicting element", EquipmentSlot.Kind.WEAPON)
	e.bonus_attack = 10
	e.element_damage_bonuses = {E.FIRE: 0.20, E.ICE: 0.20}
	return _with_icon(e) as EquipmentDefinition

static func nature_staff() -> EquipmentDefinition:
	var e := _equip(&"nature_staff", "Nature Staff",
		"Staff represent the pure, simple environment", EquipmentSlot.Kind.WEAPON)
	e.bonus_attack = 9
	e.bonus_defence = 1
	e.bonus_speed = 1.0
	e.element_damage_bonuses = {E.WIND: 0.20, E.EARTH: 0.20}
	return _with_icon(e) as EquipmentDefinition

static func shock_point() -> EquipmentDefinition:
	var e := _equip(&"shock_point", "Shock Point", "Banish the darkness", EquipmentSlot.Kind.WEAPON)
	e.bonus_attack = 9
	e.element_damage_bonuses = {E.LIGHTNING: 0.45, E.DARK: -0.20}
	return _with_icon(e) as EquipmentDefinition

static func blood_stick() -> EquipmentDefinition:
	var e := _equip(&"blood_stick", "Blood Stick",
		"Sacrifice for greater power", EquipmentSlot.Kind.WEAPON)
	e.bonus_attack = 12
	e.element_damage_bonuses = {E.DARK: 0.20}
	e.max_hp_mult = -0.10
	return _with_icon(e) as EquipmentDefinition

static func iron_plate() -> EquipmentDefinition:
	var e := _equip(&"iron_plate", "Iron Plate", "Armour made of Iron", EquipmentSlot.Kind.ARMOUR)
	e.bonus_defence = 9
	return _with_icon(e) as EquipmentDefinition

static func stable_chestcover() -> EquipmentDefinition:
	var e := _equip(&"stable_chestcover", "Stable Chestcover",
		"Provide solid defense", EquipmentSlot.Kind.ARMOUR)
	e.bonus_defence = 12
	return _with_icon(e) as EquipmentDefinition

static func heavy_armour() -> EquipmentDefinition:
	var e := _equip(&"heavy_armour", "Heavy Armour",
		"Provide higher defense, in trade-off some speed", EquipmentSlot.Kind.ARMOUR)
	e.bonus_defence = 15
	e.bonus_speed = -2.0
	return _with_icon(e) as EquipmentDefinition

static func fittest_top() -> EquipmentDefinition:
	var e := _equip(&"fittest_top", "Fittest Top",
		"Provide the all rounder boost", EquipmentSlot.Kind.ARMOUR)
	e.bonus_defence = 10
	e.bonus_attack = 1
	e.bonus_speed = 1.0
	return _with_icon(e) as EquipmentDefinition

static func speed_shirt() -> EquipmentDefinition:
	var e := _equip(&"speed_shirt", "Speed Shirt",
		"Provide huge speed boost", EquipmentSlot.Kind.ARMOUR)
	e.bonus_defence = 7
	e.bonus_speed = 3.0
	return _with_icon(e) as EquipmentDefinition

static func iron_gauntlet() -> EquipmentDefinition:
	var e := _equip(&"iron_gauntlet", "Iron Gauntlet",
		"Gauntlet made of Iron", EquipmentSlot.Kind.ALT_ARMOUR)
	e.bonus_defence = 5
	return _with_icon(e) as EquipmentDefinition

static func adventurers_helmet() -> EquipmentDefinition:
	var e := _equip(&"adventurers_helmet", "Adventurer's Helmet",
		"To those seek for challenge", EquipmentSlot.Kind.ALT_ARMOUR)
	e.bonus_defence = 8
	e.bonus_attack = 1
	e.bonus_speed = 1.0
	e.passive = PassiveEffect.Kind.START_SHIELD
	e.passive_amount = 1
	return _with_icon(e) as EquipmentDefinition

static func bandits_leggings() -> EquipmentDefinition:
	var e := _equip(&"bandits_leggings", "Bandit's Leggings",
		"To those seek for peace", EquipmentSlot.Kind.ALT_ARMOUR)
	e.bonus_defence = 5
	e.bonus_speed = 3.0
	e.start_stat_buff = EquipmentDefinition.START_BUFF_SPD
	return _with_icon(e) as EquipmentDefinition

static func knights_shields() -> EquipmentDefinition:
	var e := _equip(&"knights_shields", "Knight's Shields",
		"To those seek for protection", EquipmentSlot.Kind.ALT_ARMOUR)
	e.bonus_defence = 9
	e.start_stat_buff = EquipmentDefinition.START_BUFF_DEF
	return _with_icon(e) as EquipmentDefinition

static func hunters_gloves() -> EquipmentDefinition:
	var e := _equip(&"hunters_gloves", "Hunter's Gloves",
		"To those seek for skill", EquipmentSlot.Kind.ALT_ARMOUR)
	e.bonus_defence = 8
	e.bonus_attack = 2
	e.start_stat_buff = EquipmentDefinition.START_BUFF_ATK
	return _with_icon(e) as EquipmentDefinition

static func merchants_glasses() -> EquipmentDefinition:
	var e := _equip(&"merchants_glasses", "Merchant's Glasses",
		"To those seek for joy", EquipmentSlot.Kind.ACCESSORY)
	e.bonus_attack = 1
	e.bonus_defence = 1
	e.bonus_speed = 1.0
	e.start_stat_buff = EquipmentDefinition.START_BUFF_RANDOM
	return _with_icon(e) as EquipmentDefinition

static func dancers_mask() -> EquipmentDefinition:
	var e := _equip(&"dancers_mask", "Dancer's Mask",
		"To those seek for valour", EquipmentSlot.Kind.ACCESSORY)
	e.bonus_speed = 2.0
	e.speed_mult = 0.20
	return _with_icon(e) as EquipmentDefinition

static func pupils_note() -> EquipmentDefinition:
	var e := _equip(&"pupils_note", "Pupil's Note",
		"To those seek for vision", EquipmentSlot.Kind.ACCESSORY)
	e.bonus_attack = 1
	e.damage_dealt_bonus = 0.20
	return _with_icon(e) as EquipmentDefinition

static func priests_necklace() -> EquipmentDefinition:
	var e := _equip(&"priests_necklace", "Priest's Necklace",
		"To those seek for judgement", EquipmentSlot.Kind.ACCESSORY)
	e.bonus_defence = 1
	e.passive = PassiveEffect.Kind.DAMAGE_RESISTANCE
	e.passive_amount = 20
	return _with_icon(e) as EquipmentDefinition

static func all() -> Array[EquipmentDefinition]:
	return [
		iron_rod(), duo_staff(), nature_staff(), shock_point(), blood_stick(),
		iron_plate(), stable_chestcover(), heavy_armour(), fittest_top(), speed_shirt(),
		iron_gauntlet(), adventurers_helmet(), bandits_leggings(), knights_shields(),
		hunters_gloves(), merchants_glasses(), dancers_mask(), pupils_note(),
		priests_necklace(),
	]

static func by_id(id: StringName) -> EquipmentDefinition:
	for eq in all():
		if eq.id == id:
			return eq
	return null
