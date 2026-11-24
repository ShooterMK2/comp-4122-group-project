extends Control
# Tabbed inventory. Equipments = paper-doll; other tabs = list + floating detail.

const TABS := [
	{"name": "All", "filter": -1},
	{"name": "Equipments", "filter": ItemCategory.Kind.EQUIPMENT},
	{"name": "Consumables", "filter": ItemCategory.Kind.CONSUMABLE},
	{"name": "Spells", "filter": ItemCategory.Kind.SPELL},
	{"name": "Fragments", "filter": ItemCategory.Kind.FRAGMENT},
	{"name": "Importants", "filter": ItemCategory.Kind.IMPORTANT},
]

const EQUIP_TAB := 1
const SPELL_TAB := 3
const FRAGMENT_TAB := 4
const SLOT_SIZE := Vector2(108, 108)
const AVATAR_SIZE := Vector2(140, 176)
# Quadlet reads cleanest at multiples of 11.
const FONT_TAB := 22
const FONT_GOLD := 33
const FONT_TITLE := 33
const FONT_BODY := 22
const FONT_SMALL := 22
const FONT_PATTERN := 22
const ROW_MIN_HEIGHT := 56
const TAB_WIDTH := 180

@export var return_scene: String = "res://scenes/exploration/exploration_scene.tscn"

var _tab := 0
var _selected: InventoryEntry = null
var _selected_index: int = -1
var _picker_slot: int = -1
var _list_entries: Array[InventoryEntry] = []  # selectable rows only (no headers)

var _list_gold_label: Label
var _equip_gold_label: Label
var _equip_hp_label: Label
var _equip_stat_labels: Dictionary = {}
var _slot_buttons: Dictionary = {}
var _slot_icons: Dictionary = {}
var _slot_labels: Dictionary = {}

var _list: VBoxContainer
var _list_scroll: ScrollContainer
var _deck_footer: Label
var _tab_buttons: Array[Button] = []
var _row_buttons: Array[Button] = []

var _list_mode: Control
var _equip_mode: Control
var _content_host: Control
var _picker: PanelContainer
var _picker_list: VBoxContainer
var _picker_title: Label

var _float_panel: PanelContainer
var _float_detail: Label
var _float_hint: Label
var _use_btn: Button
var _deck_btn: Button
var _action_bar: HBoxContainer
var _float_track := false
var _float_layout_gen := 0  # invalidate stale deferred layout jobs

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)
	_build()
	RunState.changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	if _float_track:
		_sync_float_position()

func _build() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var panel_tex := IconLookup.panel_bg()
	if panel_tex:
		bg.texture = panel_tex
	else:
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.color = Color(0.12, 0.1, 0.09, 1)
		add_child(fallback)
	add_child(bg)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.04, 0.03, 0.55)
	add_child(dim)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 20)
	root.add_theme_constant_override("margin_top", 16)
	root.add_theme_constant_override("margin_right", 20)
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 18)
	root.add_child(main)

	main.add_child(_build_tabs())
	_content_host = Control.new()
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(_content_host)

	_list_mode = _build_list_mode()
	_list_mode.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_host.add_child(_list_mode)

	_equip_mode = _build_equip_mode()
	_equip_mode.set_anchors_preset(Control.PRESET_FULL_RECT)
	_equip_mode.visible = false
	_content_host.add_child(_equip_mode)

	_build_picker()
	_build_float_panel()

func _build_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(TAB_WIDTH, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)
	for i in TABS.size():
		var btn := Button.new()
		btn.text = TABS[i]["name"]
		btn.toggle_mode = true
		btn.button_pressed = i == 0
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", FONT_TAB)
		btn.pressed.connect(_on_tab.bind(i))
		col.add_child(btn)
		_tab_buttons.append(btn)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)
	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(0, 44)
	back.add_theme_font_size_override("font_size", FONT_TAB)
	back.pressed.connect(_on_back)
	col.add_child(back)
	return panel

