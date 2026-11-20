extends Control

const LevelUpModalScript = preload("res://scripts/run/ui/level_up_modal.gd")
const PlayerCardOverlayScript = preload("res://scripts/run/ui/player_card_overlay.gd")

const NODE_TYPES = {
	"BATTLE": { "name": "Battle", "icon": "res://assets/exploration/battle.png" },
	"EVENT": { "name": "Event", "icon": "res://assets/exploration/event.png" },
	"TREASURE": { "name": "Treasure", "icon": "res://assets/exploration/treasure.png" },
	"TRADE": { "name": "Trade", "icon": "res://assets/exploration/trade.png" }
}

var map_nodes: Array = []
var _level_up_modal: CanvasLayer
var _player_card: CanvasLayer

func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("MapNode"):
			map_nodes.append(child)
	gen_node_types()
	_ensure_hud()
	_player_card = PlayerCardOverlayScript.new()
	add_child(_player_card)
	_level_up_modal = LevelUpModalScript.new()
	add_child(_level_up_modal)
	_level_up_modal.offer_chosen.connect(_on_level_up_offer_chosen)
	if RunState.has_pending_level_ups():
		_present_next_level_up()

func _ensure_hud() -> void:
	if has_node("RunHud"):
		return
	# Gold + Zone Exit top-left; Player Card bottom-left; backpack bottom-right.
	var hud := Control.new()
	hud.name = "RunHud"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

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
		current_node.set_meta("node_index", i)

		var icon_rect = current_node.get_node("NodePanel/NodeIcon")
		var panel = current_node.get_node("NodePanel")
		var label = current_node.get_node("NodePanel/NodeNameLabel")

		var icon_path = NODE_TYPES[random_type]["icon"]
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		label.text = NODE_TYPES[random_type]["name"]

		if not panel.gui_input.is_connected(_on_node_clicked):
			panel.gui_input.connect(_on_node_clicked.bind(current_node))

func _band_for_index(index: int) -> StringName:
	var total := maxi(1, map_nodes.size() - 1)
	var t := float(index) / float(total)
	if t < 0.34:
		return &"early"
	if t < 0.67:
		return &"mid"
	return &"late"

func _on_node_clicked(event: InputEvent, node: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var type = node.get_meta("node_type")
		var index: int = int(node.get_meta("node_index", 0))

		if type == "BATTLE":
			if RunState.fragment_deck_count() <= 0:
				RunState.autofill_fragment_deck()
			RunState.pending_encounter_band = _band_for_index(index)
			get_tree().change_scene_to_file("res://scenes/battle/battle_scene_template.tscn")
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
