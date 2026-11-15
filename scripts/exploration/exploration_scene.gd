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
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene_template.tscn") 
		else:
			# Testing
			var dialog = AcceptDialog.new()
			dialog.dialog_text = "Entering Node: " + NODE_TYPES[type]["name"]
			add_child(dialog)
			dialog.popup_centered()
