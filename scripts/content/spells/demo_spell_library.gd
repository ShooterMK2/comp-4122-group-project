class_name DemoSpellLibrary
extends RefCounted

const E := Elements.Element
const K := SpellEffect.Kind

static func _fx(k: SpellEffect.Kind, n: int = 1, n2: int = 0) -> SpellEffect:
	return SpellEffect.make(k, n, n2)

static func _spell(id: StringName, nm: String, cells: Array, element: int,
		min_count: int, dmg: int, effects: Array) -> SpellDefinition:
	return SpellDefinition.make(id, nm, SpellPattern.make(cells),
		[ElementRequirement.make(element, min_count)], dmg, effects)

static func V(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)

# Numbers here (base damage, stacks, costs) are per-spell balance values.
static func build() -> Array[SpellDefinition]:
	var s: Array[SpellDefinition] = []
	# Fire
	s.append(_spell(&"ember", "Ember", [V(0,0), V(1,0), V(2,0)], E.FIRE, 2, 3, [_fx(K.BURN, 3)]))
	s.append(_spell(&"blazing_nova", "Blazing Nova", [V(0,0), V(1,0), V(2,0), V(1,1)], E.FIRE, 3, 2,
		[_fx(K.DETONATE, 4)]))
	s.append(_spell(&"hellfire", "Hellfire", [V(1,0), V(0,1), V(1,1), V(2,1), V(1,2)], E.FIRE, 4, 10,
		[_fx(K.BURN, 4), _fx(K.SELF_BURN, 3)]))
	# Ice
	s.append(_spell(&"chill_touch", "Chill Touch", [V(0,0), V(0,1)], E.ICE, 2, 1, [_fx(K.CHILL, 2)]))
	s.append(_spell(&"frost_nova", "Frost Nova", [V(0,0), V(1,0), V(0,1), V(1,1)], E.ICE, 3, 2,
		[_fx(K.CHILL, 2)]))
	# Earth
	s.append(_spell(&"fortify", "Fortify", [V(0,0), V(0,1), V(0,2), V(1,2)], E.EARTH, 2, 0,
		[_fx(K.FORTIFY, 10)]))
	s.append(_spell(&"smite", "Smite", [V(0,0), V(0,1), V(0,2)], E.EARTH, 3, 3,
		[_fx(K.SMITE, 8, 2)]))   # spend 8 Shield, +2 dmg per point
	# Wind
	s.append(_spell(&"gust", "Gust", [V(0,0), V(1,0)], E.WIND, 2, 2, [_fx(K.TAILWIND, 2)]))
	# Lightning
	s.append(_spell(&"chain_bolt", "Chain Bolt", [V(0,0), V(1,0), V(1,1), V(2,1)], E.LIGHTNING, 2, 4,
		[_fx(K.CONDUCTIVE, 2), _fx(K.OVERLOAD, 2, 1)]))
	s.append(_spell(&"spark", "Spark", [V(1,0), V(1,1), V(1,2), V(0,2)], E.LIGHTNING, 2, 3,
		[_fx(K.CONDUCTIVE, 1)]))
	# Dark
	s.append(_spell(&"wither", "Wither", [V(0,0), V(0,1), V(0,2), V(0,3)], E.DARK, 2, 1, [_fx(K.DECAY, 2)]))
	s.append(_spell(&"plague", "Plague", [V(0,0), V(1,0), V(0,1), V(1,1), V(2,0)], E.DARK, 3, 2,
		[_fx(K.DECAY, 3)]))
	return s
