extends CanvasLayer
# Exploration Player Card: vitals/totals/gear/ultimate on the face;
# breakdown + start-shield + pending modifiers under Details.

signal closed

const FONT_TITLE := 28
const FONT_BODY := 18
const FONT_SMALL := 16
const SLOT_SIZE := Vector2(88, 88)

var _panel: PanelContainer
var _name_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _gold_label: Label
var _atk_label: Label
var _def_label: Label
var _spd_label: Label
var _maxhp_label: Label
var _ult_label: Label
var _details_btn: Button
var _details_box: VBoxContainer
var _breakdown_labels: Array[Label] = []
var _shield_label: Label
var _pending_label: Label
var _slot_buttons: Dictionary = {}
var _slot_labels: Dictionary = {}
var _details_open := false

var _equip_float: PanelContainer
var _equip_float_label: Label
var _equip_float_slot: int = -1

var _picker: PanelContainer
var _picker_title: Label
var _picker_list: VBoxContainer
var _picker_slot: int = -1
var _picker_mode: StringName = &""  # gear | ultimate
var _ui_root: Control

func _ready() -> void:
	layer = 70
	_build()
	visible = false
	if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
		var run: Node = Engine.get_main_loop().root.get_node_or_null("RunState")
		if run != null and run.has_signal("changed"):
			run.changed.connect(refresh)

func _build() -> void:
	var root := Control.new()
	_ui_root = root
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close())
	root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(560, 520)
	_panel.offset_left = -280
	_panel.offset_top = -260
	_panel.offset_right = 280
	_panel.offset_bottom = 260
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", FONT_TITLE)
	header.add_child(_name_label)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(40, 36)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	# Shared column widths so Lv/XP and HP rows stay parallel with equal bars.
	const LABEL_COL_W := 56.0
	const VALUE_COL_W := 100.0
	const BAR_H := 18.0

	var lv_row := HBoxContainer.new()
	lv_row.add_theme_constant_override("separation", 8)
	col.add_child(lv_row)
	_level_label = Label.new()
	_level_label.custom_minimum_size = Vector2(LABEL_COL_W, 0)
	_level_label.add_theme_font_size_override("font_size", FONT_BODY)
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv_row.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.custom_minimum_size = Vector2(0, BAR_H)
	_xp_bar.show_percentage = false
	lv_row.add_child(_xp_bar)
	_xp_label = Label.new()
	_xp_label.custom_minimum_size = Vector2(VALUE_COL_W, 0)
	_xp_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lv_row.add_child(_xp_label)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	col.add_child(hp_row)
	var hp_tag := Label.new()
	hp_tag.text = "HP"
	hp_tag.custom_minimum_size = Vector2(LABEL_COL_W, 0)
	hp_tag.add_theme_font_size_override("font_size", FONT_BODY)
	hp_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_row.add_child(hp_tag)
	_hp_bar = ProgressBar.new()
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.custom_minimum_size = Vector2(0, BAR_H)
	_hp_bar.show_percentage = false
	hp_row.add_child(_hp_bar)
	_hp_label = Label.new()
	_hp_label.custom_minimum_size = Vector2(VALUE_COL_W, 0)
	_hp_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_row.add_child(_hp_label)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", FONT_BODY)
	col.add_child(_gold_label)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 18)
	col.add_child(stats)
	_atk_label = _stat_chip(stats)
	_def_label = _stat_chip(stats)
	_spd_label = _stat_chip(stats)
	_maxhp_label = _stat_chip(stats)

	var slots_row := HBoxContainer.new()
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 10)
	col.add_child(slots_row)
	for slot in [EquipmentSlot.Kind.WEAPON, EquipmentSlot.Kind.ARMOUR,
			EquipmentSlot.Kind.ALT_ARMOUR, EquipmentSlot.Kind.ACCESSORY]:
		slots_row.add_child(_make_slot_widget(slot))

	var ult_row := HBoxContainer.new()
	ult_row.add_theme_constant_override("separation", 10)
	col.add_child(ult_row)
	_ult_label = Label.new()
	_ult_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ult_label.add_theme_font_size_override("font_size", FONT_BODY)
	ult_row.add_child(_ult_label)
	var change_ult := Button.new()
	change_ult.text = "Change"
	change_ult.focus_mode = Control.FOCUS_NONE
	change_ult.pressed.connect(_open_ultimate_picker)
	ult_row.add_child(change_ult)

	_details_btn = Button.new()
	_details_btn.text = "Details v"
	_details_btn.focus_mode = Control.FOCUS_NONE
	_details_btn.pressed.connect(_toggle_details)
	col.add_child(_details_btn)

	_details_box = VBoxContainer.new()
	_details_box.visible = false
	_details_box.add_theme_constant_override("separation", 4)
	col.add_child(_details_box)
	for _i in 4:
		var lab := Label.new()
		lab.add_theme_font_size_override("font_size", FONT_SMALL)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_details_box.add_child(lab)
		_breakdown_labels.append(lab)
	_shield_label = Label.new()
	_shield_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_details_box.add_child(_shield_label)
	_pending_label = Label.new()
	_pending_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_pending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details_box.add_child(_pending_label)

	_build_picker(root)
	_build_equip_float(root)

