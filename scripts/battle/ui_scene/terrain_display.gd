class_name TerrainDisplay
extends PanelContainer
# Terrain name label + icon chip. Hover the chip for the terrain's modifiers.

# TODO: set to the folder holding your terrain icons, named <terrain name lowercase>.png/.webp
# (for example plain.png, forest.png, volcano.png). Without a file the chip shows a letter.
const ICON_DIR := "res://assets/ui/terrain/"
const EXTENSIONS := ["png", "webp"]
const FALLBACK_COLOR := Color(0.3, 0.45, 0.3)

@onready var _chip: HoverIcon = %TerrainChip


func show_terrain(terrain: TerrainDefinition) -> void:
	_chip.show_art(_icon_for(terrain.display_name), terrain.display_name.left(1), FALLBACK_COLOR)
	var lines: Array[String] = []
	var text := terrain.description()
	if text.is_empty():
		lines.append("No modifiers.")
	else:
		for part in text.split(", "):
			lines.append(part)
	_chip.set_details(terrain.display_name, lines)


func _icon_for(terrain_name: String) -> Texture2D:
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [ICON_DIR, terrain_name.to_lower(), ext]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
