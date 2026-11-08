class_name HandZone
extends HFlowContainer
# A pool of 8 HandCard slots. Fills them from the hand. Never creates nodes.

signal card_selected(index: int)
signal card_rotate(index: int)
signal card_drag_started(index: int)

@onready var _cards: Array[Node] = get_children()

func _ready() -> void:
	for card: HandCard in _cards:
		card.card_pressed.connect(func(i: int): card_selected.emit(i))
		card.rotate_requested.connect(func(i: int): card_rotate.emit(i))
		card.drag_started.connect(func(i: int): card_drag_started.emit(i))

func show_hand(hand: Array, selected: int) -> void:
	if hand.size() > _cards.size():
		push_warning("HandZone: %d fragments but only %d card slots" % [hand.size(), _cards.size()])
	for i in _cards.size():
		var card: HandCard = _cards[i]
		if i < hand.size():
			card.show_fragment(i, hand[i], i == selected)
		else:
			card.hide_card()
