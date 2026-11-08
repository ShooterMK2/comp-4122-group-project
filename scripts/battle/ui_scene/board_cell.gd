class_name BoardCell
extends Button
# One board cell. Shows a tile, an outline, and accepts fragment drops.

var anchor := Vector2i.ZERO
var can_drop_cb := Callable()
var drop_cb := Callable()

@onready var _special_overlay: Label = %SpecialOverlay

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
	var sb := StyleBoxFlat.new()       # a style resource, not a UI node
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = color
	for s in sides:
		sb.set_border_width(s, 3)      # TUNABLE: outline thickness
	for style_name in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(style_name, sb)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not can_drop_cb.is_valid():
		return false
	return bool(can_drop_cb.call(anchor, data))

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if drop_cb.is_valid():
		drop_cb.call(anchor, data)
