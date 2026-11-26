class_name TurnOrderBar
extends PanelContainer
# Shows the next moves as character icons. The first icon is the actor acting now.
# Entries come from TopPanel: TurnOrderForecast data plus "texture" and "color".

const ICON_SCENE := preload("res://scenes/battle/ui/character_icon.tscn")
const ICON_SIZE := Vector2(40, 40)          # TUNABLE
const LATER_ROUND_ALPHA := 0.6              # icons from a projected round are dimmed

@onready var _icons: HBoxContainer = %Icons


func show_order(entries: Array[Dictionary]) -> void:
	for c in _icons.get_children():
		_icons.remove_child(c)
		c.queue_free()
	if entries.is_empty():
		return
	var first_round: int = entries[0]["round"]
	var previous_round := first_round
	for i in entries.size():
		var e := entries[i]
		if e["round"] != previous_round:
			_icons.add_child(VSeparator.new())      # round break
		previous_round = e["round"]
		var icon := ICON_SCENE.instantiate() as HoverIcon
		icon.custom_minimum_size = ICON_SIZE
		_icons.add_child(icon)
		var tex: Texture2D = e.get("texture")
		var color: Color = e.get("color", HoverIcon.PLACEHOLDER_COLOR)
		icon.show_art(tex, str(e["name"]).left(1), color)
		icon.set_details(str(e["name"]), _lines(e))
		icon.highlighted = i == 0
		icon.modulate.a = LATER_ROUND_ALPHA if e["round"] > first_round else 1.0


func _lines(e: Dictionary) -> Array[String]:
	var out: Array[String] = []
	out.append(str(e["when"]))
	out.append("HP %d / %d" % [e["hp"], e["max_hp"]])
	out.append("Speed %.1f" % e["speed"])
	out.append("Status: %s" % e["status"])
	return out
