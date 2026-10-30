class_name FragmentData
extends Resource

@export var cells: Array[Vector2i] = []
@export var elements: Array[int] = []

static func make(p_cells: Array, p_elements: Array) -> FragmentData:
	var f := FragmentData.new()
	for i in p_cells.size():
		f.cells.append(p_cells[i])
		f.elements.append(p_elements[i])
	return f

func rotated_cw() -> FragmentData:
	var f := FragmentData.new()
	for i in cells.size():
		f.cells.append(Vector2i(-cells[i].y, cells[i].x))
		f.elements.append(elements[i])
	f.normalize()
	return f

func normalize() -> void:
	var min_x := 9999
	var min_y := 9999
	for c in cells:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
	for i in cells.size():
		cells[i] = cells[i] - Vector2i(min_x, min_y)

func preview_text() -> String:
	var w := 0
	var h := 0
	for c in cells:
		w = maxi(w, c.x + 1)
		h = maxi(h, c.y + 1)
	var rows: Array[String] = []
	for y in h:
		var row := ""
		for x in w:
			var idx := cells.find(Vector2i(x, y))
			row += (Elements.letter_of(elements[idx]) if idx >= 0 else " ") + " "
		rows.append(row)
	return "\n".join(rows)
