class_name BoardGrid
extends GridContainer
# The 10x10 board. The 100 BoardCell nodes are placed in board.tscn; this script only fills them.

signal cell_clicked(anchor: Vector2i)
signal fragment_dropped(hand_index: int, anchor: Vector2i)

const CELL_PX := 32                 # TUNABLE: must match BoardCell min size in tile_cell.tscn

var board: CastingBoardModel
var fragment_lookup := Callable()
var outlined: Dictionary = {}
var ghosts: Dictionary = {}
var _cells: Array = []
var _hover_key := ""

func bind(p_board: CastingBoardModel, p_lookup: Callable) -> void:
	board = p_board
	fragment_lookup = p_lookup
	columns = board.size.x
	_cells = get_children().filter(func(n): return n is BoardCell)
	if _cells.size() != board.size.x * board.size.y:
		push_warning("BoardGrid: scene has %d cells, board needs %d" % [
			_cells.size(), board.size.x * board.size.y])
	for i in _cells.size():
		var cell: BoardCell = _cells[i]
		cell.anchor = Vector2i(i % board.size.x, floori(float(i) / board.size.x))
		cell.pressed.connect(_on_cell_pressed.bind(cell.anchor))
		cell.can_drop_cb = _can_drop
		cell.drop_cb = _drop
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
		var tint := Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.45, 0.45)   # green = fits, red = blocked
		for c in frag.cells:
			var p: Vector2i = anchor + c
			if board.in_bounds(p):
				var cell: BoardCell = _cells[p.y * board.size.x + p.x]
				cell.set_tint(tint)
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
			var cell: BoardCell = _cells[y * w + x]
			var t := board.get_tile(p)
			var special := board.special_tile_at(p)
			var is_ghost: bool = t == CastingBoardModel.EMPTY and ghosts.has(p)
			var shown: int = special if t == CastingBoardModel.EMPTY else t
			if is_ghost:
				shown = ghosts[p]
			cell.show_tile(shown, is_ghost)
			var overlay_tile: int = special if t != CastingBoardModel.EMPTY or is_ghost \
				else CastingBoardModel.EMPTY
			cell.set_special_overlay(overlay_tile)
			cell.tooltip_text = _special_tooltip(special) if special != CastingBoardModel.EMPTY else ""
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

func _special_tooltip(tile: int) -> String:
	if CastingBoardModel.is_heal(tile):
		return "Heal tile: restores player HP"
	var stat: String = ["ATK", "DEF", "SPD"][CastingBoardModel.special_stat(tile)]
	if CastingBoardModel.is_buff(tile):
		return "Buff %s tile: applies to player" % stat
	return "Debuff %s tile: applies to spell target" % stat
