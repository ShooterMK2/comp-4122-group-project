class_name CastingBoardModel
extends RefCounted

signal changed
const EMPTY := -1
var size: Vector2i = BattleConfig.BOARD_SIZE
var _tiles := PackedInt32Array()

func _init() -> void:
	reset()

func reset() -> void:
	_tiles.resize(size.x * size.y)
	_tiles.fill(EMPTY)
	changed.emit()

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y

func get_tile(p: Vector2i) -> int:
	return _tiles[p.y * size.x + p.x]

func is_empty(p: Vector2i) -> bool:
	return get_tile(p) == EMPTY

func filled_count() -> int:
	var n := 0
	for t in _tiles:
		if t != EMPTY:
			n += 1
	return n

func can_place(f: FragmentData, anchor: Vector2i) -> bool:
	for c in f.cells:
		var p := anchor + c
		if not in_bounds(p) or not is_empty(p):
			return false
	return true

func place(f: FragmentData, anchor: Vector2i) -> bool:
	if not can_place(f, anchor):
		return false
	for i in f.cells.size():
		var p := anchor + f.cells[i]
		_tiles[p.y * size.x + p.x] = f.elements[i]
	changed.emit()
	return true

func clear_cells(cells: Array) -> void:
	for p in cells:
		_tiles[p.y * size.x + p.x] = EMPTY
	changed.emit()

# Used by "Reset turn": tiles now persist, so we restore instead of emptying.
func snapshot() -> PackedInt32Array:
	return _tiles.duplicate()

func restore(s: PackedInt32Array) -> void:
	_tiles = s.duplicate()
	changed.emit()