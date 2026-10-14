extends Control

const E := BattleTypes.Element
const PREVIEW_CELL := 28
const OUTLINE_COLOR_COUNT := 20

var board := CastingBoardModel.new()
var spells: Array[SpellDefinition] = []
var hand: Array[FragmentData] = []
var queue: Array[QueuedSpell] = []
var selected := -1
var _outlined_cells: Dictionary = {}
var _matched_cells: Dictionary = {}

var _cell_buttons: Array[Button] = []
var _hand_box: HBoxContainer
var _spell_list: VBoxContainer
var _info: Label

func _ready() -> void:
	randomize()
	_build_demo_spells()
	_build_ui()
	board.changed.connect(_refresh_board)
	_draw_hand()
	_refresh_board()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_rotate_selected()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not _cell_buttons.is_empty():
		_refresh_board()

# ---------- demo content ----------
func _build_demo_spells() -> void:
	spells.append(SpellDefinition.make(&"fire_bolt", "Fire Bolt",
		SpellPattern.make([Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]),
		[ElementRequirement.make(E.FIRE, 2)], 6))
	spells.append(SpellDefinition.make(&"frost_nova", "Frost Nova",
		SpellPattern.make([Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]),
		[ElementRequirement.make(E.ICE, 3)], 9))
	spells.append(SpellDefinition.make(&"stone_wall", "Stone Wall",
		SpellPattern.make([Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)]),
		[ElementRequirement.make(E.EARTH, 2)], 7))

