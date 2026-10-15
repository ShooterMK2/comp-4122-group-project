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
	_intent.text = intent_text
	var targeted := is_target and not dead
	_target.modulate.a = 1.0 if targeted else 0.0
	_style.border_color = BORDER_TARGET if targeted else BORDER_IDLE
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if clickable and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
