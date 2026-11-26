class_name EncounterDefinition
extends Resource
# Level data: one .tres per battle in res://resources/encounters/.
# Add enemies in the inspector (one entry per enemy on the field). Stats live in each EnemyDefinition.

const MAX_ENEMIES := 6                 # TUNABLE: the battlefield lays out up to this many

@export var id: String = ""
@export var terrain_id: String = ""    # "forest", "volcano", "plain". Empty = random terrain
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
	return TerrainSystem.by_id(terrain_id)

static func load_encounter(path: String) -> EncounterDefinition:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as EncounterDefinition