func _build_list_mode() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	var top := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_list_gold_label = Label.new()
	_list_gold_label.add_theme_font_size_override("font_size", FONT_GOLD)
	top.add_child(_list_gold_label)
	col.add_child(top)

	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	_list_scroll = ScrollContainer.new()
	_list_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	_list_scroll.add_child(_list)
	# Keep the float pinned under the selected row while scrolling.
	_list_scroll.get_v_scroll_bar().value_changed.connect(_on_list_scrolled)
	_list_scroll.get_h_scroll_bar().value_changed.connect(_on_list_scrolled)
	_list_scroll.resized.connect(_on_list_scrolled)

	_deck_footer = Label.new()
	_deck_footer.visible = false
	_deck_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_deck_footer.add_theme_font_size_override("font_size", FONT_BODY)
	col.add_child(_deck_footer)

	_action_bar = HBoxContainer.new()
	_action_bar.alignment = BoxContainer.ALIGNMENT_END
	_action_bar.add_theme_constant_override("separation", 12)
	col.add_child(_action_bar)
	_use_btn = Button.new()
	_use_btn.text = "Use"
	_use_btn.focus_mode = Control.FOCUS_NONE
	_use_btn.visible = false
	_use_btn.custom_minimum_size = Vector2(120, 48)
	_use_btn.add_theme_font_size_override("font_size", FONT_TAB)
	_use_btn.pressed.connect(_on_use)
	_action_bar.add_child(_use_btn)
	_deck_btn = Button.new()
	_deck_btn.text = "Deck"
	_deck_btn.focus_mode = Control.FOCUS_NONE
	_deck_btn.visible = false
	_deck_btn.custom_minimum_size = Vector2(140, 48)
	_deck_btn.add_theme_font_size_override("font_size", FONT_TAB)
	_deck_btn.pressed.connect(_on_deck)
	_action_bar.add_child(_deck_btn)
	return panel

func _build_float_panel() -> void:
	_float_panel = PanelContainer.new()
	_float_panel.visible = false
	_float_panel.z_index = 15
	_float_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_float_panel.top_level = true  # draw above scroll clip; position tracked to row
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.08, 0.96)
	style.border_color = Color(0.85, 0.72, 0.35, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_float_panel.add_theme_stylebox_override("panel", style)
	add_child(_float_panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_float_panel.add_child(col)
	_float_detail = Label.new()
	_float_detail.autowrap_mode = TextServer.AUTOWRAP_OFF  # keep ASCII shapes aligned
	_float_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_float_detail.add_theme_font_size_override("font_size", FONT_PATTERN)
	col.add_child(_float_detail)
	_float_hint = Label.new()
	_float_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_float_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_float_hint.add_theme_font_size_override("font_size", FONT_SMALL)
	col.add_child(_float_hint)

func _build_equip_mode() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	var top := HBoxContainer.new()
	var heading := Label.new()
	heading.text = "EQUIPMENT"
	heading.add_theme_font_size_override("font_size", FONT_TITLE)
	top.add_child(heading)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_equip_gold_label = Label.new()
	_equip_gold_label.add_theme_font_size_override("font_size", FONT_GOLD)
	top.add_child(_equip_gold_label)
	col.add_child(top)

	var doll := VBoxContainer.new()
	doll.alignment = BoxContainer.ALIGNMENT_CENTER
	doll.add_theme_constant_override("separation", 18)
	col.add_child(doll)

	var row_top := HBoxContainer.new()
	row_top.alignment = BoxContainer.ALIGNMENT_CENTER
	row_top.add_theme_constant_override("separation", 36)
	doll.add_child(row_top)
	row_top.add_child(_make_slot_widget(EquipmentSlot.Kind.ARMOUR))
	row_top.add_child(_make_slot_widget(EquipmentSlot.Kind.ACCESSORY))

	var row_mid := HBoxContainer.new()
	row_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	row_mid.add_theme_constant_override("separation", 36)
	doll.add_child(row_mid)
	row_mid.add_child(_make_slot_widget(EquipmentSlot.Kind.WEAPON))
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = AVATAR_SIZE
	var avatar_fill := ColorRect.new()
	avatar_fill.color = Color(0.2, 0.45, 0.7, 1)
	avatar_fill.custom_minimum_size = AVATAR_SIZE
	avatar.add_child(avatar_fill)
	row_mid.add_child(avatar)
	row_mid.add_child(_make_slot_widget(EquipmentSlot.Kind.ALT_ARMOUR))

	_equip_hp_label = Label.new()
	_equip_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hp_label.add_theme_font_size_override("font_size", FONT_BODY)
	col.add_child(_equip_hp_label)

	var hp_bar := ProgressBar.new()
	hp_bar.name = "EquipHpBar"
	hp_bar.custom_minimum_size = Vector2(0, 28)
	hp_bar.show_percentage = false
	hp_bar.max_value = 100
	col.add_child(hp_bar)

	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	col.add_child(stats)
	for key in ["ATK", "DEF", "SPD", "MAXHP"]:
		var lab := Label.new()
		lab.add_theme_font_size_override("font_size", FONT_BODY)
		_equip_stat_labels[key] = lab
		stats.add_child(lab)
	return panel

func _make_slot_widget(slot: int) -> Control:
	var wrap := VBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 8)

	var btn := Button.new()
	btn.custom_minimum_size = SLOT_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_on_slot_pressed.bind(slot))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.1, 0.85)
	style.border_color = Color(0.75, 0.65, 0.4, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.border_color = Color(1.0, 0.86, 0.4, 1)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 10
	icon.offset_top = 10
	icon.offset_right = -10
	icon.offset_bottom = -10
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)

	wrap.add_child(btn)
	var name_lab := Label.new()
	name_lab.text = EquipmentSlot.display_name(slot)
	name_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lab.add_theme_font_size_override("font_size", FONT_SMALL)
	wrap.add_child(name_lab)

	_slot_buttons[slot] = btn
	_slot_icons[slot] = icon
	_slot_labels[slot] = name_lab
	return wrap

