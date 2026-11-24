extends Control

const MAP_NODE_SCENE = preload("res://scenes/exploration/map_node.tscn")
const LevelUpModalScript = preload("res://scripts/run/ui/level_up_modal.gd")
const PlayerCardOverlayScript = preload("res://scripts/run/ui/player_card_overlay.gd")
const EventModalScript = preload("res://scenes/exploration/event_scene.tscn")

@onready var camera = $Camera2D

const NODE_TYPES = {
	"BATTLE": { "name": "Battle", "icon": "res://assets/exploration/battle.png" },
	"EVENT": { "name": "Event", "icon": "res://assets/exploration/event.png" },
	"TREASURE": { "name": "Treasure", "icon": "res://assets/exploration/treasure.png" },
	"TRADE": { "name": "Trade", "icon": "res://assets/exploration/trade.png" }
}

const MAP_LAYOUT = [1, 2, 3, 2, 3, 2, 3, 2, 1, 2, 3, 2, 1]

const LAYER_Y_POSITIONS = [
	2100, 1900,			# Layer 0 - 1: Woods
	1750, 1600, 1450,	# Layer 2 - 4: Snow
	1300, 1150, 1000,	# Layer 5 - 7: Forest
	850, 700, 550,		# Layer 8 - 10: Desert
	400, 250			# Layer 11 - 12: Volcano
]

const FIXED_TYPES = {
	"0_0": "BATTLE",	# Tutorial Level
	"8_0": "BATTLE",	# Mini Boss
	"12_0": "BATTLE",	# Final Boss
}

# Determines the terrain for battle
func get_terrain(y_pos: float) -> String:
	if y_pos >= 1900: return "None"			# 1900~2276 (Woods, Starting Area)
	elif y_pos >= 1500: return "Snow"		# 1500~1900 (Snow Mountain)
	elif y_pos >= 1000: return "Forest"		# 1000~1500 (Forest)
	elif y_pos >= 500: return "Desert"		# 500~1000 (Desert)
	else: return "Volcano"					# 0~500 (Volcano)


var map_nodes: Array = []
var connections: Dictionary = {}			# Format: { "Next_Node": ["Last_Node_1", "Last_Node_2"] }
var _level_up_modal: CanvasLayer
var _player_card: CanvasLayer
var _event_scene: CanvasLayer
var start_layer = 0

func _ready() -> void:
	if RunState.pending_node_to_clear != "":
		if RunState.pending_node_to_clear not in RunState.cleared_nodes:
			RunState.cleared_nodes.append(RunState.pending_node_to_clear)
		RunState.pending_node_to_clear = ""
	generate_map_graph()
	_ensure_hud()
	_player_card = PlayerCardOverlayScript.new()
	add_child(_player_card)
	_level_up_modal = LevelUpModalScript.new()
	add_child(_level_up_modal)
	_level_up_modal.offer_chosen.connect(_on_level_up_offer_chosen)
	if RunState.has_pending_level_ups():
		_present_next_level_up()
	if "current_layer" in RunState:
		start_layer = RunState.current_layer
	start_layer = maxi(0, start_layer)
	_move_camera(start_layer)
	_event_scene = EventModalScript.instantiate()
	_event_scene.visible = false
	add_child(_event_scene)
	_event_scene.choice_made.connect(_on_event_choice_made)
	
func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel events: scroll the camera
	if event is InputEventMouseButton and event.pressed:
		var scroll_speed := 20.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.y -= scroll_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.y += scroll_speed
		var viewport_half_height = get_viewport_rect().size.y / 2.0
		var map_height = 2276.0
		camera.position.y = clampf(camera.position.y, viewport_half_height, map_height - viewport_half_height)	

func _ensure_hud() -> void:
	if has_node("RunHud"):
		return
	# Gold + Zone Exit top-left; Player Card bottom-left; backpack bottom-right.
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "RunHudLayer"
	hud_layer.layer = 1
	add_child(hud_layer)

	var hud := Control.new()
	hud.name = "RunHud"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)

	var gold := Label.new()
	gold.name = "GoldLabel"
	gold.text = "$%d" % RunState.gold
	gold.set_anchors_preset(Control.PRESET_TOP_LEFT)
	gold.offset_left = 12
	gold.offset_top = 8
	gold.offset_right = 200
	gold.offset_bottom = 40
	gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(gold)

	var exit_btn := Button.new()
	exit_btn.name = "ZoneExitButton"
	exit_btn.text = "Zone Exit"
	exit_btn.tooltip_text = "Claim zone-clear XP (once per zone)"
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	exit_btn.offset_left = 12
	exit_btn.offset_top = 44
	exit_btn.offset_right = 140
	exit_btn.offset_bottom = 76
	exit_btn.disabled = RunState.zone_exit_claimed
	exit_btn.pressed.connect(_on_zone_exit)
	hud.add_child(exit_btn)

	var player_btn := TextureButton.new()
	player_btn.name = "PlayerCardButton"
	player_btn.texture_normal = load("res://assets/ui/inventory/player_card.png")
	player_btn.ignore_texture_size = true
	player_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	player_btn.custom_minimum_size = Vector2(96, 96)
	player_btn.focus_mode = Control.FOCUS_NONE
	player_btn.tooltip_text = "Player Card"
	player_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	player_btn.offset_left = 20
	player_btn.offset_top = -116
	player_btn.offset_right = 116
	player_btn.offset_bottom = -20
	player_btn.pressed.connect(_on_player_card_pressed)
	hud.add_child(player_btn)

	var inv := TextureButton.new()
	inv.name = "InventoryButton"
	inv.texture_normal = load("res://assets/ui/inventory/backpack.png")
	inv.ignore_texture_size = true
	inv.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	inv.custom_minimum_size = Vector2(96, 96)
	inv.focus_mode = Control.FOCUS_NONE
	inv.tooltip_text = "Inventory"
	inv.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	inv.offset_left = -116
	inv.offset_top = -116
	inv.offset_right = -20
	inv.offset_bottom = -20
	inv.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/run/inventory_screen.tscn"))
	hud.add_child(inv)

	RunState.changed.connect(func():
		if is_instance_valid(gold):
			gold.text = "$%d" % RunState.gold
		if is_instance_valid(exit_btn):
			exit_btn.disabled = RunState.zone_exit_claimed)

