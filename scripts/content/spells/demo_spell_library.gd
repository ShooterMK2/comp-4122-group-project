class_name DemoSpellLibrary
extends RefCounted

const E := Elements.Element
const K := SpellEffect.Kind

static func _fx(k: SpellEffect.Kind, n: int = 1, n2: int = 0) -> SpellEffect:
	return SpellEffect.make(k, n, n2)

static func _spell(id: StringName, nm: String, cells: Array, element: int,
		min_count: int, effects: Array) -> SpellDefinition:
	return SpellDefinition.make(id, nm, SpellPattern.make(cells),
		[ElementRequirement.make(element, min_count)], min_count, effects)

static func V(x: int, y: int) -> Vector2i:
	return Vector2i(x, y)

# Each level uses its tile count as base damage: 3, 5, or 8.
static func build() -> Array[SpellDefinition]:
	var s: Array[SpellDefinition] = []
	# Fire
	s.append(_spell(&"ember", "Ember", [V(0,0), V(1,0), V(2,0)], E.FIRE, 3, [_fx(K.BURN, 2)]))
	s.append(_spell(&"blazing_nova", "Blazing Nova", [V(0,0), V(1,0), V(2,0), V(0,1), V(1,1)], E.FIRE, 5,
		[_fx(K.BURN, 3)]))
	s.append(_spell(&"hellfire", "Hellfire", [V(0,0), V(1,0), V(2,0), V(0,1), V(1,1), V(2,1), V(1,2), V(1,3)], E.FIRE, 8,
		[_fx(K.BURN, 4), _fx(K.SELF_BURN, 2)]))
	# Ice
	s.append(_spell(&"chill_touch", "Chill Touch", [V(0,0), V(0,1), V(1,1)], E.ICE, 3, [_fx(K.CHILL, 1)]))
	s.append(_spell(&"frost_nova", "Frost Nova", [V(0,0), V(1,0), V(2,0), V(1,1), V(1,2)], E.ICE, 5,
		[_fx(K.CHILL, 2)]))
	s.append(_spell(&"absolute_zero", "Absolute Zero", [V(1,0), V(0,1), V(1,1), V(2,1), V(1,2), V(0,3), V(1,3), V(2,3)], E.ICE, 8,
		[_fx(K.CHILL, 3)]))
	# Earth
	s.append(_spell(&"stone_crash", "Stone Crash", [V(0,0), V(1,0), V(0,1)], E.EARTH, 3, [_fx(K.FORTIFY, 4)]))
	s.append(_spell(&"smite", "Smite", [V(0,0), V(0,1), V(0,2), V(1,2), V(2,2)], E.EARTH, 5,
		[_fx(K.SMITE, 4, 2)]))
	s.append(_spell(&"tectonic_break", "Tectonic Break", [V(0,0), V(0,1), V(0,2), V(1,2), V(2,2), V(2,1), V(2,0), V(1,3)], E.EARTH, 8,
		[_fx(K.FORTIFY, 10)]))
	# Wind
	s.append(_spell(&"gust", "Gust", [V(0,0), V(1,0), V(0,1)], E.WIND, 3, [_fx(K.TAILWIND, 1)]))
	s.append(_spell(&"crosswind", "Crosswind", [V(1,0), V(0,1), V(1,1), V(2,1), V(1,2)], E.WIND, 5,
		[_fx(K.TAILWIND, 2)]))
	s.append(_spell(&"tempest", "Tempest", [V(0,0), V(1,0), V(1,1), V(2,1), V(2,2), V(3,2), V(3,3), V(2,3)], E.WIND, 8,
		[_fx(K.TAILWIND, 3)]))
	# Lightning
	s.append(_spell(&"spark", "Spark", [V(0,0), V(1,0), V(1,1)], E.LIGHTNING, 3, [_fx(K.CONDUCTIVE, 1)]))
	s.append(_spell(&"chain_bolt", "Chain Bolt", [V(0,0), V(1,0), V(1,1), V(2,1), V(2,2)], E.LIGHTNING, 5,
		[_fx(K.CONDUCTIVE, 2), _fx(K.OVERLOAD, 1, 1)]))
	s.append(_spell(&"thunderhead", "Thunderhead", [V(0,0), V(1,0), V(2,0), V(2,1), V(2,2), V(1,2), V(0,2), V(0,3)], E.LIGHTNING, 8,
		[_fx(K.CONDUCTIVE, 3)]))
	# Dark
	s.append(_spell(&"wither", "Wither", [V(0,0), V(0,1), V(0,2)], E.DARK, 3, [_fx(K.DECAY, 1)]))
	s.append(_spell(&"plague", "Plague", [V(0,0), V(1,0), V(0,1), V(1,1), V(2,0)], E.DARK, 5,
		[_fx(K.DECAY, 2)]))
	s.append(_spell(&"eclipse", "Eclipse", [V(0,0), V(1,0), V(2,0), V(0,1), V(2,1), V(0,2), V(1,2), V(2,2)], E.DARK, 8,
		[_fx(K.DECAY, 3)]))
	return s