func _build_equip_float(root: Control) -> void:
	_equip_float = PanelContainer.new()
	_equip_float.visible = false
	_equip_float.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_float.z_index = 20
	_equip_float.custom_minimum_size = Vector2(220, 0)
	root.add_child(_equip_float)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 10)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_bottom", 8)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_float.add_child(pad)
	_equip_float_label = Label.new()
	_equip_float_label.add_theme_font_size_override("font_size", FONT_SMALL)
	_equip_float_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equip_float_label.custom_minimum_size = Vector2(200, 0)
	_equip_float_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(_equip_float_label)

func _stat_chip(parent: Control) -> Label:
	var lab := Label.new()
	lab.add_theme_font_size_override("font_size", FONT_BODY)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lab)
	return lab

func _make_slot_widget(slot: int) -> Control:
	var wrap := VBoxContainer.new()
	wrap.custom_minimum_size = SLOT_SIZE + Vector2(0, 24)
	var btn := Button.new()
	btn.custom_minimum_size = SLOT_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_text = true
	btn.expand_icon = true
	btn.pressed.connect(_open_gear_picker.bind(slot))
	btn.mouse_entered.connect(_on_slot_hover.bind(slot))
	btn.mouse_exited.connect(_on_slot_unhover.bind(slot))
	wrap.add_child(btn)
	var lab := Label.new()
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", FONT_SMALL)
	lab.text = EquipmentSlot.display_name(slot)
	wrap.add_child(lab)
	_slot_buttons[slot] = btn
	_slot_labels[slot] = lab
	return wrap

func _on_slot_hover(slot: int) -> void:
	if _picker != null and _picker.visible:
		return
	var eq: EquipmentDefinition = RunState.loadout.get_equipped(slot)
	if eq == null:
		_hide_equip_float()
		return
	_show_equip_float(eq, _slot_buttons.get(slot) as Control, slot)

func _on_slot_unhover(slot: int) -> void:
	if _equip_float_slot == slot:
		_hide_equip_float()

func _on_picker_equip_hover(eq: EquipmentDefinition, row: Control) -> void:
	if eq == null:
		return
	_show_equip_float(eq, row, -100 - hash(eq.id) % 10000)

func _on_picker_equip_unhover(token: int) -> void:
	if _equip_float_slot == token:
		_hide_equip_float()

func _show_equip_float(eq: EquipmentDefinition, anchor: Control, token: int) -> void:
	_equip_float_slot = token
	_equip_float_label.text = _format_equipment_float(eq)
	_equip_float.visible = true
	_equip_float.reset_size()
	call_deferred("_place_equip_float_at", anchor)

func _hide_equip_float() -> void:
	_equip_float_slot = -1
	if _equip_float != null:
		_equip_float.visible = false

func _place_equip_float_at(anchor: Control) -> void:
	if not _equip_float.visible or anchor == null or not is_instance_valid(anchor):
		return
	var rect := anchor.get_global_rect()
	var size := _equip_float.get_combined_minimum_size()
	_equip_float.size = size
	var vp := get_viewport().get_visible_rect().size
	# Prefer to the right of the anchor; flip left / above if needed.
	var x := rect.position.x + rect.size.x + 8.0
	var y := rect.position.y
	if x + size.x > vp.x - 8.0:
		x = rect.position.x - size.x - 8.0
	if y + size.y > vp.y - 8.0:
		y = maxf(8.0, vp.y - size.y - 8.0)
	if y < 8.0:
		y = 8.0
	# For face slots (short buttons), also try above when left/right is cramped.
	if x < 8.0:
		x = clampf(rect.position.x + (rect.size.x - size.x) * 0.5, 8.0, maxf(8.0, vp.x - size.x - 8.0))
		y = rect.position.y - size.y - 8.0
		if y < 8.0:
			y = rect.position.y + rect.size.y + 8.0
	x = clampf(x, 8.0, maxf(8.0, vp.x - size.x - 8.0))
	y = clampf(y, 8.0, maxf(8.0, vp.y - size.y - 8.0))
	_equip_float.global_position = Vector2(x, y)