func _build_picker() -> void:
	_picker = PanelContainer.new()
	_picker.visible = false
	_picker.z_index = 20
	_picker.custom_minimum_size = Vector2(420, 360)
	_picker.set_anchors_preset(Control.PRESET_CENTER)
	_picker.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_picker.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_picker)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_picker.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var head := HBoxContainer.new()
	_picker_title = Label.new()
	_picker_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_title.add_theme_font_size_override("font_size", FONT_TITLE)
	head.add_child(_picker_title)
	var close := Button.new()
	close.text = "X"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(44, 44)
	close.add_theme_font_size_override("font_size", FONT_TAB)
	close.pressed.connect(_close_picker)
	head.add_child(close)
	col.add_child(head)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 240)
	col.add_child(scroll)
	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_picker_list)

func _on_tab(index: int) -> void:
	_tab = index
	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = i == index
	_clear_selection()
	_close_picker()
	_apply_mode_visibility()
	_refresh()

func _apply_mode_visibility() -> void:
	var equip := _tab == EQUIP_TAB
	_list_mode.visible = not equip
	_equip_mode.visible = equip
	if equip:
		_hide_float()

func _refresh() -> void:
	_apply_mode_visibility()
	_refresh_stats_common()
	if _tab == EQUIP_TAB:
		_refresh_equip_slots()
	else:
		_refresh_list()
		_refresh_float_and_actions()
	if _picker.visible and _picker_slot >= 0:
		_populate_picker(_picker_slot)

func _refresh_stats_common() -> void:
	var snap: PlayerStatSnapshot = RunState.snapshot()
	var gold := "$%d" % RunState.gold
	_list_gold_label.text = gold
	_equip_gold_label.text = gold
	_equip_hp_label.text = "HP: %d / %d" % [RunState.run_hp, snap.max_hp()]
	_equip_stat_labels["ATK"].text = snap.format_attack()
	_equip_stat_labels["DEF"].text = snap.format_defence()
	_equip_stat_labels["SPD"].text = snap.format_speed()
	_equip_stat_labels["MAXHP"].text = snap.format_max_hp()
	var bar := _equip_mode.find_child("EquipHpBar", true, false) as ProgressBar
	if bar:
		bar.max_value = snap.max_hp()
		bar.value = RunState.run_hp

