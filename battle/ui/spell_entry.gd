class_name SpellEntry
extends PanelContainer

signal move_up(index: int)
signal move_down(index: int)

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

	box.add_child(FragmentPreview.new().setup(d.pattern.cells, q.source_elements, 16))

func _on_up(index: int) -> void:
	move_up.emit(index)

func _on_down(index: int) -> void:
	move_down.emit(index)
