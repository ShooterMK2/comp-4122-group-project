class_name PlayerPanel
extends PanelContainer
# Player HUD at the top-left of the player zone: portrait, HP bar, charge bar.
# The portrait is the ultimate button; its frame glows while the ultimate can be cast.
# Scene unique-name nodes: PortraitAnchor, PortraitTexture, PortraitPlaceholder, UltGlow,
# HpBar, HpLabel, StatusLabel, ChargeBar, ChargeLabel.

signal ultimate_pressed

const GLOW_PULSE_TIME := 0.8            # TUNABLE: seconds per half-pulse of the glow
const HP_TWEEN_TIME := 0.25

var _glow_tween: Tween
var _hp_tween: Tween
var _can_ultimate := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ignore_mouse(self)
	%PortraitAnchor.mouse_filter = Control.MOUSE_FILTER_STOP
	%PortraitAnchor.gui_input.connect(_on_portrait_input)
	%HpBar.min_value = 0.0
	%HpBar.max_value = 100.0             # percent
	%ChargeBar.max_value = BattleConfig.CHARGE_GAUGE_MAX
	%UltGlow.visible = false

func setup(art_name: String, color: Color) -> void:
	var base := art_name.get_basename()
	var tex: Texture2D = AssetLookup.character(base + "_icon")     # optional dedicated icon
	if tex == null:
		tex = AssetLookup.character(base)
	%PortraitTexture.texture = tex
	%PortraitTexture.visible = tex != null
	%PortraitPlaceholder.visible = tex == null
	%PortraitPlaceholder.color = color

func refresh(c: CombatantState, charge: float, can_ultimate: bool) -> void:
	var dead := c.is_dead()
	var pct := 100.0 * float(c.hp) / float(maxi(c.max_hp, 1))
	%HpLabel.text = "%d/%d" % [c.hp, c.max_hp]
	if _hp_tween != null:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(%HpBar, "value", pct, HP_TWEEN_TIME)
	%StatusLabel.text = CombatantText.status_line(c)
	%ChargeBar.value = charge
	_can_ultimate = can_ultimate and not dead
	if _can_ultimate:
		%ChargeLabel.text = "ULTIMATE READY (%.0f/%.0f) - click the portrait" % [charge, BattleConfig.CHARGE_GAUGE_MAX]
	else:
		%ChargeLabel.text = "Charge %.0f / %.0f" % [charge, BattleConfig.CHARGE_GAUGE_MAX]
	
	_set_glow(_can_ultimate)
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

func _on_portrait_input(event: InputEvent) -> void:
	if _can_ultimate and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		ultimate_pressed.emit()

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

# Pulsing golden frame around the portrait while the ultimate is ready.
func _set_glow(on: bool) -> void:
	%PortraitAnchor.mouse_default_cursor_shape = \
		Control.CURSOR_POINTING_HAND if on else Control.CURSOR_ARROW
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