func _refresh_equip_slots() -> void:
	for slot in _slot_icons.keys():
		var icon: TextureRect = _slot_icons[slot]
		var eq: EquipmentDefinition = RunState.loadout.get_equipped(slot)
		if eq != null:
			icon.texture = IconLookup.for_item_id(eq.id)
			icon.modulate = Color.WHITE
			_slot_labels[slot].text = "%s\n%s" % [EquipmentSlot.display_name(slot), eq.display_name]
		else:
			icon.texture = null
			icon.modulate = Color(1, 1, 1, 0.35)
			_slot_labels[slot].text = EquipmentSlot.display_name(slot)

func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	_row_buttons.clear()
	_list_entries.clear()
	var filter: int = TABS[_tab]["filter"]
	var last_group := -999
	var keep_id: StringName = _selected.id if _selected != null else &""
	var keep_cat := _selected.category if _selected != null else -1
	var new_index := -1
	for entry in RunState.list_entries(filter):
		# Ultimates are managed on the exploration Player Card only.
		if entry.category == ItemCategory.Kind.ULTIMATE:
			continue
		if filter < 0 and entry.category != last_group:
			last_group = entry.category
			var header := Label.new()
			header.text = ItemCategory.display_name(entry.category)
			header.add_theme_font_size_override("font_size", FONT_BODY)
			_list.add_child(header)
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, ROW_MIN_HEIGHT)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", FONT_BODY)
		row.add_theme_constant_override("icon_max_width", 48)
		var suffix := ""
		if entry.category == ItemCategory.Kind.EQUIPMENT and RunState.is_equipped(entry.id):
			suffix = " [E]"
		elif entry.category == ItemCategory.Kind.FRAGMENT and RunState.is_in_fragment_deck(entry.id):
			suffix = " [Deck]"
		elif entry.category == ItemCategory.Kind.SPELL and RunState.is_in_spell_deck(entry.id):
			suffix = " [Deck]"
		row.text = "%s  x%d%s" % [entry.display_name(), entry.quantity, suffix]
		row.icon = _icon_for_entry(entry)
		var idx := _list_entries.size()
		row.pressed.connect(_on_select_index.bind(idx))
		_list.add_child(row)
		_row_buttons.append(row)
		_list_entries.append(entry)
		if entry.id == keep_id and entry.category == keep_cat:
			new_index = idx
	_update_deck_footer(filter)
	# Keep selection only if the same item stack still exists (e.g. after Use).
	if new_index >= 0:
		_select_index(new_index, false)
	else:
		_clear_selection()

func _update_deck_footer(filter: int) -> void:
	if filter == ItemCategory.Kind.FRAGMENT:
		_deck_footer.visible = true
		_deck_footer.text = "Deck %d / Owned %d" % [
			RunState.fragment_deck_count(), RunState.fragment_bag().size()]
	elif filter == ItemCategory.Kind.SPELL:
		_deck_footer.visible = true
		_deck_footer.text = "Deck %d / Owned %d" % [
			RunState.spell_deck_count(), RunState.list_entries(ItemCategory.Kind.SPELL).size()]
	elif filter < 0:
		_deck_footer.visible = true
		_deck_footer.text = "Equip ultimate from Player Card on the map"
	else:
		_deck_footer.visible = false

func _icon_for_entry(entry: InventoryEntry) -> Texture2D:
	if entry.ref is ItemDefinition:
		return IconLookup.for_item_id(entry.id)
	if entry.category == ItemCategory.Kind.SPELL:
		return IconLookup.spell()
	if entry.category == ItemCategory.Kind.FRAGMENT:
		return IconLookup.fragment()
	return entry.icon()

func _on_select_index(index: int) -> void:
	_select_index(index, true)

func _select_index(index: int, scroll: bool) -> void:
	if index < 0 or index >= _list_entries.size():
		_clear_selection()
		return
	_selected_index = index
	_selected = _list_entries[index]
	for i in _row_buttons.size():
		_row_buttons[i].button_pressed = false
		_row_buttons[i].modulate = Color(1.15, 1.05, 0.75, 1) if i == index else Color.WHITE
	if scroll and index < _row_buttons.size():
		_list_scroll.ensure_control_visible(_row_buttons[index])
	_refresh_float_and_actions()

func _clear_selection() -> void:
	_selected = null
	_selected_index = -1
	for b in _row_buttons:
		b.modulate = Color.WHITE
	_hide_float()
	_refresh_float_and_actions()

