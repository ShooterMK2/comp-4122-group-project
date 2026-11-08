class_name AssetLookup
extends RefCounted

const CHARACTER_DIRS := [                    # new art folders must be added here
	"res://assets/player/",
	"res://assets/characters/",
	"res://assets/enemies/",
	"res://assets/textures/characters/",
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
