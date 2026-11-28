extends CanvasLayer
# Guaranteed-stat readout + pick exactly one of three non-stat offers.

signal offer_chosen(index: int)

var _title: Label
var _stat_label: Label
var _buttons: Array[Button] = []
var _root: Control

func _ready() -> void:
	layer = 80
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 320)
	panel.offset_left = -260
	panel.offset_top = -160
	panel.offset_right = 260
	panel.offset_bottom = 160
	_root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	v.add_child(_title)

	_stat_label = Label.new()
	_stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stat_label.add_theme_font_size_override("font_size", 18)
	v.add_child(_stat_label)

	var hint := Label.new()
	hint.text = "Pick one reward:"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)

	for i in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 120)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var idx := i
		b.pressed.connect(func():
			offer_chosen.emit(idx))
		row.add_child(b)
		_buttons.append(b)

	visible = false

func present(entry: Dictionary) -> void:
	var lv: int = int(entry.get("level", 1))
	_title.text = "LEVEL UP!  →  Lv %d" % lv
	_stat_label.text = "Stats: %s" % str(entry.get("stat_text", "+STAT"))
	var offers: Array = entry.get("offers", [])
	for i in _buttons.size():
		if i < offers.size():
			var o: LevelUpOffer = offers[i]
			_buttons[i].text = "%s\n%s" % [o.label, o.description]
			_buttons[i].disabled = false
			_buttons[i].visible = true
		else:
			_buttons[i].visible = false
	visible = true

func dismiss() -> void:
	visible = false
