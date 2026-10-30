class_name FragmentCard
extends Button

signal card_pressed(index: int)
signal rotate_requested(index: int)
signal drag_started(index: int)

var index := -1
var fragment: FragmentData

func _init() -> void:
	custom_minimum_size = Vector2(110, 110)
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE

func setup(i: int, f: FragmentData, is_selected: bool) -> void:
	index = i
	fragment = f
	button_pressed = is_selected
	pressed.connect(_on_pressed)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(FragmentPreview.from_fragment(f, 28))

func _on_pressed() -> void:
	card_pressed.emit(index)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		rotate_requested.emit(index)
		accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if fragment == null:
		return null
	drag_started.emit(index)
	var wrapper := Control.new()
	var ghost := FragmentPreview.from_fragment(fragment, CastingBoardView.CELL_SIZE - 2)
	ghost.position = Vector2(-CastingBoardView.CELL_SIZE / 2.0, -CastingBoardView.CELL_SIZE / 2.0)
	ghost.modulate = Color(1, 1, 1, 0.8)
	wrapper.add_child(ghost)
	set_drag_preview(wrapper)
	return {"hand_index": index}
