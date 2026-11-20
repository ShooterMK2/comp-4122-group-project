class_name StarterContent
extends RefCounted

const E := Elements.Element

static func _with_icon(item: ItemDefinition) -> ItemDefinition:
	item.icon = IconLookup.for_item_id(item.id)
	return item

static func wooden_rod() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"wooden_rod"
	e.display_name = "Wooden Rod"
	e.description = "Casting focus."
	e.slot = EquipmentSlot.Kind.WEAPON
	e.bonus_attack = 2
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func travel_cloak() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"travel_cloak"
	e.display_name = "Travel Cloak"
	e.description = "Chest armour."
	e.slot = EquipmentSlot.Kind.ARMOUR
	e.bonus_defence = 1
	e.bonus_max_hp = 10
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func leather_greaves() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"leather_greaves"
	e.display_name = "Leather Greaves"
	e.description = "Leg protection."
	e.slot = EquipmentSlot.Kind.ALT_ARMOUR
	e.bonus_speed = 1.0
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func copper_ring() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"copper_ring"
	e.display_name = "Copper Ring"
	e.description = "Wards the first blow."
	e.slot = EquipmentSlot.Kind.ACCESSORY
	e.passive = PassiveEffect.Kind.START_SHIELD
	e.passive_amount = 1
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func minor_tonic() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"minor_tonic"
	c.display_name = "Minor Tonic"
	c.description = "Restore 20 HP."
	c.use_effect = UseEffect.Kind.HEAL_HP
	c.use_amount = RunConfig.MINOR_TONIC_HEAL
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func warding_charm() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"warding_charm"
	c.display_name = "Warding Charm"
	c.description = "+1 Shield next battle."
	c.use_effect = UseEffect.Kind.START_SHIELD
	c.use_amount = 1
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func sealed_letter() -> ImportantDefinition:
	var i := ImportantDefinition.new()
	i.id = &"sealed_letter"
	i.display_name = "Sealed Letter"
	i.description = "A story letter."
	i.usable = false
	i.story_flag = &"has_sealed_letter"
	i.max_stack = 1
	return _with_icon(i) as ImportantDefinition

static func blessed_sigil() -> ImportantDefinition:
	var i := ImportantDefinition.new()
	i.id = &"blessed_sigil"
	i.display_name = "Blessed Sigil"
	i.description = "+10 max HP next battle."
	i.usable = true
	i.consumed_on_use = true
	i.use_effect = UseEffect.Kind.TEMP_MAX_HP
	i.use_amount = RunConfig.BLESSED_SIGIL_MAX_HP_BONUS
	i.max_stack = 1
	return _with_icon(i) as ImportantDefinition

static func V(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)

static func _frag(id: StringName, name: String, cells: Array, elements: Array) -> FragmentDefinition:
	var f := FragmentDefinition.new()
	f.id = id
	f.display_name = name
	f.description = ""
	f.fragment = FragmentData.make(cells, elements)
	f.icon = IconLookup.fragment()
	return f

static func fragments() -> Array[FragmentDefinition]:
	var out: Array[FragmentDefinition] = []
	out.append(_frag(&"fire_line_3", "Fire Line",
		[V(0,0), V(1,0), V(2,0)], [E.FIRE, E.FIRE, E.FIRE]))
	out.append(_frag(&"ice_corner_3", "Ice Corner",
		[V(0,0), V(0,1), V(1,1)], [E.ICE, E.ICE, E.ICE]))
	out.append(_frag(&"earth_block_3", "Earth Block",
		[V(0,0), V(1,0), V(0,1)], [E.EARTH, E.EARTH, E.EARTH]))
	out.append(_frag(&"wind_hook_3", "Wind Hook",
		[V(0,0), V(1,0), V(0,1)], [E.WIND, E.WIND, E.WIND]))
	out.append(_frag(&"spark_hook_3", "Spark Hook",
		[V(0,0), V(1,0), V(1,1)], [E.LIGHTNING, E.LIGHTNING, E.LIGHTNING]))
	out.append(_frag(&"dark_pillar_3", "Dark Pillar",
		[V(0,0), V(0,1), V(0,2)], [E.DARK, E.DARK, E.DARK]))
	out.append(_frag(&"fire_mix_a", "Ember Wing A",
		[V(0,0), V(1,0), V(2,0)], [E.FIRE, E.FIRE, E.FIRE]))
	out.append(_frag(&"fire_mix_b", "Ember Wing B",
		[V(0,0), V(1,0)], [E.FIRE, E.FIRE]))
	out.append(_frag(&"ice_mix_a", "Frost Stem",
		[V(0,0), V(1,0), V(2,0)], [E.ICE, E.ICE, E.ICE]))
	out.append(_frag(&"ice_mix_b", "Frost Tail",
		[V(0,0), V(0,1)], [E.ICE, E.ICE]))
	out.append(_frag(&"flex_universal", "Universal Flex",
		[V(0,0), V(1,0), V(0,1)], [E.UNIVERSAL, E.UNIVERSAL, E.UNIVERSAL]))
	out.append(_frag(&"flex_duel", "Duel Spark",
		[V(0,0), V(1,0)], [E.FIRE, E.ICE]))
	return out

static func all_equipment() -> Array[EquipmentDefinition]:
	return [wooden_rod(), travel_cloak(), leather_greaves(), copper_ring()]

static func all_consumables() -> Array[ConsumableDefinition]:
	return [minor_tonic(), warding_charm()]

static func all_importants() -> Array[ImportantDefinition]:
	return [sealed_letter(), blessed_sigil()]
