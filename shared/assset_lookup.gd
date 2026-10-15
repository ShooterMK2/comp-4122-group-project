class_name AssetLookup
extends RefCounted

const CHARACTER_DIRS := [  #If you create new folders for art, remember to add them here
	"res://assets/player",
	"res://assets/enemies/",
	"res://assets/textures/characters/",
]
const EXTENSIONS := ["png", "webp"]

# Returns null if the art does not exist yet (views then show a placeholder).
static func character(art_name: String) -> Texture2D:
	if art_name == "":
		return null
	for dir in CHARACTER_DIRS:
		for ext in EXTENSIONS:
			var path := "%s%s.%s" % [dir, art_name, ext]
			if ResourceLoader.exists(path):
				return load(path)
	return null
