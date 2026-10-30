class_name DeadlockOverlay
extends Control
# Sits on top of the casting board. Hidden unless a deadlock is detected.

signal backlash_pressed
signal fizzle_pressed

var _detail: Label
var _backlash: Button
var _backlash_note: Label
var _fizzle: Button

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(320, 0)
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "DEADLOCK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail)

	_backlash = Button.new()
	_backlash.tooltip_text = "Pay HP to clear the board. Each cleared tile deals base damage. Cost rises with each use this battle."
	_backlash.pressed.connect(func(): backlash_pressed.emit())
	box.add_child(_backlash)

	_backlash_note = Label.new()
	_backlash_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_backlash_note)

	_fizzle = Button.new()
	_fizzle.tooltip_text = "Clear the board at no HP cost, with no damage."
	_fizzle.pressed.connect(func(): fizzle_pressed.emit())
	box.add_child(_fizzle)

# info: tiles, cost, damage, can_backlash, reason
func show_choice(info: Dictionary) -> void:
	_detail.text = "No fragment in your hand fits the board (%d tile(s) in the way). Choose how to clear it. Either choice ends your turn." % info["tiles"]
	_backlash.text = "Backlash  (-%d HP, deal %d dmg, ends turn)" % [info["cost"], info["damage"]]
	_backlash.disabled = not info["can_backlash"]
	_backlash_note.text = info["reason"]
	_backlash_note.visible = not info["can_backlash"]
	_fizzle.text = "Fizzle  (free, ends turn)"
	visible = true

func hide_overlay() -> void:
	visible = false