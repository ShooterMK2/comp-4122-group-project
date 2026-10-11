extends Control

const E := BattleTypes.Element

var board := CastingBoardModel.new()
var spells: Array[SpellDefinition] = []
var hand: Array[FragmentData] = []
var queue: Array[QueuedSpell] = []
var selected := -1

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
	root.add_theme_constant_override("separation", 32)
	add_child(root)

	var left := VBoxContainer.new()
	root.add_child(left)
	_info = Label.new()
	_info.text = "Pick a fragment, then click the board. R = rotate."
	left.add_child(_info)

	var grid := GridContainer.new()
	grid.columns = board.size.x
	left.add_child(grid)
	for y in board.size.y:
		for x in board.size.x:
			var b := Button.new()
			b.custom_minimum_size = Vector2(64, 64)
			b.pressed.connect(_on_cell_pressed.bind(Vector2i(x, y)))
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

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
	root.add_child(right)
	var title := Label.new()
	title.text = "Spell List"
	right.add_child(title)
	_spell_list = VBoxContainer.new()
	right.add_child(_spell_list)

# ---------- actions ----------
func _draw_hand() -> void:
	hand.clear()
	for i in 3:
		hand.append(_random_fragment())
	selected = -1
	_refresh_hand()

func _reset() -> void:
	queue.clear()
	board.reset()
	_draw_hand()
	_refresh_queue()

func _rotate_selected() -> void:
	if selected < 0:
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
	var frag := hand[selected]
	if not board.place(frag, anchor):
		_info.text = "Can't place there."
		return
	hand.remove_at(selected)
	selected = -1
	_info.text = "Placed %d tiles." % frag.cells.size()
	_resolve_matches()
	if hand.is_empty():
		_draw_hand()
	_refresh_hand()

func _resolve_matches() -> void:
	while true:
		var hit := SpellMatcher.find_first_match(board, spells)
		if hit.is_empty():
			break
		board.clear_cells(hit.cells)
		var elems: Array[int] = []
		for e in hit.elements:
			elems.append(e)
		queue.append(QueuedSpell.new(hit.spell, elems))
		_info.text = "Matched: %s" % hit.spell.display_name
	_refresh_queue()

# ---------- refresh ----------
func _refresh_board() -> void:
	for y in board.size.y:
		for x in board.size.x:
			var t := board.get_tile(Vector2i(x, y))
			var b := _cell_buttons[y * board.size.x + x]
			b.text = BattleTypes.letter_of(t)
			b.self_modulate = Color(0.25, 0.25, 0.25) if t == BattleTypes.EMPTY else BattleTypes.color_of(t)

func _refresh_hand() -> void:
	for c in _hand_box.get_children():
		c.queue_free()
	for i in hand.size():
		var b := Button.new()
		b.text = hand[i].preview_text()
		b.custom_minimum_size = Vector2(96, 96)
		b.toggle_mode = true
		b.button_pressed = (i == selected)
		b.pressed.connect(_on_fragment_pressed.bind(i))
		_hand_box.add_child(b)

func _refresh_queue() -> void:
	for c in _spell_list.get_children():
		c.queue_free()
	for q in queue:
		var l := Label.new()
		l.text = q.summary()
		_spell_list.add_child(l)