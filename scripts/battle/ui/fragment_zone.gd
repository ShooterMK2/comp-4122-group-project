class_name FragmentZone
extends HFlowContainer

signal card_selected(index: int)
signal card_rotate(index: int)
signal card_drag_started(index: int)

func _init() -> void:
	custom_minimum_size = Vector2(0, 110)
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)

func show_hand(hand: Array, selected: int) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for i in hand.size():
		var card := FragmentCard.new()
		card.setup(i, hand[i], i == selected)
		card.card_pressed.connect(_on_card_pressed)
		card.rotate_requested.connect(_on_card_rotate)
		card.drag_started.connect(_on_card_drag_started)
		add_child(card)

func _on_card_pressed(i: int) -> void:
	card_selected.emit(i)

func _on_card_rotate(i: int) -> void:
	card_rotate.emit(i)

func _on_card_drag_started(i: int) -> void:
	card_drag_started.emit(i)
