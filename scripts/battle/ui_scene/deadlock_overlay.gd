class_name _DeadlockOverlay
extends Control
# Shown when no fragment fits. Two choices; it only reports which one the player picked.

signal backlash_chosen
signal fizzle_chosen

func _ready() -> void:
	visible = false
	%BacklashButton.pressed.connect(func(): backlash_chosen.emit())
	%FizzleButton.pressed.connect(func(): fizzle_chosen.emit())

func show_choice(cost: int, can_backlash: bool, hp: int) -> void:
	%MessageLabel.text = "No fragment fits the board. Choose how to recover."
	%BacklashButton.text = "BACKLASH: lose %d HP (you have %d). The board's tiles hit the target and your turn ends." % [cost, hp]
	%BacklashButton.disabled = not can_backlash
	%BacklashButton.tooltip_text = "" if can_backlash else "Not enough HP: Backlash can never kill you."
	%FizzleButton.text = "FIZZLE: lose all tiles for free. Your turn ends."
	visible = true
	if can_backlash:
		%BacklashButton.grab_focus()
	else:
		%FizzleButton.grab_focus()

func close() -> void:
	visible = false
