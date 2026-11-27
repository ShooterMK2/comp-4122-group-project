class_name EncounterDefinition
extends Resource
# Level data: one .tres per battle in res://resources/encounters/.
# Add enemies in the inspector (one entry per enemy on the field). Stats live in each EnemyDefinition.

const MAX_ENEMIES := 6                 # TUNABLE: the battlefield lays out up to this many

@export var id: String = ""
@export var primary_terrain_id: String = ""   # None/Snow/Forest/Desert/Volcano. Empty → RunState or None
@export var secondary_terrain_id: String = "" # Mountain/Waterside/... Empty → Clearing (or RunState)
@export var terrain_id: String = ""           # DEPRECATED: legacy single id; used if primary empty
@export var enemies: Array[EnemyDefinition] = []

func make_enemies() -> Array[EnemyDefinition]:
	var out: Array[EnemyDefinition] = []
	for d in enemies:
		if d == null:
			continue
		if out.size() >= MAX_ENEMIES:
			push_warning("Encounter '%s' has more than %d enemies; extras are ignored." % [id, MAX_ENEMIES])
			break
		out.append(d.duplicate(true) as EnemyDefinition)
	return out

func make_terrain() -> TerrainDefinition:
	var primary := primary_terrain_id.strip_edges()
	var secondary := secondary_terrain_id.strip_edges()
	if primary.is_empty() and not terrain_id.strip_edges().is_empty():
		return TerrainSystem.by_id(terrain_id)
	if primary.is_empty() and secondary.is_empty():
		# Prefer pending map terrain when the encounter leaves both blank.
		if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
			var rs = Engine.get_main_loop().root.get_node_or_null("RunState")
			if rs != null:
				return TerrainSystem.compose(
						str(rs.pending_primary_terrain), str(rs.pending_secondary_terrain))
		return TerrainSystem.compose("None", "Clearing")
	if primary.is_empty():
		primary = "None"
	if secondary.is_empty():
		secondary = "Clearing"
	return TerrainSystem.compose(primary, secondary)

static func load_encounter(path: String) -> EncounterDefinition:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as EncounterDefinition
