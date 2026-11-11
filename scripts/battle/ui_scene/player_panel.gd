class_name PlayerPanel
extends PanelContainer
# The player HUD: portrait + HP + status + ultimate charge on top, big sprite below.
# Shows data, reports clicks and spell drops. Never changes game state.

signal clicked
signal ultimate_pressed
signal spell_dropped(definition: SpellDefinition)

const SPRITE_SIZE := 100.0              # TUNABLE: must match %SpriteAnchor min size
const GLOW_PULSE_TIME := 0.8            # TUNABLE: seconds per half-pulse of the ultimate-ready frame

var drop_enabled := false               # the controller enables this during the Casting Period
var _glow_tween: Tween

func _ready() -> void:
	_ignore_mouse(self)                  # only the root panel and the ultimate button take the mouse
	%UltimateButton.mouse_filter = Control.MOUSE_FILTER_STOP
	%ChargeBar.max_value = BattleConfig.CHARGE_GAUGE_MAX
	%UltGlow.visible = false
	%UltimateButton.pressed.connect(func(): ultimate_pressed.emit())

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

func setup(art_name: String, color: Color, placeholder_text: String) -> void:
	var tex: Texture2D = AssetLookup.character(art_name.get_basename())
	%PortraitTexture.texture = tex
	%PortraitTexture.visible = tex != null
	%PortraitPlaceholder.visible = tex == null
	%PortraitPlaceholder.color = color
	%ArtSprite.texture = tex
	%ArtSprite.visible = tex != null
	%ArtSprite.position = Vector2(SPRITE_SIZE, SPRITE_SIZE) / 2.0
	if tex != null:
		var longest := maxf(tex.get_width(), tex.get_height())
		%ArtSprite.scale = Vector2.ONE * (SPRITE_SIZE / longest)
	%Placeholder.visible = tex == null
	%Placeholder.color = color
	%PlaceholderLabel.visible = tex == null
	%PlaceholderLabel.text = placeholder_text

# Same signature as CombatantPanel.refresh so BattlefieldPanel keeps working.
func refresh(c: CombatantState, _intent_text: String, _is_target: bool,
		charge: float = 0.0, can_ultimate: bool = false) -> void:
	var dead := c.is_dead()
	%NameLabel.text = c.display_name
	%HpBar.max_value = c.max_hp
	%HpBar.value = c.hp
	%HpLabel.text = "%d/%d" % [c.hp, c.max_hp]
	%StatusLabel.text = CombatantText.status_line(c)
	%ChargeBar.value = charge
	%ChargeLabel.text = "Charge %.0f%% / %.0f%%" % [charge, BattleConfig.CHARGE_GAUGE_MAX]
	%UltimateButton.disabled = not can_ultimate
	_set_glow(can_ultimate and not dead)
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

# Pulsing golden frame around the portrait while the ultimate is ready.
func _set_glow(on: bool) -> void:
	if %UltGlow.visible == on:
		return
	%UltGlow.visible = on
	if _glow_tween != null:
		_glow_tween.kill()
	%UltGlow.modulate.a = 1.0
	if on:
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(%UltGlow, "modulate:a", 0.45, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE)
		_glow_tween.tween_property(%UltGlow, "modulate:a", 1.0, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return drop_enabled and data is Dictionary and data.get("kind") == "spell_card"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	spell_dropped.emit(data["definition"])
