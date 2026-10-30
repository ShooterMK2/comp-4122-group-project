class_name TileCell
extends Button

var anchor := Vector2i.ZERO
var can_drop_cb := Callable()
var drop_cb := Callable()

func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_text = true
	add_theme_font_size_override("font_size", 16)

func setup(p_anchor: Vector2i, px: int) -> void:
	anchor = p_anchor
	custom_minimum_size = Vector2(px, px)

func show_tile(element: int, ghost: bool) -> void:
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

func set_tint(color: Color) -> void:
	self_modulate = color

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
