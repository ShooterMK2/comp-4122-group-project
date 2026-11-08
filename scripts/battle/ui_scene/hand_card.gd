class_name HandCard
extends Button
# One fragment in the hand. Shows its shape, can be selected, rotated and dragged.

signal card_pressed(index: int)
signal rotate_requested(index: int)
signal drag_started(index: int)

const GRID_COLUMNS := 4              # TUNABLE: must equal %ShapeGrid.columns (largest fragment width)
const GHOST_SCALE := 1.6             # TUNABLE: drag ghost size = board cell 32 / card cell 20

var index := -1
var fragment: FragmentData

@onready var _cells: Array[Node] = %ShapeGrid.get_children()

func _ready() -> void:
	_ignore_mouse(self)
	pressed.connect(func(): card_pressed.emit(index))
	visible = false

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

func show_fragment(i: int, f: FragmentData, is_selected: bool) -> void:
	index = i
	fragment = f
	visible = true
	set_pressed_no_signal(is_selected)
	for cell: ColorRect in _cells:
		cell.color = Color(0, 0, 0, 0)
		(cell.get_child(0) as TextureRect).texture = null
	for k in f.cells.size():
		var p: Vector2i = f.cells[k]
		var slot := p.y * GRID_COLUMNS + p.x
		if p.x >= GRID_COLUMNS or slot >= _cells.size():
			push_warning("HandCard: fragment does not fit the %d-column card grid" % GRID_COLUMNS)
			continue
		var e: int = f.elements[k] if k < f.elements.size() else Elements.Element.NONE
		var tex: Texture2D = Elements.texture_of(e)
		var cell: ColorRect = _cells[slot]
		(cell.get_child(0) as TextureRect).texture = tex
		cell.color = Color(0, 0, 0, 0) if tex != null else Elements.color_of(e)

func hide_card() -> void:
	visible = false
	fragment = null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		rotate_requested.emit(index)
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if fragment == null:
		return null
	drag_started.emit(index)
	var ghost := %ShapeGrid.duplicate() as Control      # visual copy; no scripts inside
	ghost.scale = Vector2.ONE * GHOST_SCALE
	ghost.modulate.a = 0.8
	set_drag_preview(ghost)
	return {"hand_index": index}
