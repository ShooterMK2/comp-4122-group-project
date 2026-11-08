class_name ResultOverlay
extends Control
# Win / lose screen. Display only.

signal restart_pressed

const COLOR_WIN := Color(1.0, 0.86, 0.4)     # TUNABLE
const COLOR_LOSE := Color(0.9, 0.3, 0.3)     # TUNABLE

func _ready() -> void:
	%RestartButton.pressed.connect(func(): restart_pressed.emit())
	visible = false

func show_result(won: bool, subtitle: String = "", stats: String = "") -> void:
	%TitleLabel.text = "VICTORY" if won else "DEFEAT"
	%TitleLabel.add_theme_color_override("font_color", COLOR_WIN if won else COLOR_LOSE)
	%SubtitleLabel.text = subtitle
	%StatsLabel.text = stats
	%StatsLabel.visible = stats != ""
	visible = true
