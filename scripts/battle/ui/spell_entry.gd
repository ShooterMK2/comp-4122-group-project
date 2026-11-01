class_name SpellEntry
extends PanelContainer

signal move_up(index: int)
signal move_down(index: int)

var _damage_label: Label

func setup(index: int, count: int, q: QueuedSpell) -> void:
	var d := q.definition
	var box := VBoxContainer.new()
	add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var names: Array[String] = []
	for e in q.source_elements:
		names.append(Elements.name_of(e))
	var title := Label.new()
	title.text = "%d. %s (%s)" % [index + 1, d.display_name, ", ".join(names)]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	head.add_child(title)

	var up := Button.new()
	up.text = "^"
	up.disabled = index == 0
	up.pressed.connect(_on_up.bind(index))
	head.add_child(up)
	var down := Button.new()
	down.text = "v"
	down.disabled = index >= count - 1
	down.pressed.connect(_on_down.bind(index))
	head.add_child(down)

	var fx_text: Array[String] = []
	for fx in d.effects:
		fx_text.append(fx.describe())
	var info := Label.new()
	var fx_line := ", ".join(fx_text) if not fx_text.is_empty() else "no effects"
	info.text = "Base %d | %s" % [d.base_damage, fx_line]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	_damage_label = Label.new()
	_damage_label.text = "Final damage: --"
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	box.add_child(_damage_label)

	box.add_child(FragmentPreview.new().setup(d.pattern.cells, q.source_elements, 16))

func set_projected_damage(damage: int) -> void:
	if _damage_label != null:
		_damage_label.text = "Final damage: %d" % damage

func _on_up(index: int) -> void:
	move_up.emit(index)

func _on_down(index: int) -> void:
	move_down.emit(index)
