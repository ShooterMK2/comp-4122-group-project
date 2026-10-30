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

const POOL := [
	Elements.Element.FIRE, Elements.Element.FIRE,
	Elements.Element.ICE, Elements.Element.ICE,
	Elements.Element.EARTH, Elements.Element.EARTH,
	Elements.Element.WIND, Elements.Element.LIGHTNING, Elements.Element.DARK,
	Elements.Element.UNIVERSAL, Elements.Element.NONE,
]

static func random_fragment() -> FragmentData:
	var cells: Array = SHAPES.pick_random()
	var elems: Array = []
	for i in cells.size():
		elems.append(POOL.pick_random())
	return FragmentData.make(cells, elems)

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
