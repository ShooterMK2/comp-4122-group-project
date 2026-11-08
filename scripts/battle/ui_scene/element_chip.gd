class_name ElementChip
extends PanelContainer
# One element icon. Used in the WEAK / STRONG rows.

func show_element(e: int) -> void:
	visible = true
	var tex: Texture2D = Elements.texture_of(e)
	%Icon.texture = tex
	%Letter.visible = tex == null
	%Letter.text = Elements.letter_of(e)
	tooltip_text = Elements.name_of(e)

func hide_chip() -> void:
	visible = false
