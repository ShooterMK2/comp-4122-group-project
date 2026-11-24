class_name SpellPattern
extends Resource

@export var cells: Array[Vector2i] = []   # normalized, min x/y = 0

static func make(p_cells: Array) -> SpellPattern:
	var p := SpellPattern.new()
	for c in p_cells:
		p.cells.append(c)
	return p

func preview_text(filled: String = "#", empty: String = ".") -> String:
	if cells.is_empty():
		return ""
	var w := 0
	var h := 0
	for c in cells:
		w = maxi(w, c.x + 1)
		h = maxi(h, c.y + 1)
	var rows: Array[String] = []
	for y in h:
		var row := ""
		for x in w:
			row += filled if cells.has(Vector2i(x, y)) else empty
			row += " "
		rows.append(row.rstrip(" "))
	return "\n".join(rows)
