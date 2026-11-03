class_name DamagePreview
extends PanelContainer

var _label := Label.new()

func _init() -> void:
	custom_minimum_size = Vector2(150, 0)
	_label.add_theme_font_size_override("font_size", 9)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)

func show_preview(actions: Array[Dictionary]) -> void:
	if actions.is_empty():
		_label.text = "DAMAGE PREVIEW\nNo queued spell or attack"
		return
	var lines: Array[String] = ["DAMAGE PREVIEW"]
	for action in actions:
		var info: Dictionary = action["info"]
		var name: String = action["name"]
		lines.append("%s: %d" % [name, info["expected"]])
		lines.append(" ATK %d  AF %.2fx" % [info["effective_attack"], info["attack_factor"]])
		lines.append(" T %.2fx  O %.2fx" % [info["attack_terrain"], info["other"]])
		lines.append(" D %.2fx  E %.2fx" % [info["defence"], info["elemental"]])
		lines.append(" Br %.2fx R %.2fx" % [info["break"], info["random"]])
	_label.text = "\n".join(lines)
