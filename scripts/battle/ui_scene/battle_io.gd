class_name BattleIO
extends PanelContainer
# Bottom half. Two periods. Shows/hides parts and reports input. Holds no game rules.
# There is no Reset button: the board can only be recovered through a deadlock choice.

enum Phase { CHANTING, CASTING }

signal cast_pressed
signal end_turn_pressed

var phase: Phase = Phase.CHANTING

@onready var spell_zone: SpellZone = %SpellZone
@onready var target_detail: TargetDetail = %TargetDetail
@onready var board_view: BoardGrid = %CastingBoard
@onready var hand_view: HandZone = %FragmentZone

func _ready() -> void:
	%CastButton.pressed.connect(func(): cast_pressed.emit())
	%EndTurnButton.pressed.connect(func(): end_turn_pressed.emit())
	set_phase(Phase.CHANTING)

func set_phase(p: Phase) -> void:
	phase = p
	var chanting := p == Phase.CHANTING
	%FragmentColumn.visible = chanting
	%BoardFrame.visible = chanting
	%CastButton.visible = chanting
	%CastSidebar.visible = not chanting
	%PhaseLabel.text = "CHANTING" if chanting else "CASTING"

func set_hint(text: String) -> void:
	%HintLabel.text = text

func set_cast_enabled(on: bool) -> void:
	%CastButton.disabled = not on
