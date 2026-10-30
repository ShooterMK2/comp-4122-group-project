class_name BattleLogView
extends RichTextLabel

func _init() -> void:
	custom_minimum_size = Vector2(0, 220)
	bbcode_enabled = false
	scroll_active = true
	scroll_following = true
	selection_enabled = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func add_line(s: String) -> void:
	add_text(s)
	newline()

func add_lines(lines: Array) -> void:
	for l in lines:
		add_line(str(l))
