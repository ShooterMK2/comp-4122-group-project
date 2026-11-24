class_name TestEncounter
extends RefCounted

## Legacy helper — forwards to Zone 1 mid band.
static func enemies() -> Array[EnemyDefinition]:
	return ZoneEncounters.zone1(&"mid")
