class_name TurnDeck
extends RefCounted
# The player's hand for the current turn on top of the fragment deck's draw/discard piles.
# Rules: a placed fragment goes to the discard pile at once; fragments still in hand when the
# turn ends are discarded too. FragmentDeckDraw reshuffles the discard pile when it runs dry.

var hand: Array[FragmentData] = []
var _draw: FragmentDeckDraw


func _init(p_draw: FragmentDeckDraw) -> void:
	_draw = p_draw


func draw_hand(count: int) -> void:
	hand = _draw.draw(count)


func draw_extra(count: int) -> void:
	hand.append_array(_draw.draw(count))


func fragment_at(index: int) -> FragmentData:
	if index < 0 or index >= hand.size():
		return null
	return hand[index]


func play(index: int) -> void:
	if index < 0 or index >= hand.size():
		return
	var fragment := hand[index]
	hand.remove_at(index)
	_draw.discard(fragment)


func rotate_at(index: int) -> void:
	if index >= 0 and index < hand.size():
		hand[index] = hand[index].rotated_cw()


func end_turn() -> void:
	_draw.discard_many(hand)
	hand.clear()


func draw_pile_size() -> int:
	return _draw.draw_pile.size()


func discard_pile_size() -> int:
	return _draw.discard_pile.size()
