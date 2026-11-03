class_name CastingBoardModel
extends RefCounted

signal changed
const EMPTY := -1
const BUFF_ATTACK := -10
const BUFF_DEFENCE := -11
const BUFF_SPEED := -12
const DEBUFF_ATTACK := -20
const DEBUFF_DEFENCE := -21
const DEBUFF_SPEED := -22
const HEAL := -30
var size: Vector2i = BattleConfig.BOARD_SIZE
var _tiles := PackedInt32Array()
var _special_tiles := PackedInt32Array()
var _special_ages := PackedInt32Array()

func _init() -> void:
	reset()

func reset() -> void:
	_tiles.resize(size.x * size.y)
	_tiles.fill(EMPTY)
	_special_tiles.resize(size.x * size.y)
	_special_tiles.fill(EMPTY)
	_special_ages.resize(size.x * size.y)
	_special_ages.fill(0)
	changed.emit()

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size.x and p.y < size.y

func get_tile(p: Vector2i) -> int:
	return _tiles[p.y * size.x + p.x]

func is_empty(p: Vector2i) -> bool:
	return get_tile(p) == EMPTY

func special_tile_at(p: Vector2i) -> int:
	return _special_tiles[p.y * size.x + p.x]

func special_age_at(p: Vector2i) -> int:
	return _special_ages[p.y * size.x + p.x]

static func is_special_value(tile: int) -> bool:
	return tile <= BUFF_ATTACK

static func is_special_tile(tile: int) -> bool:
	return is_special_value(tile)

static func special_stat(tile: int) -> int:
	return absi(tile) % 10

static func is_buff(tile: int) -> bool:
	return tile >= BUFF_SPEED and tile <= BUFF_ATTACK

static func is_debuff(tile: int) -> bool:
	return tile >= DEBUFF_SPEED and tile <= DEBUFF_ATTACK

static func is_heal(tile: int) -> bool:
	return tile == HEAL

static func special_for(is_buff_tile: bool, stat: int) -> int:
	return (-10 if is_buff_tile else -20) - stat

static func random_special_tiles() -> Array[int]:
	var out: Array[int] = []
	if randf() < BattleConfig.SPECIAL_TILE_APPEAR_CHANCE:
		out.append(special_for(true, randi_range(0, 2)))
	if randf() < BattleConfig.SPECIAL_TILE_APPEAR_CHANCE:
		out.append(special_for(false, randi_range(0, 2)))
	if randf() < BattleConfig.SPECIAL_TILE_APPEAR_CHANCE:
		out.append(HEAL)
	return out

func spawn_special_tiles() -> Array[int]:
	var spawned: Array[int] = []
	for tile in random_special_tiles():
		var available: Array[Vector2i] = []
		for y in size.y:
			for x in size.x:
				var p := Vector2i(x, y)
				if special_tile_at(p) == EMPTY:
					available.append(p)
		if available.is_empty():
			break
		var position: Vector2i = available.pick_random()
		var index: int = position.y * size.x + position.x
		_special_tiles[index] = tile
		_special_ages[index] = 0
		spawned.append(tile)
	if not spawned.is_empty():
		changed.emit()
	return spawned

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
		var index: int = p.y * size.x + p.x
		_special_tiles[index] = EMPTY
		_special_ages[index] = 0
	changed.emit()

# Used by "Reset turn": tiles now persist, so we restore instead of emptying.
func snapshot() -> Dictionary:
	return {
		"tiles": _tiles.duplicate(),
		"special_tiles": _special_tiles.duplicate(),
		"special_ages": _special_ages.duplicate(),
	}

func restore(s: Dictionary) -> void:
	_tiles = s["tiles"].duplicate()
	_special_tiles = s["special_tiles"].duplicate()
	_special_ages = s["special_ages"].duplicate()
	changed.emit()

func advance_special_tiles() -> void:
	var changed_tiles := false
	for i in _special_tiles.size():
		if _special_tiles[i] == EMPTY:
			continue
		_special_ages[i] += 1
		if _special_ages[i] >= 2:
			_special_tiles[i] = EMPTY
			_special_ages[i] = 0
			changed_tiles = true
	if changed_tiles:
		changed.emit()