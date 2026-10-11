class_name BattleTypes
extends RefCounted

enum Element { NONE, UNIVERSAL, FIRE, ICE, EARTH, WIND, LIGHTNING, DARK }

const EMPTY := -1
const BOARD_SIZE := Vector2i(5, 5)

const COLORS := {
	Element.NONE: Color(0.6, 0.6, 0.6),
	Element.UNIVERSAL: Color(0.95, 0.9, 0.4),
	Element.FIRE: Color(0.95, 0.35, 0.2),
	Element.ICE: Color(0.4, 0.75, 1.0),
	Element.EARTH: Color(0.55, 0.4, 0.2),
	Element.WIND: Color(0.6, 0.95, 0.7),
	Element.LIGHTNING: Color(0.8, 0.5, 1.0),
	Element.DARK: Color(0.35, 0.2, 0.5),
}

static func color_of(e: int) -> Color:
	return COLORS.get(e, Color(0.2, 0.2, 0.2))

static func name_of(e: int) -> String:
	return Element.keys()[e].capitalize()

static func letter_of(e: int) -> String:
	return "·" if e == EMPTY else Element.keys()[e].substr(0, 1)
