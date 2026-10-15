class_name SpellQueueView
extends VBoxContainer

signal reorder(from_index: int, to_index: int)

var _list: VBoxContainer
var _preview: Label

func _init() -> void:
	add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Spell Queue"
	add_child(title)
	_list = VBoxContainer.new()
	add_child(_list)
	add_child(HSeparator.new())
	_preview = Label.new()
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_preview)

func show_queue(queue: Array) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	if queue.is_empty():
		var empty := Label.new()
		empty.text = "(no spells queued)"
		_list.add_child(empty)
		return
	for i in queue.size():
		var entry := SpellEntry.new()
		entry.setup(i, queue.size(), queue[i])
		entry.move_up.connect(_on_up)
		entry.move_down.connect(_on_down)
		_list.add_child(entry)

func show_preview(info: Dictionary) -> void:
	var spell_dmg: int = info["spells"]
	var basic: int = info["basic"]
	var out: Array[String] = []
	out.append("Predicted: spells %d + tiles %d = %d" % [spell_dmg, basic, spell_dmg + basic])
	var after: Array = info["enemies_after"]
	for e in after:
		out.append("  %s: HP %d/%d" % [e["name"], e["hp"], e["max_hp"]])
	out.append("You: HP %d/%d" % [info["player_hp"], info["player_max_hp"]])
	var lines: Array = info["lines"]
	if not lines.is_empty():
		out.append("")
		out.append("Breakdown:")
		for line in lines:
			out.append("  " + str(line))
	_preview.text = "\n".join(out)

func _on_up(i: int) -> void:
	reorder.emit(i, i - 1)

func _on_down(i: int) -> void:
	reorder.emit(i, i + 1)
