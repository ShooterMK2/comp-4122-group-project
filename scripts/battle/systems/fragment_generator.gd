class_name FragmentGenerator
extends RefCounted

const SHAPES := [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
]

const PRIMARY_ELEMENT_POOL := [
	Elements.Element.FIRE, Elements.Element.FIRE,
	Elements.Element.ICE, Elements.Element.ICE,
	Elements.Element.EARTH, Elements.Element.EARTH,
	Elements.Element.WIND, Elements.Element.LIGHTNING, Elements.Element.DARK,
]
const PRIMARY_ELEMENT_CHANCE := 0.70
const UNIVERSAL_CHANCE := 0.05
const NONE_CHANCE := 0.02

static func random_fragment() -> FragmentData:
	var cells: Array = SHAPES.pick_random()
	var primary: int = PRIMARY_ELEMENT_POOL.pick_random()
	var elems: Array = []
	for i in cells.size():
		elems.append(_random_element(primary))
	return FragmentData.make(cells, elems)

static func _random_element(primary: int) -> int:
	if randf() < NONE_CHANCE:
		return Elements.Element.NONE
	if randf() < UNIVERSAL_CHANCE:
		return Elements.Element.UNIVERSAL
	if randf() < PRIMARY_ELEMENT_CHANCE:
		return primary
	var secondary: int = PRIMARY_ELEMENT_POOL.pick_random()
	while secondary == primary:
		secondary = PRIMARY_ELEMENT_POOL.pick_random()
	return secondary

static func single_element(element: int) -> FragmentData:
	var cells: Array = SHAPES.pick_random()
	var elems: Array = []
	for i in cells.size():
		elems.append(element)
	return FragmentData.make(cells, elems)

static func draw(count: int) -> Array[FragmentData]:
	var out: Array[FragmentData] = []
	for i in count:
		out.append(random_fragment())
	return out
