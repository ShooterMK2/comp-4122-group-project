class_name StarterContent
extends RefCounted

const E := Elements.Element

static func _with_icon(item: ItemDefinition) -> ItemDefinition:
	item.icon = IconLookup.for_item_id(item.id)
	return item

static func starter_rod() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"starter_rod"
	e.display_name = "Starter Rod"
	e.description = "Weapon for beginner"
	e.slot = EquipmentSlot.Kind.WEAPON
	e.bonus_attack = 3
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func starter_robe() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"starter_robe"
	e.display_name = "Starter Robe"
	e.description = "Robe for beginner"
	e.slot = EquipmentSlot.Kind.ARMOUR
	e.bonus_defence = 3
	e.bonus_max_hp = 20
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func starter_shoes() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"starter_shoes"
	e.display_name = "Starter Shoes"
	e.description = "Shoes for beginner"
	e.slot = EquipmentSlot.Kind.ALT_ARMOUR
	e.bonus_speed = 2.0
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func starter_necklace() -> EquipmentDefinition:
	var e := EquipmentDefinition.new()
	e.id = &"starter_necklace"
	e.display_name = "Starter Necklace"
	e.description = "Start with 2 Shield, Slight Defense Boost"
	e.slot = EquipmentSlot.Kind.ACCESSORY
	e.passive = PassiveEffect.Kind.START_SHIELD
	e.passive_amount = 2
	e.passive2 = PassiveEffect.Kind.DAMAGE_RESISTANCE
	e.passive2_amount = 20  # 20% incoming damage reduction (hidden from UI label above)
	e.max_stack = 1
	return _with_icon(e) as EquipmentDefinition

static func healing_potion() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"healing_potion"
	c.display_name = "Healing Potion"
	c.description = "Restore 20 HP Immediately"
	c.use_effect = UseEffect.Kind.HEAL_HP
	c.use_amount = RunConfig.HEALING_POTION_HEAL
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func protective_ring() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"protective_ring"
	c.display_name = "Protective Ring"
	c.description = "Next Battle: +2 Shields"
	c.use_effect = UseEffect.Kind.START_SHIELD
	c.use_amount = 2
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func fire_booster() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"fire_booster"
	c.display_name = "Fire Booster"
	c.description = "Next Battle: Slight Boost to Fire Damage"
	c.use_effect = UseEffect.Kind.FIRE_SPELL_DAMAGE
	c.use_amount = 20  # +20%
	c.max_stack = 99
	return _with_icon(c) as ConsumableDefinition

static func pieces_of_hp() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"pieces_of_hp"
	c.display_name = "Pieces of HP"
	c.description = "+10 HP permanently"
	c.use_effect = UseEffect.Kind.PERM_MAX_HP
	c.use_amount = RunConfig.PIECES_OF_HP_BONUS
	c.max_stack = 1
	return _with_icon(c) as ConsumableDefinition

static func pieces_of_atk() -> ConsumableDefinition:
	var c := ConsumableDefinition.new()
	c.id = &"pieces_of_atk"
	c.display_name = "Pieces of ATK"
	c.description = "+1 ATK permanently"
	c.use_effect = UseEffect.Kind.PERM_ATK
	c.use_amount = RunConfig.PIECES_OF_ATK_BONUS
	c.max_stack = 1
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

static func shield_of_hero() -> ImportantDefinition:
	var i := ImportantDefinition.new()
	i.id = &"shield_of_hero"
	i.display_name = "Shield of Hero"
	i.description = "+3 Shields in the start of the battle permanently"
	i.usable = true
	i.consumed_on_use = true
	i.use_effect = UseEffect.Kind.PERM_START_SHIELD
	i.use_amount = RunConfig.SHIELD_OF_HERO_BONUS
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
	return [starter_rod(), starter_robe(), starter_shoes(), starter_necklace()]

static func all_consumables() -> Array[ConsumableDefinition]:
	return [healing_potion(), protective_ring(), fire_booster(), pieces_of_hp(), pieces_of_atk()]

static func all_importants() -> Array[ImportantDefinition]:
	return [sealed_letter(), shield_of_hero()]

static func consumable_by_id(id: StringName) -> ConsumableDefinition:
	for c in all_consumables():
		if c.id == id:
			return c
	return null

## Extra fragments only available via level-up rewards (not starter-owned).
static func reward_fragments() -> Array[FragmentDefinition]:
	return [
		_frag(&"reward_solar_arc", "Solar Arc",
			[V(0,0), V(1,0), V(2,0), V(1,1)], [E.FIRE, E.FIRE, E.FIRE, E.UNIVERSAL]),
		_frag(&"reward_tide_coil", "Tide Coil",
			[V(0,0), V(0,1), V(1,1), V(1,2)], [E.ICE, E.ICE, E.ICE, E.WIND]),
	]

## Extra spells only available via level-up rewards.
static func reward_spells() -> Array[SpellDefinition]:
	var out: Array[SpellDefinition] = []
	out.append(SpellDefinition.make(&"reward_spark_lash", "Spark Lash",
		SpellPattern.make([V(0,0), V(1,0), V(1,1)]),
		[ElementRequirement.make(E.LIGHTNING, 3)], 3,
		[SpellEffect.make(SpellEffect.Kind.CONDUCTIVE, 1)]))
	return out
