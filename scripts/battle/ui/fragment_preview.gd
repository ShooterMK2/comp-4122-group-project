class_name FragmentPreview
extends GridContainer

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)

func setup(cells: Array, elems: Array, px: int) -> FragmentPreview:
	var w := 0
	var h := 0
	for c in cells:
		w = maxi(w, c.x + 1)
		h = maxi(h, c.y + 1)
	columns = maxi(w, 1)
	for y in h:
		for x in w:
			var idx := cells.find(Vector2i(x, y))
			var cell: Control
			if idx < 0:
				cell = Control.new()
			else:
				var e: int = Elements.Element.NONE
				if idx < elems.size():
					e = elems[idx]
				var tex: Texture2D = Elements.texture_of(e)
				if tex != null:
					var tr := TextureRect.new()
					tr.texture = tex
					tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tr.stretch_mode = TextureRect.STRETCH_SCALE
					tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					cell = tr
				else:
					var cr := ColorRect.new()
					cr.color = Elements.color_of(e)
					cell = cr
			cell.custom_minimum_size = Vector2(px, px)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(cell)
	return self

static func from_fragment(f: FragmentData, px: int = 28) -> FragmentPreview:
	return FragmentPreview.new().setup(f.cells, f.elements, px)
