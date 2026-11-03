class_name TileCell
extends Button

var anchor := Vector2i.ZERO
var can_drop_cb := Callable()
var drop_cb := Callable()
var _special_overlay: Label

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_text = true
	add_theme_font_size_override("font_size", 16)
	_special_overlay = Label.new()
	_special_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_special_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_special_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_special_overlay.add_theme_font_size_override("font_size", 15)
	_special_overlay.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.95))
	_special_overlay.add_theme_constant_override("outline_size", 4)
	_special_overlay.z_index = 10
	_special_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_special_overlay)

func setup(p_anchor: Vector2i, px: int) -> void:
	anchor = p_anchor
	custom_minimum_size = Vector2(px, px)

func show_tile(element: int, ghost: bool) -> void:
	if CastingBoardModel.is_special_value(element):
		icon = null
		text = _special_label(element)
		self_modulate = Color(0.45, 0.45, 0.45) if ghost else _special_color(element)
		return
	var tex: Texture2D = Elements.texture_of(element)
	icon = tex
	if tex != null:
		text = ""
		self_modulate = Color(0.45, 0.45, 0.45) if ghost else Color.WHITE
	else:
		text = Elements.letter_of(element)
		if ghost:
			self_modulate = Color(0.35, 0.35, 0.35)
		elif element == CastingBoardModel.EMPTY:
			self_modulate = Color(0.25, 0.25, 0.25)
		else:
			self_modulate = Elements.color_of(element)

func _special_label(tile: int) -> String:
	if CastingBoardModel.is_heal(tile):
		return "+"
	var stat: String = ["A", "D", "S"][CastingBoardModel.special_stat(tile)]
	return ("+" if CastingBoardModel.is_buff(tile) else "-") + stat

func _special_color(tile: int) -> Color:
	if CastingBoardModel.is_heal(tile):
		return Color(0.3, 0.9, 0.45)
	return Color(0.3, 0.75, 1.0) if CastingBoardModel.is_buff(tile) else Color(1.0, 0.35, 0.35)

func set_tint(color: Color) -> void:
	self_modulate = color

func set_special_overlay(tile: int) -> void:
	if tile == CastingBoardModel.EMPTY:
		_special_overlay.visible = false
		return
	_special_overlay.visible = true
	_special_overlay.text = _special_label(tile)
	_special_overlay.modulate = _special_color(tile)

func clear_outline() -> void:
	for style_name in ["normal", "hover", "pressed", "focus"]:
		remove_theme_stylebox_override(style_name)

func set_outline(color: Color, sides: Array) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = color
	for s in sides:
		sb.set_border_width(s, 3)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(style_name, sb)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not can_drop_cb.is_valid():
		return false
	return bool(can_drop_cb.call(anchor, data))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if drop_cb.is_valid():
		drop_cb.call(anchor, data)
