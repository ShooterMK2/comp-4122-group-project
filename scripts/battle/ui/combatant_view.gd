class_name CombatantView
extends PanelContainer

signal clicked

const ART_SIZE := 140
const BORDER_IDLE := Color(0.25, 0.25, 0.3)
const BORDER_TARGET := Color(1.0, 0.75, 0.2)

var clickable := false
var _style: StyleBoxFlat
var _target: Label
var _title: Label
var _art: TextureRect
var _placeholder: ColorRect
var _placeholder_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _status: Label
var _intent: Label
var _elemental_info: VBoxContainer

func _init() -> void:
	custom_minimum_size = Vector2(ART_SIZE + 24, 0)
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.12, 0.12, 0.15, 0.85)
	_style.set_border_width_all(2)
	_style.border_color = BORDER_IDLE
	_style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", _style)

	var box := VBoxContainer.new()
	add_child(box)

	_target = Label.new()
	_target.text = "[ TARGET ]"
	_target.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target.modulate.a = 0.0
	box.add_child(_target)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	var frame := Control.new()
	frame.custom_minimum_size = Vector2(ART_SIZE, ART_SIZE)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(frame)

	_placeholder = ColorRect.new()
	frame.add_child(_placeholder)
	_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_placeholder_label = Label.new()
	_placeholder_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(_placeholder_label)
	_placeholder_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_art)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hp_label)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)

	_elemental_info = VBoxContainer.new()
	_elemental_info.add_theme_constant_override("separation", 2)
	box.add_child(_elemental_info)

	_intent = Label.new()
	_intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_intent)

	_ignore_mouse(self)

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

func setup(art_name: String, placeholder_color: Color, placeholder_text: String,
		p_clickable: bool) -> void:
	var tex: Texture2D = AssetLookup.character(art_name)
	_art.texture = tex
	_art.visible = tex != null
	_placeholder.visible = tex == null
	_placeholder_label.visible = tex == null
	_placeholder.color = placeholder_color
	_placeholder_label.text = placeholder_text
	clickable = p_clickable
	if clickable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func refresh(c: CombatantState, intent_text: String, is_target: bool) -> void:
	var dead := c.is_dead()
	_title.text = c.display_name
	_hp_bar.max_value = c.max_hp
	_hp_bar.value = c.hp
	_hp_label.text = "HP %d/%d" % [c.hp, c.max_hp]
	_status.text = StatusSystem.describe(c)
	_refresh_elemental_info(c)
	_intent.text = intent_text
	var targeted := is_target and not dead
	_target.modulate.a = 1.0 if targeted else 0.0
	_style.border_color = BORDER_TARGET if targeted else BORDER_IDLE
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

func _refresh_elemental_info(c: CombatantState) -> void:
	for child in _elemental_info.get_children():
		child.queue_free()
	if c.elemental_weaknesses.is_empty() and c.elemental_strengths.is_empty():
		return
	if not c.elemental_weaknesses.is_empty():
		_add_element_row("WEAK", c.elemental_weaknesses, Color(0.2, 0.65, 0.25))
	if not c.elemental_strengths.is_empty():
		_add_element_row("STRONG", c.elemental_strengths, Color(0.75, 0.2, 0.2))

func _add_element_row(title: String, elements: Array[int], background: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	_elemental_info.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(48, 0)
	label.add_theme_font_size_override("font_size", 11)
	row.add_child(label)
	for element in elements:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(28, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = background
		style.set_corner_radius_all(4)
		style.set_content_margin_all(2)
		chip.add_theme_stylebox_override("panel", style)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = Elements.texture_of(element)
		icon.tooltip_text = Elements.name_of(element)
		chip.tooltip_text = Elements.name_of(element)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
		if icon.texture == null:
			var fallback := Label.new()
			fallback.text = Elements.letter_of(element)
			fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(fallback)
		row.add_child(chip)

func _gui_input(event: InputEvent) -> void:
	if clickable and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
