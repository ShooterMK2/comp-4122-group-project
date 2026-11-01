class_name SpellQueueView
extends VBoxContainer

signal reorder(from_index: int, to_index: int)

var _list: VBoxContainer
var _preview_panel: PanelContainer
var _spell_damage_bar: ProgressBar
var _basic_damage_bar: ProgressBar
var _spell_damage_value: Label
var _basic_damage_value: Label
var _total_damage: Label
var _enemy_hp_list: VBoxContainer
var _player_hp: Label
var _details: Label
var _entries: Array[SpellEntry] = []

func _init() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(360, 0)
	var title := Label.new()
	title.text = "Spell Queue"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	_list = VBoxContainer.new()
	add_child(_list)
	add_child(HSeparator.new())
	_build_preview()

func _build_preview() -> void:
	_preview_panel = PanelContainer.new()
	_preview_panel.custom_minimum_size = Vector2(0, 220)
	add_child(_preview_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.15, 0.96)
	panel_style.border_color = Color(0.3, 0.42, 0.58)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	_preview_panel.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	_preview_panel.add_child(content)

	var heading := Label.new()
	heading.text = "CAST PREVIEW"
	heading.add_theme_font_size_override("font_size", 16)
	content.add_child(heading)

	_spell_damage_bar = _add_damage_row(content, "SPELL DAMAGE",
		Elements.texture_of(Elements.Element.UNIVERSAL))
	_basic_damage_bar = _add_damage_row(content, "BOARD ATTACK",
		Elements.texture_of(Elements.Element.NONE))
	_spell_damage_value = _spell_damage_bar.get_meta("value_label") as Label
	_basic_damage_value = _basic_damage_bar.get_meta("value_label") as Label

	_total_damage = Label.new()
	_total_damage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_total_damage.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	content.add_child(_total_damage)

	var enemy_heading := Label.new()
	enemy_heading.text = "PROJECTED HP"
	enemy_heading.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	content.add_child(enemy_heading)
	_enemy_hp_list = VBoxContainer.new()
	_enemy_hp_list.add_theme_constant_override("separation", 3)
	content.add_child(_enemy_hp_list)

	_player_hp = Label.new()
	_player_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(_player_hp)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 12)
	content.add_child(_details)

func _add_damage_row(parent: VBoxContainer, title: String, icon: Texture2D) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var icon_view := TextureRect.new()
	icon_view.custom_minimum_size = Vector2(24, 24)
	icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_view.texture = icon
	row.add_child(icon_view)

	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(112, 0)
	row.add_child(label)

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(80, 20)
	row.add_child(bar)

	var value := Label.new()
	value.custom_minimum_size = Vector2(38, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	bar.set_meta("value_label", value)
	return bar

func show_queue(queue: Array) -> void:
	_entries.clear()
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	if queue.is_empty():
		var empty := Label.new()
		empty.text = "(no spells queued)"
		_list.add_child(empty)
		return
	for i in queue.size():
		var entry := SpellEntry.new()
		entry.setup(i, queue.size(), queue[i])
		entry.move_up.connect(_on_up)
		entry.move_down.connect(_on_down)
		_list.add_child(entry)
		_entries.append(entry)

func show_preview(info: Dictionary) -> void:
	var spell_damages: Array = info.get("spell_damages", [])
	for i in mini(_entries.size(), spell_damages.size()):
		_entries[i].set_projected_damage(spell_damages[i])
	var spell_dmg: int = info["spells"]
	var basic: int = info["basic"]
	var total := spell_dmg + basic
	var scale := maxi(total, 1)
	_spell_damage_bar.max_value = scale
	_spell_damage_bar.value = spell_dmg
	_basic_damage_bar.max_value = scale
	_basic_damage_bar.value = basic
	_spell_damage_value.text = str(spell_dmg)
	_basic_damage_value.text = str(basic)
	_total_damage.text = "TOTAL DAMAGE  %d" % total

	for child in _enemy_hp_list.get_children():
		child.queue_free()
	var after: Array = info["enemies_after"]
	for e in after:
		var hp := ProgressBar.new()
		hp.show_percentage = false
		hp.max_value = e["max_hp"]
		hp.value = e["hp"]
		hp.custom_minimum_size = Vector2(0, 16)
		hp.tooltip_text = "%s: HP %d/%d" % [e["name"], e["hp"], e["max_hp"]]
		_enemy_hp_list.add_child(hp)
		var name_label := Label.new()
		name_label.text = "%s  %d/%d" % [e["name"], e["hp"], e["max_hp"]]
		name_label.add_theme_font_size_override("font_size", 12)
		_enemy_hp_list.add_child(name_label)
	_player_hp.text = "PLAYER HP  %d/%d" % [info["player_hp"], info["player_max_hp"]]
	var lines: Array = info["lines"]
	_details.text = "\n".join(lines) if not lines.is_empty() else "No additional effects."

func _on_up(i: int) -> void:
	reorder.emit(i, i - 1)

func _on_down(i: int) -> void:
	reorder.emit(i, i + 1)
