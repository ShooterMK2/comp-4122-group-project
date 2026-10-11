class_name SpellPattern
extends Resource

@export var cells: Array[Vector2i] = []   # normalized, min x/y = 0

static func make(p_cells: Array) -> SpellPattern:
	var p := SpellPattern.new()
	for c in p_cells:
		p.cells.append(c)
	return p