func _format_equipment_float(eq: EquipmentDefinition) -> String:
	var parts: Array[String] = []
	var blurb := eq.description.strip_edges().trim_suffix(".")
	if not blurb.is_empty():
		parts.append(blurb)
	var stats := _equipment_stats_text(eq)
	if not stats.is_empty():
		parts.append(stats)
	var special := _passive_text(eq)
	if not special.is_empty():
		parts.append(special)
	return ", ".join(parts)

func _equipment_stats_text(eq: EquipmentDefinition) -> String:
	var bits: Array[String] = []
	if eq.bonus_attack != 0:
		bits.append("ATK %+d" % eq.bonus_attack)
	if eq.bonus_defence != 0:
		bits.append("DEF %+d" % eq.bonus_defence)
	if not is_zero_approx(eq.bonus_speed):
		bits.append("SPD %+.0f" % eq.bonus_speed)
	if eq.bonus_max_hp != 0:
		bits.append("MAX HP %+d" % eq.bonus_max_hp)
	return ", ".join(bits)

func _passive_text(eq: EquipmentDefinition) -> String:
	match eq.passive:
		PassiveEffect.Kind.START_SHIELD:
			return "+%d Start Shield next battle" % eq.passive_amount
		PassiveEffect.Kind.ELEMENT_DAMAGE_BONUS:
			return "+%d Element damage bonus" % eq.passive_amount
		_:
			return ""

func _build_picker(root: Control) -> void:
	_picker = PanelContainer.new()
	_picker.visible = false
	_picker.set_anchors_preset(Control.PRESET_CENTER)
	_picker.custom_minimum_size = Vector2(360, 320)
	_picker.offset_left = -180
	_picker.offset_top = -160
	_picker.offset_right = 180
	_picker.offset_bottom = 160
	root.add_child(_picker)
	var v := VBoxContainer.new()
	_picker.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_picker_title = Label.new()
	_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_title.add_theme_font_size_override("font_size", FONT_BODY)
	head.add_child(_picker_title)
	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_close_picker)
	head.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 240)
	v.add_child(scroll)
	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_picker_list)

func open() -> void:
	_details_open = false
	_details_box.visible = false
	_details_btn.text = "Details v"
	_close_picker()
	_hide_equip_float()
	visible = true
	refresh()

func close() -> void:
	_close_picker()
	_hide_equip_float()
	visible = false
	closed.emit()

func refresh() -> void:
	if not is_inside_tree() or not visible:
		return
	var snap: PlayerStatSnapshot = RunState.snapshot()
	_name_label.text = snap.display_name
	_level_label.text = "Lv %d" % RunState.player_level
	var need := RunState.xp_to_next()
	if need <= 0:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_label.text = "MAX"
	else:
		_xp_bar.max_value = need
		_xp_bar.value = RunState.player_xp
		_xp_label.text = "%d / %d" % [RunState.player_xp, need]
	_hp_bar.max_value = snap.max_hp()
	_hp_bar.value = RunState.run_hp
	_hp_label.text = "%d / %d" % [RunState.run_hp, snap.max_hp()]
	_gold_label.text = "Gold  $%d" % RunState.gold
	_atk_label.text = "ATK %d" % snap.attack()
	_def_label.text = "DEF %d" % snap.defence()
	_spd_label.text = "SPD %.0f" % snap.speed()
	_maxhp_label.text = "MAX HP %d" % snap.max_hp()

	for slot in _slot_buttons.keys():
		var eq: EquipmentDefinition = RunState.loadout.get_equipped(slot)
		var btn: Button = _slot_buttons[slot]
		var lab: Label = _slot_labels[slot]
		if eq != null:
			btn.text = eq.display_name
			btn.icon = IconLookup.for_item_id(eq.id)
			lab.text = "%s\n%s" % [EquipmentSlot.display_name(slot), eq.display_name]
		else:
			btn.text = "—"
			btn.icon = null
			lab.text = EquipmentSlot.display_name(slot)

	var ult: UltimateDefinition = RunState.equipped_ultimate()
	_ult_label.text = "Ultimate: %s" % (ult.display_name if ult != null else "(none)")

	if _breakdown_labels.size() >= 4:
		_breakdown_labels[0].text = snap.format_attack()
		_breakdown_labels[1].text = snap.format_defence()
		_breakdown_labels[2].text = snap.format_speed()
		_breakdown_labels[3].text = snap.format_max_hp()
	_shield_label.text = "Start shield next battle: %d" % snap.start_shield
	_pending_label.text = "Pending: %s" % _pending_summary()

