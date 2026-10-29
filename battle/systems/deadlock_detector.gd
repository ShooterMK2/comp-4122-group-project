class_name DeadlockDetector
extends RefCounted

# Deadlocked = the hand has fragments, and none fits anywhere in any rotation.
static func is_deadlocked(board: CastingBoardModel, hand: Array[FragmentData]) -> bool:
	if hand.is_empty():
		return false
	for f in hand:
		if can_fit_anywhere(board, f):
			return false
	return true

static func can_fit_anywhere(board: CastingBoardModel, f: FragmentData) -> bool:
	var frag := f
	for rotation in 4:
		for y in board.size.y:
			for x in board.size.x:
				if board.can_place(frag, Vector2i(x, y)):
					return true
		frag = frag.rotated_cw()
	return false