func _on_player_card_pressed() -> void:
	if _player_card != null and _player_card.has_method("open"):
		_player_card.open()

func _on_zone_exit() -> void:
	var dialog := AcceptDialog.new()
	if RunState.zone_exit_claimed:
		dialog.dialog_text = "Zone exit XP already claimed."
	else:
		var levels := RunState.claim_zone_exit_xp()
		dialog.dialog_text = "Zone clear! +%d XP (Lv %d)%s" % [
			RunConfig.MILESTONE_ZONE_EXIT_XP,
			RunState.player_level,
			("\nLevel-up!" if levels > 0 else "")]
	add_child(dialog)
	dialog.confirmed.connect(func():
		if RunState.has_pending_level_ups():
			_present_next_level_up()
		dialog.queue_free())
	dialog.canceled.connect(func():
		if RunState.has_pending_level_ups():
			_present_next_level_up()
		dialog.queue_free())
	dialog.popup_centered()

func _present_next_level_up() -> void:
	if not RunState.has_pending_level_ups():
		return
	_level_up_modal.present(RunState.peek_pending_level_up())

func _on_level_up_offer_chosen(index: int) -> void:
	var err := RunState.choose_level_up_offer(index)
	if err != "":
		return
	_level_up_modal.dismiss()
	if RunState.has_pending_level_ups():
		_present_next_level_up()

func generate_map_graph() -> void:
	seed(RunState.map_seed)
	var type_keys = NODE_TYPES.keys()
	var screen_width = get_viewport_rect().size.x
	var x_offset = 50.0
	for layer_idx in range(MAP_LAYOUT.size()):
		var nodes_in_layer = MAP_LAYOUT[layer_idx]
		var layer_array: Array = []
		for node_idx in range(nodes_in_layer):
			var new_node = MAP_NODE_SCENE.instantiate()
			add_child(new_node)
			# Calculate Position
			var y_pos = LAYER_Y_POSITIONS[layer_idx]
			var spacing = 250
			var total_width = (nodes_in_layer - 1) * spacing
			var start_x = (screen_width - total_width) / 2.0 - x_offset
			var x_pos = start_x + (node_idx * spacing)
			new_node.position = Vector2(x_pos, y_pos)
			# Determine Node Type
			var type_key = "%d_%d" % [layer_idx, node_idx]
			var random_type = ""
			if FIXED_TYPES.has(type_key):
				random_type = FIXED_TYPES[type_key]
			else:
				random_type = type_keys.pick_random()
			new_node.set_meta("node_type", random_type)
			new_node.set_meta("layer", layer_idx)
			new_node.set_meta("index", node_idx)
			# Set Visuals
			var icon_rect = new_node.get_node("NodePanel/NodeIcon")
			var panel = new_node.get_node("NodePanel")
			var label = new_node.get_node("NodePanel/NodeNameLabel")
			var icon_path = NODE_TYPES[random_type]["icon"]
			if ResourceLoader.exists(icon_path):
				icon_rect.texture = load(icon_path)
			label.text = NODE_TYPES[random_type]["name"]
			if not panel.gui_input.is_connected(_on_node_clicked):
				panel.gui_input.connect(_on_node_clicked.bind(new_node))
			# Visuals for cleared Nodes
			var node_key = "%d_%d" % [layer_idx, node_idx]
			if node_key in RunState.cleared_nodes:
				_visual_for_cleared_node(new_node)
			layer_array.append(new_node)
		map_nodes.append(layer_array)
	build_connections()
	draw_connections()

func build_connections() -> void:
	connections.clear()
	for layer_idx in range(map_nodes.size() - 1):
		var current_layer = map_nodes[layer_idx]
		var next_layer = map_nodes[layer_idx + 1]
		# Connect each parent to its closest child
		for node in current_layer:
			var closest_child = _get_closest_node(node, next_layer)
			if closest_child != null:
				_add_connection(closest_child, node)
		# Ensure no unreachable nodes
		for next_node in next_layer:
			var closest_parent = _get_closest_node(next_node, current_layer)
			if closest_parent != null:
				_add_connection(next_node, closest_parent)

