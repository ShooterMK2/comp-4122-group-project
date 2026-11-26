class_name HoverIcon
extends PanelContainer
# Icon built on the StatusChip scene: art (or a letter fallback), a highlight frame and a
# hover popup with details. Used by the CharacterIcon and TerrainChip scenes.
# Shows data only; it never changes game state.

const FRAME_COLOR := Color(1.0, 0.9, 0.1)
const FRAME_WIDTH := 3.0
const TOOLTIP_WIDTH := 220.0                    # TUNABLE: popup text width
const PLACEHOLDER_COLOR := Color(0.35, 0.35, 0.4)

var title := ""
var lines: Array[String] = []
var highlighted := false:
	set(value):
		highlighted = value
		if _frame != null:
			_frame.queue_redraw()

@onready var _icon: TextureRect = %Icon
@onready var _letter: Label = %Letter
@onready var _count: Label = %Count

var _frame: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS    # StatusChip defaults to Ignore, which blocks hover
	_count.visible = false
	_letter.add_theme_font_size_override("font_size", 16)
	# The frame is a child so it is drawn above the icon texture.
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.draw.connect(_draw_frame)
	add_child(_frame)


func show_art(tex: Texture2D, fallback_text: String, fallback_color: Color = PLACEHOLDER_COLOR) -> void:
	_icon.texture = tex
	_icon.visible = tex != null
	_letter.visible = tex == null
	_letter.text = fallback_text
	self_modulate = Color.WHITE if tex != null else fallback_color


func set_details(p_title: String, p_lines: Array[String]) -> void:
	title = p_title
	lines = p_lines
	tooltip_text = p_title      # Godot only shows a tooltip when this is not empty


func _draw_frame() -> void:
	if not highlighted:
		return
	var half := FRAME_WIDTH * 0.5
	_frame.draw_rect(Rect2(Vector2(half, half), _frame.size - Vector2(FRAME_WIDTH, FRAME_WIDTH)),
			FRAME_COLOR, false, FRAME_WIDTH)


# Hover popup. Godot puts the returned control inside its tooltip popup.
func _make_custom_tooltip(_for_text: String) -> Object:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	var box := VBoxContainer.new()
	margin.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", FRAME_COLOR)
	box.add_child(heading)
	box.add_child(HSeparator.new())

	var body := RichTextLabel.new()
	body.fit_content = true
	body.scroll_active = false
	body.custom_minimum_size = Vector2(TOOLTIP_WIDTH, 0)
	body.text = "\n".join(lines)
	box.add_child(body)
	return margin