func _pending_summary() -> String:
	var p: PendingBattleModifiers = RunState.pending
	if p == null or p.is_empty():
		return "(none)"
	var parts: Array[String] = []
	if p.temp_max_hp != 0:
		parts.append("%+d temp Max HP" % p.temp_max_hp)
	if p.item_attack != 0:
		parts.append("%+d ATK" % p.item_attack)
	if p.item_defence != 0:
		parts.append("%+d DEF" % p.item_defence)
	if not is_zero_approx(p.item_speed):
		parts.append("%+.0f SPD" % p.item_speed)
	if p.start_shield != 0:
		parts.append("%+d Start Shield" % p.start_shield)
	if p.heal_amount != 0:
		parts.append("%+d Heal" % p.heal_amount)
	return ", ".join(parts)

func _toggle_details() -> void:
	_details_open = not _details_open
	_details_box.visible = _details_open
	_details_btn.text = "Details ^" if _details_open else "Details v"

func _open_gear_picker(slot: int) -> void:
	_hide_equip_float()
	_picker_mode = &"gear"
	_picker_slot = slot
	_picker_title.text = EquipmentSlot.display_name(slot)
	for c in _picker_list.get_children():
		c.queue_free()
	var any := false
	for entry in RunState.list_entries(ItemCategory.Kind.EQUIPMENT):
		var eq := entry.ref as EquipmentDefinition
		if eq == null or eq.slot != slot:
			continue
		any = true
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 44)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var mark := " [E]" if RunState.is_equipped(entry.id) else ""
		row.text = "%s%s" % [entry.display_name(), mark]
		row.icon = IconLookup.for_item_id(entry.id)
		row.pressed.connect(_on_gear_picked.bind(entry.id, slot))
		var token := -100 - hash(eq.id) % 10000
		row.mouse_entered.connect(_on_picker_equip_hover.bind(eq, row))
		row.mouse_exited.connect(_on_picker_equip_unhover.bind(token))
		_picker_list.add_child(row)
	if not any:
		var empty := Label.new()
		empty.text = "(no gear for this slot)"
		_picker_list.add_child(empty)
	_picker.visible = true

func _on_gear_picked(id: StringName, slot: int) -> void:
	_hide_equip_float()
	if RunState.is_equipped(id):
		RunState.unequip_slot(slot)
	else:
		RunState.equip_item(id)
	_close_picker()
	refresh()

func _open_ultimate_picker() -> void:
	_hide_equip_float()
	_picker_mode = &"ultimate"
	_picker_slot = -1
	_picker_title.text = "Ultimates"
	for c in _picker_list.get_children():
		c.queue_free()
	for entry in RunState.list_entries(ItemCategory.Kind.ULTIMATE):
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 48)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var active := RunState.is_ultimate_equipped(entry.id)
		row.text = "%s%s" % [entry.display_name(), " [Active]" if active else ""]
		row.disabled = active
		var ult := entry.ref as UltimateDefinition
		if ult != null and ult.icon != null:
			row.icon = ult.icon
		row.pressed.connect(_on_ultimate_picked.bind(entry.id))
		_picker_list.add_child(row)
		var desc := Label.new()
		desc.text = entry.description()
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", FONT_SMALL)
		_picker_list.add_child(desc)
	_picker.visible = true

func _on_ultimate_picked(id: StringName) -> void:
	RunState.equip_ultimate(id)
	_close_picker()
	refresh()

func _close_picker() -> void:
	_hide_equip_float()
	_picker.visible = false
	_picker_slot = -1
	_picker_mode = &""

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _picker.visible:
			_close_picker()
		else:
			close()
		get_viewport().set_input_as_handled()
