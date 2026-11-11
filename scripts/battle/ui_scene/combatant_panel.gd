class_name CombatantPanel
extends PanelContainer
# One enemy. Shows data, reports clicks and spell drops. Never changes game state.
# Order top to bottom: weaknesses, HP bar, status, sprite, name, intent.

signal clicked
signal spell_dropped(definition: SpellDefinition)

const ART_SIZE := 80.0                  # TUNABLE: must match %ArtAnchor min size

var drop_enabled := false               # the controller enables this during the Casting Period

@onready var _weak_chips: Array = %WeakRow.get_children().filter(func(n): return n is ElementChip)

func _ready() -> void:
	_ignore_mouse(self)                  # only the root panel takes the mouse
	%TargetFrame.visible = false
	for chip in _weak_chips:
		chip.hide_chip()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

func setup(art_name: String, color: Color, placeholder_text: String) -> void:
	var tex: Texture2D = AssetLookup.character(art_name.get_basename())
	%ArtSprite.texture = tex
	%ArtSprite.visible = tex != null
	%ArtSprite.position = Vector2(ART_SIZE, ART_SIZE) / 2.0
	if tex != null:
		var longest := maxf(tex.get_width(), tex.get_height())
		%ArtSprite.scale = Vector2.ONE * (ART_SIZE / longest)
	%Placeholder.visible = tex == null
	%Placeholder.color = color
	%PlaceholderLabel.visible = tex == null
	%PlaceholderLabel.text = placeholder_text

func refresh(c: CombatantState, intent_text: String, is_target: bool) -> void:
	var dead := c.is_dead()
	%NameLabel.text = c.display_name
	%HpBar.max_value = c.max_hp
	%HpBar.value = c.hp
	%HpLabel.text = "%d/%d" % [c.hp, c.max_hp]
	%StatusLabel.text = CombatantText.status_line(c)
	_fill_chips(_weak_chips, c.elemental_weaknesses, %WeakRow)
	%IntentLabel.text = intent_text
	%IntentLabel.visible = intent_text != ""
	%TargetFrame.visible = is_target and not dead
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

func _fill_chips(chips: Array, elements: Array, row: Control) -> void:
	row.visible = not elements.is_empty()
	for i in chips.size():
		if i < elements.size():
			chips[i].show_element(elements[i])
		else:
			chips[i].hide_chip()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return drop_enabled and data is Dictionary and data.get("kind") == "spell_card"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	spell_dropped.emit(data["definition"])
