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
	e.description = "A simple casting board focus. +2 ATK."
	e.slot = EquipmentSlot.Kind.WEAPON
	e.bonus_attack = 2
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func travel_cloak() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"travel_cloak"
	e.display_name = "Travel Cloak"
	e.description = "Weathered chest armour. +1 DEF, +10 max HP."
	e.slot = EquipmentSlot.Kind.ARMOUR
	e.bonus_defence = 1
	e.bonus_max_hp = 10
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func leather_greaves() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"leather_greaves"
	e.display_name = "Leather Greaves"
	e.description = "Light leg protection. +1 SPD."
	e.slot = EquipmentSlot.Kind.ALT_ARMOUR
	e.bonus_speed = 1.0
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func copper_ring() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"copper_ring"
	e.display_name = "Copper Ring"
	e.description = "A trinket that wards the first blow. Start battle with 1 Shield."
	e.slot = EquipmentSlot.Kind.ACCESSORY
	e.passive = PassiveEffect.Kind.START_SHIELD
	e.passive_amount = 1
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func minor_tonic() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"minor_tonic"
	c.display_name = "Minor Tonic"
	c.description = "Restore 20 HP before battle."
	c.use_effect = UseEffect.Kind.HEAL_HP
	c.use_amount = RunConfig.MINOR_TONIC_HEAL
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func warding_charm() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"warding_charm"
	c.display_name = "Warding Charm"
	c.description = "Start the next battle with +1 Shield."
	c.use_effect = UseEffect.Kind.START_SHIELD
	c.use_amount = 1
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func sealed_letter() -> ImportantDefinition:
	var i := ImportantDefinition.new()
	i.id = &"sealed_letter"
	i.display_name = "Sealed Letter"
	i.description = "A story letter. Cannot be used."
	i.usable = false
	i.story_flag = &"has_sealed_letter"
	i.max_stack = 1
	return _with_icon(i) as ImportantDefinition

static func blessed_sigil() -> ImportantDefinition:
	var i := ImportantDefinition.new()
	i.id = &"blessed_sigil"
	i.display_name = "Blessed Sigil"
	i.description = "Before battle: +10 max HP this fight."
	i.usable = true
	i.consumed_on_use = true
	i.use_effect = UseEffect.Kind.TEMP_MAX_HP
	i.use_amount = RunConfig.BLESSED_SIGIL_MAX_HP_BONUS
	i.max_stack = 1
	return _with_icon(i) as ImportantDefinition

static func V(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)

static func _frag(id: StringName, name: String, cells: Array, elements: Array,
		desc: String) -> FragmentDefinition:
	var f := FragmentDefinition.new()
	f.id = id
	f.display_name = name
	f.description = desc
	f.fragment = FragmentData.make(cells, elements)
	f.icon = IconLookup.fragment()
	return f

static func fragments() -> Array[FragmentDefinition]:
	var out: Array[FragmentDefinition] = []
	out.append(_frag(&"fire_line_3", "Fire Line",
		[V(0,0), V(1,0), V(2,0)], [E.FIRE, E.FIRE, E.FIRE],
		"3-tile fire line. Matches Ember alone."))
	out.append(_frag(&"ice_corner_3", "Ice Corner",
		[V(0,0), V(0,1), V(1,1)], [E.ICE, E.ICE, E.ICE],
		"Ice corner. Matches Chill Touch alone."))
	out.append(_frag(&"earth_block_3", "Earth Block",
		[V(0,0), V(1,0), V(0,1)], [E.EARTH, E.EARTH, E.EARTH],
		"Earth block. Matches Stone Crash alone."))
	out.append(_frag(&"wind_hook_3", "Wind Hook",
		[V(0,0), V(1,0), V(0,1)], [E.WIND, E.WIND, E.WIND],
		"Wind hook. Matches Gust alone."))
	out.append(_frag(&"spark_hook_3", "Spark Hook",
		[V(0,0), V(1,0), V(1,1)], [E.LIGHTNING, E.LIGHTNING, E.LIGHTNING],
		"Lightning hook. Matches Spark alone."))
	out.append(_frag(&"dark_pillar_3", "Dark Pillar",
		[V(0,0), V(0,1), V(0,2)], [E.DARK, E.DARK, E.DARK],
		"Dark pillar. Matches Wither alone."))
	out.append(_frag(&"fire_mix_a", "Ember Wing A",
		[V(0,0), V(1,0), V(2,0)], [E.FIRE, E.FIRE, E.FIRE],
		"Combines toward Blazing Nova."))
	out.append(_frag(&"fire_mix_b", "Ember Wing B",
		[V(0,0), V(1,0)], [E.FIRE, E.FIRE],
		"Pairs with Ember Wing A for Blazing Nova."))
	out.append(_frag(&"ice_mix_a", "Frost Stem",
		[V(0,0), V(1,0), V(2,0)], [E.ICE, E.ICE, E.ICE],
		"Combines toward Frost Nova."))
	out.append(_frag(&"ice_mix_b", "Frost Tail",
		[V(0,0), V(0,1)], [E.ICE, E.ICE],
		"Pairs with Frost Stem for Frost Nova."))
	out.append(_frag(&"flex_universal", "Universal Flex",
		[V(0,0), V(1,0), V(0,1)], [E.UNIVERSAL, E.UNIVERSAL, E.UNIVERSAL],
		"Universal tiles for flexible requirements."))
	out.append(_frag(&"flex_duel", "Duel Spark",
		[V(0,0), V(1,0)], [E.FIRE, E.ICE],
		"Two-tile dual-element placement test."))
	return out

static func all_equipment() -> Array[EquipmentDefinition]:
	return [wooden_rod(), travel_cloak(), leather_greaves(), copper_ring()]

static func all_consumables() -> Array[ConsumableDefinition]:
	return [minor_tonic(), warding_charm()]

static func all_importants() -> Array[ImportantDefinition]:
	return [sealed_letter(), blessed_sigil()]