func _refresh_float_and_actions() -> void:
	if _tab == EQUIP_TAB or _selected == null or _selected_index < 0 \
			or _selected_index >= _row_buttons.size():
		_hide_float()
		_use_btn.visible = false
		_deck_btn.visible = false
		_action_bar.visible = false
		return
	var desc := _selected.description().strip_edges()
	_float_detail.text = desc if not desc.is_empty() else _selected.display_name()
	var use_err := PreBattleUse.can_use(_selected, RunState)
	var show_use := PreBattleUse.is_usable_kind(_selected) and use_err.is_empty()
	_use_btn.visible = show_use
	_use_btn.disabled = false
	_float_hint.visible = use_err != "" and use_err != "—"
	_float_hint.text = use_err if _float_hint.visible else ""
	var show_deck := _selected.category == ItemCategory.Kind.FRAGMENT \
			or _selected.category == ItemCategory.Kind.SPELL
	_deck_btn.visible = show_deck
	_deck_btn.disabled = false
	if _selected.category == ItemCategory.Kind.FRAGMENT:
		_deck_btn.text = "Remove Deck" if RunState.is_in_fragment_deck(_selected.id) else "Add Deck"
	elif _selected.category == ItemCategory.Kind.SPELL:
		_deck_btn.text = "Remove Deck" if RunState.is_in_spell_deck(_selected.id) else "Add Deck"
	_action_bar.visible = show_use or show_deck
	_show_float_over_row(_selected_index)

func _on_list_scrolled(_value: Variant = null) -> void:
	# Position only — never re-run deferred layout during scroll (avoids races).
	_sync_float_position()

func _show_float_over_row(index: int) -> void:
	_float_panel.visible = true
	_float_track = true
	set_process(true)
	_float_layout_gen += 1
	var gen := _float_layout_gen
	_apply_float_width(index)
	_sync_float_position()
	call_deferred("_finalize_float_layout", index, gen)

func _float_max_width_for_row(row: Control) -> float:
	var row_w := row.get_global_rect().size.x
	var scroll_w := _list_scroll.size.x
	var bar := _list_scroll.get_v_scroll_bar()
	var gutter := 0.0
	if bar != null and bar.visible:
		gutter = bar.size.x + 6.0
	elif scroll_w > 0.0 and row_w > scroll_w - 1.0:
		# Row can report full content width; reserve a typical scrollbar gutter.
		gutter = 18.0
	return maxf(80.0, mini(row_w, scroll_w - gutter) if scroll_w > 0.0 else row_w)

func _apply_float_width(index: int) -> void:
	if index < 0 or index >= _row_buttons.size():
		return
	var row: Button = _row_buttons[index]
	if not is_instance_valid(row):
		return
	var width := _float_max_width_for_row(row)
	var pad := 28.0
	_float_detail.custom_minimum_size = Vector2(maxi(1, int(width - pad)), 0)
	_float_hint.custom_minimum_size = Vector2(maxi(1, int(width - pad)), 0)
	_float_panel.custom_minimum_size = Vector2(width, 0)
	_float_panel.size = Vector2(width, _float_panel.size.y)

func _finalize_float_layout(index: int, gen: int) -> void:
	if gen != _float_layout_gen or not _float_panel.visible:
		return
	if index < 0 or index >= _row_buttons.size():
		return
	var row: Button = _row_buttons[index]
	if not is_instance_valid(row):
		return
	var width := _float_max_width_for_row(row)
	_float_panel.reset_size()
	var panel_h := _float_panel.get_combined_minimum_size().y
	_float_panel.size = Vector2(width, panel_h)
	_sync_float_position()

