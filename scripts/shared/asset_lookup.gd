class_name AssetLookup
extends RefCounted

const CHARACTER_DIRS := [                    # new art folders must be added here
	"res://assets/player/",
	"res://assets/characters/",
	"res://assets/enemies/",
	"res://assets/textures/characters/",
]
const ENV_DIR := "res://assets/textures/environments/"
const ENV_FALLBACK_ID := "cave"              # used when a terrain has no art yet
const LEGACY_BACKGROUND := "res://assets/textures/environments/ComfyUI_temp_zhdlv_00027_.png"
const STATUS_ICON_DIRS := [
	"res://assets/textures/status/",
	"res://assets/textures/ui/status/",
]
const EXTENSIONS := ["png", "webp"]

static func character(art_name: String) -> Texture2D:
	if art_name == "":
		return null
	var base := art_name.get_basename()      # tolerates "name.png"
	for dir in CHARACTER_DIRS:
		for ext in EXTENSIONS:
			var path := "%s%s.%s" % [dir, base, ext]
			if ResourceLoader.exists(path):
				return load(path)
	return null

# "Forest" -> "forest". Files: <id>_background.png, <id>_floor.png (or <id>_floor_1.png).
static func terrain_id(display_name: String) -> String:
	return display_name.strip_edges().to_snake_case()

static func background(tid: String) -> Texture2D:
	var tex := _environment(tid, ["background", "bg"])
	if tex == null and ResourceLoader.exists(LEGACY_BACKGROUND):
		tex = load(LEGACY_BACKGROUND)
	return tex

static func floor_texture(tid: String) -> Texture2D:
	return _environment(tid, ["floor", "floor_1"])

# Status icon by snake_case name, e.g. "burn" -> status_burn.png or burn.png.
static func status_icon(key: String) -> Texture2D:
	var paths: Array[String] = []
	for dir in STATUS_ICON_DIRS:
		for ext in EXTENSIONS:
			paths.append("%sstatus_%s.%s" % [dir, key, ext])
			paths.append("%s%s.%s" % [dir, key, ext])
	return _first_existing(paths)

static func _environment(tid: String, kinds: Array) -> Texture2D:
	var paths: Array[String] = []
	for id in [tid, ENV_FALLBACK_ID]:
		for kind in kinds:
			for ext in EXTENSIONS:
				paths.append("%s%s_%s.%s" % [ENV_DIR, id, kind, ext])
	return _first_existing(paths)

static func _first_existing(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null
