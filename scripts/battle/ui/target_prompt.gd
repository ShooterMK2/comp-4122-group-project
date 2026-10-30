class_name TargetPrompt
extends PanelContainer
# Generic "confirm this action's target" prompt. Used for the player's spells and
# basic attack, and (optionally) for enemy spells.

signal confirmed
signal cancelled

var _title: Label
var _target: Label
var _hint: Label
var _confirm: Button
var _cancel: Button

func _init() -> void:
	visible = false
	custom_minimum_size = Vector2(340, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_target = Label.new()
	box.add_child(_target)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)

	var row := HBoxContainer.new()
	box.add_child(row)
	_confirm = Button.new()
	_confirm.pressed.connect(func(): confirmed.emit())
	row.add_child(_confirm)
	_cancel = Button.new()
	_cancel.text = "Cancel"
	_cancel.pressed.connect(func(): cancelled.emit())
	row.add_child(_cancel)

# info keys (all optional): title, target_label, target_name, hint, confirm_text, can_cancel
func show_step(info: Dictionary) -> void:
	_title.text = info.get("title", "")
	_target.text = "%s: %s" % [info.get("target_label", "Target"), info.get("target_name", "")]
	_hint.text = info.get("hint", "")
	_hint.visible = _hint.text != ""
	_confirm.text = info.get("confirm_text", "Confirm")
	_cancel.visible = info.get("can_cancel", false)
	visible = true
	_confirm.grab_focus()

func hide_prompt() -> void:
	visible = false