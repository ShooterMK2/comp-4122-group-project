class_name CastingBoardModel
extends RefCounted

signal changed

var size: Vector2i = BattleTypes.BOARD_SIZE
var _tiles := PackedInt32Array()

func _init() -> void:
	reset()

func reset() -> void:
	_tiles.resize(size.x * size.y)
	_tiles.fill(BattleTypes.EMPTY)
	changed.emit()

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y

func get_tile(p: Vector2i) -> int:
	return _tiles[p.y * size.x + p.x]

func is_empty(p: Vector2i) -> bool:
	return get_tile(p) == BattleTypes.EMPTY

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
		_tiles[p.y * size.x + p.x] = BattleTypes.EMPTY
	changed.emit()