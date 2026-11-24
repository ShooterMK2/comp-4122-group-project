class_name IconLookup
extends RefCounted

const ITEM_DIR := "res://assets/icons/items/"
const SPELL_DIR := "res://assets/icons/spells/"
const KEY_THRESHOLD := 48.0  # TUNABLE: higher = more aggressive background removal

static var _cache := {}
static var _clear_cache := {}

static func load_tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_cache[path] = tex
		return tex
	return null

static func load_tex_clear(path: String) -> Texture2D:
	if _clear_cache.has(path):
		return _clear_cache[path]
	var src := load_tex(path)
	if src == null:
		return null
	var cleared := make_background_transparent(src)
	_clear_cache[path] = cleared
	return cleared

static func for_item_id(id: StringName) -> Texture2D:
	return load_tex_clear(ITEM_DIR + String(id) + ".png")

static func fragment() -> Texture2D:
	return load_tex_clear(ITEM_DIR + "fragment.png")

static func spell() -> Texture2D:
	return load_tex_clear(SPELL_DIR + "spell.png")

static func panel_bg() -> Texture2D:
	return load_tex("res://assets/ui/inventory/panel_bg.png")

## Autokey near-corner / near-white studio backgrounds to alpha (4B).
static func make_background_transparent(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	if w < 2 or h < 2:
		return tex
	var key := _average_corner_color(img, w, h)
	# Prefer light studio backdrops when corners disagree.
	if key.get_luminance() < 0.55:
		key = Color(0.92, 0.9, 0.86, 1.0)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if _color_distance(c, key) <= KEY_THRESHOLD:
				c.a = 0.0
				img.set_pixel(x, y, c)
	var out := ImageTexture.create_from_image(img)
	return out

static func _average_corner_color(img: Image, w: int, h: int) -> Color:
	var samples: Array[Color] = [
		img.get_pixel(0, 0),
		img.get_pixel(w - 1, 0),
		img.get_pixel(0, h - 1),
		img.get_pixel(w - 1, h - 1),
		img.get_pixel(mini(2, w - 1), mini(2, h - 1)),
	]
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for c in samples:
		r += c.r
		g += c.g
		b += c.b
	var n := float(samples.size())
	return Color(r / n, g / n, b / n, 1.0)

static func _color_distance(a: Color, b: Color) -> float:
	var dr := (a.r - b.r) * 255.0
	var dg := (a.g - b.g) * 255.0
	var db := (a.b - b.b) * 255.0
	return sqrt(dr * dr + dg * dg + db * db)
