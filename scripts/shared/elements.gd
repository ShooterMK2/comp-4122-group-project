class_name Elements
extends RefCounted

enum Element { NONE, UNIVERSAL, FIRE, ICE, EARTH, WIND, LIGHTNING, DARK }

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

const TILE_DIRS := [
	"res://assets/texture/tiles/",
	"res://assets/textures/tiles/",
]

# Edit these if your tile_xx names differ (e.g. "tile_flame").
const TILE_ALIASES := {
	Element.NONE: ["none", "00"],
	Element.UNIVERSAL: ["universal", "wild", "01"],
	Element.FIRE: ["fire", "02"],
	Element.ICE: ["ice", "03"],
	Element.EARTH: ["earth", "04"],
	Element.WIND: ["wind", "05"],
	Element.LIGHTNING: ["lightning", "06"],
	Element.DARK: ["dark", "07"],
}

static var _tex_cache := {}

static func is_valid(e: int) -> bool:
	return e >= 0 and e < Element.size()

static func color_of(e: int) -> Color:
	return COLORS.get(e, Color(0.2, 0.2, 0.2))

static func name_of(e: int) -> String:
	return Element.keys()[e].capitalize() if is_valid(e) else "Empty"

static func letter_of(e: int) -> String:
	return Element.keys()[e].substr(0, 1) if is_valid(e) else "·"

static func texture_of(e: int) -> Texture2D:
	if not is_valid(e):
		return null
	if _tex_cache.has(e):
		return _tex_cache[e]
	var tex: Texture2D = null
	for dir in TILE_DIRS:
		for alias in TILE_ALIASES.get(e, []):
			var path: String = "%stile_%s.png" % [dir, alias]
			if ResourceLoader.exists(path):
				tex = load(path)
				break
		if tex:
			break
	if tex == null:
		push_warning("No tile texture found for %s" % name_of(e))
	_tex_cache[e] = tex
	return tex