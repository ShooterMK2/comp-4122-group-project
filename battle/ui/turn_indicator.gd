class_name TurnIndicator
extends HBoxContainer

signal cast_pressed
signal reset_pressed

var _turn: Label
var _cast: Button
var _reset: Button

func _init() -> void:
	add_theme_constant_override("separation", 12)
	_turn = Label.new()
	_turn.text = "Turn 1"
	_turn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_turn)
	_cast = Button.new()
	_cast.text = "End Turn"
	_cast.pressed.connect(_on_cast)
	add_child(_cast)
	_reset = Button.new()
	_reset.text = "Reset"
	_reset.pressed.connect(_on_reset)
	add_child(_reset)

func _on_cast() -> void:
	cast_pressed.emit()

func _on_reset() -> void:
	reset_pressed.emit()

func set_turn(n: int) -> void:
	_turn.text = "Turn %d" % n

func set_cast_label(t: String) -> void:
	_cast.text = t

func set_cast_enabled(on: bool) -> void:
	_cast.disabled = not on
