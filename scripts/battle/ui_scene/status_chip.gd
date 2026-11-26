class_name StatusChip
extends PanelContainer
# One status icon with a stack number in the corner.
# Scene needs unique-name children: Icon (TextureRect), Letter (Label), Count (Label).

func show_entry(e: Dictionary) -> void:
	visible = true
	var tex: Texture2D = e["icon"]
	%Icon.texture = tex
	%Icon.visible = tex != null
	%Letter.visible = tex == null
	%Letter.text = e["letter"]
	self_modulate = Color.WHITE if tex != null else (e["color"] as Color).lerp(Color.WHITE, 0.35)
	%Count.visible = true
	%Count.text = str(e["count"])
	tooltip_text = e["tooltip"]

func show_overflow(extra: int) -> void:
	visible = true
	%Icon.visible = false
	%Letter.visible = true
	%Letter.text = "+%d" % extra
	%Count.visible = false
	self_modulate = Color(0.8, 0.8, 0.8)
	tooltip_text = "%d more status effect(s)" % extra