func _get_closest_node(target_node: Control, candidates: Array) -> Control:
	var closest_node = null
	var min_dist = 99999.0
	for c in candidates:
		var dist = abs(target_node.position.x - c.position.x)
		if dist < min_dist:
			min_dist = dist
			closest_node = c
	return closest_node

func _add_connection(child_node: Control, parent_node: Control) -> void:
	if not connections.has(child_node):
		connections[child_node] = []
	if parent_node not in connections[child_node]:
		connections[child_node].append(parent_node)
		
func draw_connections() -> void:
	var line_layer = Node2D.new()
	line_layer.z_index = -1
	add_child(line_layer)
	for child_node in connections.keys():
		for parent_node in connections[child_node]:
			var line = Line2D.new()
			var start_pos = parent_node.position + Vector2(50, 50)
			var end_pos = child_node.position + Vector2(50, 50)
			line.points = [start_pos, end_pos]
			line.width = 8
			line.default_color = Color(0.971, 0.82, 0.727, 0.8)
			line_layer.add_child(line)

func _mark_node_as_cleared() -> void:
	if RunState.pending_node_to_clear == "":
		return
	if RunState.pending_node_to_clear not in RunState.cleared_nodes:
		RunState.cleared_nodes.append(RunState.pending_node_to_clear)
	var parts = RunState.pending_node_to_clear.split("_")
	var l = int(parts[0])
	var n = int(parts[1])
	var target_node = map_nodes[l][n]
	_visual_for_cleared_node(target_node)
	RunState.pending_node_to_clear = ""
	
func _visual_for_cleared_node(target_node: Control) -> void:
	var panel = target_node.get_node("NodePanel")
	var overlay = ColorRect.new()
	overlay.color = Color(0.2, 0.2, 0.2, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay)

func _band_for_index(index: int) -> StringName:
	var total := maxi(1, map_nodes.size() - 1)
	var t := float(index) / float(total)
	if t < 0.34:
		return &"early"
	if t < 0.67:
		return &"mid"
	return &"late"

func _on_event_choice_made(effect: String) -> void:
	match effect:
		"monolith_touch":
			RunState.add_gold(50)
			RunState.set_run_hp(RunState.run_hp - 20)
		"monolith_pray":
			RunState.heal_run_hp(30)
		"spring_rest":
			RunState.heal_run_hp(30)
		"spring_bottle":
			RunState.add_gold(10)
		"merchant_help":
			RunState.add_gold(30)
		"merchant_rob":
			RunState.add_gold(80)
			RunState.set_run_hp(RunState.run_hp - 30)
		"leave":
			pass
	_mark_node_as_cleared()


func _on_node_clicked(event: InputEvent, node: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var type = node.get_meta("node_type")
		var layer_idx = node.get_meta("layer")
		var node_idx = node.get_meta("index")
		if layer_idx < RunState.current_layer: return  # Can move within same layer, not going back
		if RunState.current_layer == -1:
			if layer_idx != 0:  # Starting: Can only click the first layer
				return
		else:
			if layer_idx == RunState.current_layer:
				if node_idx == RunState.current_node_index: return
				pass 
			else: 
				var current_node = map_nodes[RunState.current_layer][RunState.current_node_index]
				if connections.has(node):
					if current_node not in connections[node]: return  # Not connected with current node
				else: return  # Not recorded in dictionary
		RunState.current_layer = layer_idx
		RunState.current_node_index = node_idx
		RunState.pending_node_to_clear = "%d_%d" % [layer_idx, node_idx]
		_move_camera(layer_idx)

		if type == "BATTLE":
			if RunState.fragment_deck_count() <= 0:
				RunState.autofill_fragment_deck()
			RunState.pending_encounter_band = _band_for_index(node_idx)
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene_template.tscn")
		elif type == "EVENT":
			var event_data = EventDatabase.get_random_event()
			_event_scene.show_event(event_data)
			RunState.pending_node_to_clear = "%d_%d" % [layer_idx, node_idx]
		else:
			var levels := RunState.grant_milestone_xp(RunConfig.MILESTONE_NODE_XP)
			var dialog = AcceptDialog.new()
			dialog.dialog_text = "Entering Node: %s\n+%d XP%s" % [
				NODE_TYPES[type]["name"],
				RunConfig.MILESTONE_NODE_XP,
				("\nLevel-up!" if levels > 0 else "")]
			add_child(dialog)
			dialog.confirmed.connect(func():
				if RunState.has_pending_level_ups():
					_present_next_level_up()
				dialog.queue_free())
			dialog.canceled.connect(func():
				if RunState.has_pending_level_ups():
					_present_next_level_up()
				dialog.queue_free())
			dialog.popup_centered()

func _move_camera(layer_idx: int) -> void:
	if layer_idx < 0 or layer_idx >= LAYER_Y_POSITIONS.size():
		return
	var target_y = LAYER_Y_POSITIONS[layer_idx] + 50
	camera.position.y = target_y
