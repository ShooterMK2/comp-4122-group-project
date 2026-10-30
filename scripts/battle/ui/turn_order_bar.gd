class_name TurnOrderBar
extends HBoxContainer

func _init() -> void:
	add_theme_constant_override("separation", 6)

# entries: [{"name", "speed", "state": "done" | "now" | "next"}]
func show_order(entries: Array[Dictionary]) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var title := Label.new()
	title.text = "Turn order:"
	add_child(title)
	for i in entries.size():
		if i > 0:
			var arrow := Label.new()
			arrow.text = ">"
			add_child(arrow)
		var e: Dictionary = entries[i]
		var chip := PanelContainer.new()
		var label := Label.new()
		label.text = "%s (%.1f)" % [e["name"], e["speed"]]
		chip.add_child(label)
		match e["state"]:
			"done":
				chip.modulate = Color(1, 1, 1, 0.4)
			"now":
				chip.modulate = Color(1.0, 0.9, 0.4)
		add_child(chip)