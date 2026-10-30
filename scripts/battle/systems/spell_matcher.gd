class_name SpellMatcher
extends RefCounted

# Returns {spell, cells, elements} for the first match, or {} if none.
static func find_first_match(board: CastingBoardModel, spells: Array[SpellDefinition]) -> Dictionary:
	var sorted := spells.duplicate()
	sorted.sort_custom(func(a, b): return a.pattern.cells.size() > b.pattern.cells.size())
	for spell: SpellDefinition in sorted:
		for y in board.size.y:
			for x in board.size.x:
				var hit := _try_at(board, spell, Vector2i(x, y))
				if not hit.is_empty():
					return hit
	return {}

static func _try_at(board: CastingBoardModel, spell: SpellDefinition, anchor: Vector2i) -> Dictionary:
	var cells: Array[Vector2i] = []
	var elems: Array[int] = []
	for c in spell.pattern.cells:
		var p := anchor + c
		if not board.in_bounds(p) or board.is_empty(p):
			return {}
		cells.append(p)
		elems.append(board.get_tile(p))
	if not _meets_requirements(spell, elems):
		return {}
	return {"spell": spell, "cells": cells, "elements": elems}

static func _meets_requirements(spell: SpellDefinition, elems: Array[int]) -> bool:
	var wild := elems.count(Elements.Element.UNIVERSAL)
	var wild_needed := 0
	for req in spell.requirements:
		wild_needed += maxi(0, req.min_count - elems.count(req.element))
	return wild_needed <= wild
