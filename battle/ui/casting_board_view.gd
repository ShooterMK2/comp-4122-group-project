class_name CastingBoardView
extends GridContainer

signal cell_clicked(anchor: Vector2i)
signal fragment_dropped(hand_index: int, anchor: Vector2i)

const CELL_SIZE := 48

var board: CastingBoardModel
var fragment_lookup := Callable()
var outlined: Dictionary = {}
var ghosts: Dictionary = {}
var _cells: Array[TileCell] = []
var _hover_key := ""

func _init() -> void:
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)

func bind(p_board: CastingBoardModel, p_lookup: Callable) -> void:
	board = p_board
	fragment_lookup = p_lookup
	columns = board.size.x
	for y in board.size.y:
		for x in board.size.x:
			var cell := TileCell.new()
			cell.setup(Vector2i(x, y), CELL_SIZE)
			cell.pressed.connect(_on_cell_pressed.bind(cell.anchor))
			cell.can_drop_cb = _can_drop
			cell.drop_cb = _drop
			add_child(cell)
			_cells.append(cell)
	refresh()

func _on_cell_pressed(anchor: Vector2i) -> void:
	cell_clicked.emit(anchor)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hover_key = ""
		if board != null and not _cells.is_empty():
			refresh()

func _can_drop(anchor: Vector2i, data: Variant) -> bool:
	if not (data is Dictionary and data.has("hand_index")):
		return false
	var idx: int = data["hand_index"]
	var frag: FragmentData = fragment_lookup.call(idx)
	if frag == null:
		return false
	var ok := board.can_place(frag, anchor)
	var key := "%d,%d,%d" % [idx, anchor.x, anchor.y]
	if key != _hover_key:
		_hover_key = key
		refresh()
		var tint := Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.45, 0.45)
		for c in frag.cells:
			var p: Vector2i = anchor + c
			if board.in_bounds(p):
				_cells[p.y * board.size.x + p.x].set_tint(tint)
	return ok

func _drop(anchor: Vector2i, data: Variant) -> void:
	_hover_key = ""
	fragment_dropped.emit(int(data["hand_index"]), anchor)

func _same_outline(p: Vector2i, color: Color) -> bool:
	return outlined.has(p) and outlined[p] == color

func refresh() -> void:
	if board == null or _cells.is_empty():
		return
	var w := board.size.x
	for y in board.size.y:
		for x in w:
			var p := Vector2i(x, y)
			var cell := _cells[y * w + x]
			var t := board.get_tile(p)
			var is_ghost: bool = t == CastingBoardModel.EMPTY and ghosts.has(p)
			var shown: int = t
			if is_ghost:
				shown = ghosts[p]
			cell.show_tile(shown, is_ghost)
			if outlined.has(p):
				var col: Color = outlined[p]
				var sides: Array = []
				if not _same_outline(p + Vector2i.LEFT, col):
					sides.append(SIDE_LEFT)
				if not _same_outline(p + Vector2i.RIGHT, col):
					sides.append(SIDE_RIGHT)
				if not _same_outline(p + Vector2i.UP, col):
					sides.append(SIDE_TOP)
				if not _same_outline(p + Vector2i.DOWN, col):
					sides.append(SIDE_BOTTOM)
				cell.set_outline(col, sides)
			else:
				cell.clear_outline()
