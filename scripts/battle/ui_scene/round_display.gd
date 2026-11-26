class_name RoundDisplay
extends PanelContainer

@onready var _label: Label = %RoundLabel


func show_round(round_number: int) -> void:
	_label.text = "Round %d" % maxi(round_number, 1)    # state.turn is 0 before the first round