func _random_fragment() -> FragmentData:
	var shapes := [
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
		[Vector2i(0,0), Vector2i(1,0)],
		[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	]
	var pool := [E.FIRE, E.FIRE, E.ICE, E.ICE, E.EARTH, E.UNIVERSAL, E.NONE]
	var cells: Array = shapes.pick_random()
	var elems: Array = []
	for i in cells.size():
		elems.append(pool.pick_random())
	return FragmentData.make(cells, elems)

# ---------- UI (built in code) ----------
func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_top = 24
	root.add_theme_constant_override("separation", 32)
	add_child(root)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(left_scroll)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 64.0 * board.size.x
	left_scroll.add_child(left)
	_info = Label.new()
	_info.text = "Drag a fragment onto the board (or click it, then click a cell). R = rotate."
	left.add_child(_info)

	var grid := GridContainer.new()
	grid.columns = board.size.x
	left.add_child(grid)
	for y in board.size.y:
		for x in board.size.x:
			var anchor := Vector2i(x, y)
			var b := Button.new()
			b.custom_minimum_size = Vector2(64, 64)
			b.expand_icon = true
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b.pressed.connect(_on_cell_pressed.bind(anchor))
			b.set_drag_forwarding(Callable(),
				_cell_can_drop.bind(anchor), _cell_drop.bind(anchor))
			grid.add_child(b)
			_cell_buttons.append(b)

	_hand_box = HBoxContainer.new()
	left.add_child(_hand_box)

	var tools := HBoxContainer.new()
	left.add_child(tools)
	var rot := Button.new()
	rot.text = "Rotate (R)"
	rot.pressed.connect(_rotate_selected)
	tools.add_child(rot)
	var redraw := Button.new()
	redraw.text = "New hand"
	redraw.pressed.connect(_draw_hand)
	tools.add_child(redraw)
	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(_reset)
	tools.add_child(reset)

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size.x = 300
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 300
	right_scroll.add_child(right)
	var title := Label.new()
	title.text = "Spell List"
	right.add_child(title)
	_spell_list = VBoxContainer.new()
	right.add_child(_spell_list)

# ---------- drag and drop ----------
func _hand_drag(_at_position: Vector2, index: int) -> Variant:
	if index < 0 or index >= hand.size():
		return null
	selected = index
	var wrapper := Control.new()
	var ghost := _make_fragment_preview(hand[index])
	ghost.position = Vector2(-PREVIEW_CELL / 2.0, -PREVIEW_CELL / 2.0)
	ghost.modulate = Color(1, 1, 1, 0.8)
	wrapper.add_child(ghost)
	set_drag_preview(wrapper)
	return {"hand_index": index}

func _cell_can_drop(_at_position: Vector2, data: Variant, anchor: Vector2i) -> bool:
	if not (data is Dictionary and data.has("hand_index")):
		return false
	var idx: int = data["hand_index"]
	if idx < 0 or idx >= hand.size():
		return false
	var frag := hand[idx]
	var ok := board.can_place(frag, anchor)
	_show_ghost(frag, anchor, ok)
	return ok

func _cell_drop(_at_position: Vector2, data: Variant, anchor: Vector2i) -> void:
	_try_place(data["hand_index"], anchor)

func _show_ghost(frag: FragmentData, anchor: Vector2i, ok: bool) -> void:
	_refresh_board()
	var tint := Color(0.6, 1.0, 0.6) if ok else Color(1.0, 0.45, 0.45)
	for c in frag.cells:
		var p := anchor + c
		if board.in_bounds(p):
			_cell_buttons[p.y * board.size.x + p.x].self_modulate = tint

# ---------- actions ----------
func _draw_hand() -> void:
	hand.clear()
	for i in 3:
		hand.append(_random_fragment())
	selected = -1
	_refresh_hand()

func _reset() -> void:
	queue.clear()
	_outlined_cells.clear()
	_matched_cells.clear()
	board.reset()
	_draw_hand()
	_refresh_queue()

func _rotate_selected() -> void:
	if selected < 0 or selected >= hand.size():
		return
	hand[selected] = hand[selected].rotated_cw()
	_refresh_hand()

func _on_fragment_pressed(i: int) -> void:
	selected = i
	_refresh_hand()

func _on_cell_pressed(anchor: Vector2i) -> void:
	if selected < 0:
		_info.text = "Select a fragment first."
		return
	_try_place(selected, anchor)

func _try_place(index: int, anchor: Vector2i) -> void:
	if index < 0 or index >= hand.size():
		return
	var frag := hand[index]
	if not board.place(frag, anchor):
		_info.text = "Can't place there."
		return
	hand.remove_at(index)
	selected = -1
	_info.text = "Placed %d tiles." % frag.cells.size()
	_resolve_matches()
	if hand.is_empty():
		_draw_hand()
	_refresh_hand.call_deferred()

func _resolve_matches() -> void:
	var match_index := 0
	while true:
		var hit := SpellMatcher.find_first_match(board, spells)
		if hit.is_empty():
			break
		if match_index == 0:
			_outlined_cells.clear()
			_matched_cells.clear()
		var outline_color := Color.from_hsv(
			float(match_index % OUTLINE_COLOR_COUNT) / OUTLINE_COLOR_COUNT, 0.8, 1.0)
		for i in hit.cells.size():
			var cell: Vector2i = hit.cells[i]
			_outlined_cells[cell] = outline_color
			_matched_cells[cell] = hit.elements[i]
		board.clear_cells(hit.cells)
		var elems: Array[int] = []
		for e in hit.elements:
			elems.append(e)
		queue.append(QueuedSpell.new(hit.spell, elems))
		_info.text = "Matched: %s" % hit.spell.display_name
		match_index += 1
	_refresh_board()
	_refresh_queue()

# ---------- refresh ----------
func _refresh_board() -> void:
	for y in board.size.y:
		for x in board.size.x:
			var t := board.get_tile(Vector2i(x, y))
			var b := _cell_buttons[y * board.size.x + x]
			var cell := Vector2i(x, y)
			var is_preview := t == BattleTypes.EMPTY and _matched_cells.has(cell)
			var display_element: int = _matched_cells[cell] if is_preview else t
			var tex := BattleTypes.texture_of(display_element)
			b.icon = tex
			if _outlined_cells.has(cell):
				var outline := StyleBoxFlat.new()
				outline.bg_color = Color(0, 0, 0, 0)
				var outline_color: Color = _outlined_cells[cell]
				outline.border_color = outline_color
				if not _outlined_cells.has(cell + Vector2i.LEFT) \
						or _outlined_cells[cell + Vector2i.LEFT] != outline_color:
					outline.set_border_width(SIDE_LEFT, 3)
				if not _outlined_cells.has(cell + Vector2i.RIGHT) \
						or _outlined_cells[cell + Vector2i.RIGHT] != outline_color:
					outline.set_border_width(SIDE_RIGHT, 3)
				if not _outlined_cells.has(cell + Vector2i.UP) \
						or _outlined_cells[cell + Vector2i.UP] != outline_color:
					outline.set_border_width(SIDE_TOP, 3)
				if not _outlined_cells.has(cell + Vector2i.DOWN) \
						or _outlined_cells[cell + Vector2i.DOWN] != outline_color:
					outline.set_border_width(SIDE_BOTTOM, 3)
				b.add_theme_stylebox_override("normal", outline)
				b.add_theme_stylebox_override("hover", outline)
				b.add_theme_stylebox_override("pressed", outline)
				b.add_theme_stylebox_override("focus", outline)
			else:
				b.remove_theme_stylebox_override("normal")
				b.remove_theme_stylebox_override("hover")
				b.remove_theme_stylebox_override("pressed")
				b.remove_theme_stylebox_override("focus")
			if tex:
				b.text = ""
				b.self_modulate = Color(0.45, 0.45, 0.45) if is_preview else Color.WHITE
			else:
				b.text = BattleTypes.letter_of(display_element)
				if is_preview:
					b.self_modulate = Color(0.35, 0.35, 0.35)
				elif t == BattleTypes.EMPTY:
					b.self_modulate = Color(0.25, 0.25, 0.25)
				else:
					b.self_modulate = BattleTypes.color_of(t)

func _refresh_hand() -> void:
	for c in _hand_box.get_children():
		c.queue_free()
	for i in hand.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(110, 110)
		b.toggle_mode = true
		b.button_pressed = (i == selected)
		b.pressed.connect(_on_fragment_pressed.bind(i))
		b.set_drag_forwarding(_hand_drag.bind(i), Callable(), Callable())
		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(_make_fragment_preview(hand[i]))
		b.add_child(center)
		_hand_box.add_child(b)

func _make_fragment_preview(f: FragmentData) -> Control:
	var w := 0
	var h := 0
	for c in f.cells:
		w = maxi(w, c.x + 1)
		h = maxi(h, c.y + 1)
	var grid := GridContainer.new()
	grid.columns = w
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	for y in h:
		for x in w:
			var idx := f.cells.find(Vector2i(x, y))
			var cell: Control
			if idx < 0:
				cell = Control.new()
			else:
				var e: int = f.elements[idx]
				var tex := BattleTypes.texture_of(e)
				if tex:
					var tr := TextureRect.new()
					tr.texture = tex
					tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					tr.stretch_mode = TextureRect.STRETCH_SCALE
					tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					cell = tr
				else:
					var cr := ColorRect.new()
					cr.color = BattleTypes.color_of(e)
					cell = cr
			cell.custom_minimum_size = Vector2(PREVIEW_CELL, PREVIEW_CELL)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid.add_child(cell)
	return grid

func _refresh_queue() -> void:
	for c in _spell_list.get_children():
		c.queue_free()
	for q in queue:
		var entry := VBoxContainer.new()
		var elements: Array[String] = []
		for e in q.source_elements:
			elements.append(BattleTypes.name_of(e))
		var title := Label.new()
		title.text = "\"%s\" (%s)" % [q.definition.display_name, ", ".join(elements)]
		entry.add_child(title)
		var pattern := FragmentData.make(q.definition.pattern.cells, q.source_elements)
		entry.add_child(_make_fragment_preview(pattern))
		_spell_list.add_child(entry)
