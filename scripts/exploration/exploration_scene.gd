extends Control

const NODE_TYPES = {
	"BATTLE": { "name": "Battle", "icon": "res://assets/exploration/battle.png" },
	"EVENT": { "name": "Event", "icon": "res://assets/exploration/event.png" },
	"TREASURE": { "name": "Treasure", "icon": "res://assets/exploration/treasure.png" },
	"TRADE": { "name": "Trade", "icon": "res://assets/exploration/trade.png" }
}

var map_nodes: Array = []

func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("MapNode"):
			map_nodes.append(child)
	gen_node_types()
	_ensure_hud()

func _ensure_hud() -> void:
	if has_node("RunHud"):
		return
	var hud := HBoxContainer.new()
	hud.name = "RunHud"
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 12
	hud.offset_top = 8
	hud.offset_right = -12
	hud.offset_bottom = 48
	add_child(hud)
	var gold := Label.new()
	gold.name = "GoldLabel"
	gold.text = "$%d" % RunState.gold
	hud.add_child(gold)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)
	var inv := Button.new()
	inv.text = "Inventory"
	inv.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/run/inventory_screen.tscn"))
	hud.add_child(inv)
	RunState.changed.connect(func():
		if is_instance_valid(gold):
			gold.text = "$%d" % RunState.gold)

func gen_node_types() -> void:
	var type_keys = NODE_TYPES.keys()
	var total_nodes = map_nodes.size()

	for i in range(total_nodes):
		var current_node = map_nodes[i]
		var random_type = ""

		# First and Last Nodes are Battle Node
		if i == total_nodes - 1 or i == 0:
			random_type = "BATTLE"
		else:
			random_type = type_keys.pick_random()

		current_node.set_meta("node_type", random_type)

		var icon_rect = current_node.get_node("NodePanel/NodeIcon")
		var panel = current_node.get_node("NodePanel")
		var label = current_node.get_node("NodePanel/NodeNameLabel")

		var icon_path = NODE_TYPES[random_type]["icon"]
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		label.text = NODE_TYPES[random_type]["name"]

		if not panel.gui_input.is_connected(_on_node_clicked):
			panel.gui_input.connect(_on_node_clicked.bind(current_node))

func _on_node_clicked(event: InputEvent, node: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var type = node.get_meta("node_type")

		if type == "BATTLE":
			if RunState.fragment_deck_count() <= 0:
				RunState.autofill_fragment_deck()
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene_template.tscn")
		else:
			# Testing
			var dialog = AcceptDialog.new()
			dialog.dialog_text = "Entering Node: " + NODE_TYPES[type]["name"]
			add_child(dialog)
			dialog.popup_centered()