func _sync_float_position() -> void:
	if not _float_track or not _float_panel.visible:
		return
	if _selected_index < 0 or _selected_index >= _row_buttons.size():
		return
	var row: Button = _row_buttons[_selected_index]
	if not is_instance_valid(row):
		return
	var row_rect := row.get_global_rect()
	var area := _list_scroll.get_global_rect()
	var width := _float_max_width_for_row(row)
	var height := _float_panel.size.y
	_float_panel.size.x = width

	var x := row_rect.position.x
	var max_x := area.position.x + area.size.x - width
	var bar := _list_scroll.get_v_scroll_bar()
	if bar != null and bar.visible:
		max_x -= bar.size.x + 4.0
	x = clampf(x, area.position.x, maxf(area.position.x, max_x))

	# Prefer just below the row; flip above or clamp if it would leave the list area.
	var y_below := row_rect.position.y + row_rect.size.y
	var y_above := row_rect.position.y - height
	var y := y_below
	if y_below + height > area.position.y + area.size.y:
		if y_above >= area.position.y:
			y = y_above
		else:
			y = area.position.y + area.size.y - height
	y = clampf(y, area.position.y, maxf(area.position.y, area.position.y + area.size.y - height))
	_float_panel.global_position = Vector2(x, y)

func _hide_float() -> void:
	_float_track = false
	_float_layout_gen += 1  # cancel any pending finalize
	set_process(false)
	if _float_panel:
		_float_panel.visible = false

func _on_slot_pressed(slot: int) -> void:
	_picker_slot = slot
	_populate_picker(slot)
	_picker.visible = true

func _populate_picker(slot: int) -> void:
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
		row.custom_minimum_size = Vector2(0, ROW_MIN_HEIGHT)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", FONT_BODY)
		row.add_theme_constant_override("icon_max_width", 48)
		var equipped := RunState.is_equipped(entry.id)
		var mark := " [E]" if equipped else ""
		row.text = "%s  x%d%s" % [entry.display_name(), entry.quantity, mark]
		row.icon = IconLookup.for_item_id(entry.id)
		row.pressed.connect(_on_picker_equip.bind(entry.id, slot))
		_picker_list.add_child(row)
	if not any:
		var empty := Label.new()
		empty.text = "(empty)"
		_picker_list.add_child(empty)

func _on_picker_equip(id: StringName, slot: int) -> void:
	# Click the already-equipped item again to unequip.
	if RunState.is_equipped(id):
		RunState.unequip_slot(slot)
	else:
		RunState.equip_item(id)
	_close_picker()
	_refresh()

func _close_picker() -> void:
	_picker.visible = false
	_picker_slot = -1

func _on_use() -> void:
	if _selected == null:
		return
	var used_id := _selected.id
	var used_cat := _selected.category
	var err := PreBattleUse.use(_selected, RunState)
	if not err.is_empty():
		_float_hint.visible = true
		_float_hint.text = err
		return
	# Refresh rebuilds the list; selection is restored if the stack still exists,
	# otherwise it clears and the description disappears.
	_refresh()
	if _selected != null and _selected.id == used_id and _selected.category == used_cat:
		_show_float_over_row(_selected_index)

func _on_deck() -> void:
	if _selected == null:
		return
	var err := ""
	if _selected.category == ItemCategory.Kind.FRAGMENT:
		if RunState.is_in_fragment_deck(_selected.id):
			err = RunState.remove_from_fragment_deck(_selected.id)
		else:
			err = RunState.add_to_fragment_deck(_selected.id)
	elif _selected.category == ItemCategory.Kind.SPELL:
		if RunState.is_in_spell_deck(_selected.id):
			err = RunState.remove_from_spell_deck(_selected.id)
		else:
			err = RunState.add_to_spell_deck(_selected.id)
	else:
		return
	if not err.is_empty():
		_float_hint.visible = true
		_float_hint.text = err
		return
	_refresh()

func _on_back() -> void:
	get_tree().change_scene_to_file(return_scene)

func _unhandled_input(event: InputEvent) -> void:
	if _picker.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_picker()
			get_viewport().set_input_as_handled()
		return
	if _tab == EQUIP_TAB:
		return
	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_UP):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_DOWN):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_clear_selection()
		get_viewport().set_input_as_handled()

func _move_selection(delta: int) -> void:
	if _list_entries.is_empty():
		return
	if _selected_index < 0:
		# No selection: up -> last, down -> first
		_select_index(_list_entries.size() - 1 if delta < 0 else 0, true)
		return
	var next := clampi(_selected_index + delta, 0, _list_entries.size() - 1)
	_select_index(next, true)
