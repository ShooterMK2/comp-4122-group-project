class_name n_DeadlockOverlay
extends Control
# Backlash / Fizzle choice. Shows text and reports the button pressed; holds no rules.

signal backlash_pressed
signal fizzle_pressed


func _ready() -> void:
	%BacklashButton.pressed.connect(func(): backlash_pressed.emit())
	%FizzleButton.pressed.connect(func(): fizzle_pressed.emit())


# check: DeadlockResolver.check_backlash() -> {"ok", "cost", "reason"}
func open(tiles: int, check: Dictionary) -> void:
	%Description.text = "No fragment in your hand fits the board (%d tiles in the way). Choose how to clear it. Either choice ends your turn." % tiles
	%BacklashButton.text = "Backlash: -%d HP, the tiles deal damage" % int(check["cost"])
	%BacklashButton.disabled = not check["ok"]
	%BacklashButton.tooltip_text = str(check["reason"])
	%FizzleButton.text = "Fizzle: free, no damage"
	show()
