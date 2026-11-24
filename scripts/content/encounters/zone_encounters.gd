class_name ZoneEncounters
extends RefCounted

## Zone 1 authored encounters by level band (enemy levels 1–20).

static func for_zone(zone_id: int, band: StringName = &"mid") -> Array[EnemyDefinition]:
	if zone_id == ZoneConfig.ZONE_1:
		return zone1(band)
	return zone1(band)

static func zone1(band: StringName = &"mid") -> Array[EnemyDefinition]:
	match String(band):
		"early":
			return _pack([_tuned_dummy(0, 2), _tuned_dummy(1, 3)])
		"late":
			return _pack([_tuned_hound(18), _tuned_dummy(2, 14), _tuned_dummy(0, 12)])
		_:
			return _pack([_tuned_hound(8), _tuned_dummy(0, 6), _tuned_dummy(1, 7)])

static func _pack(enemies: Array) -> Array[EnemyDefinition]:
	var out: Array[EnemyDefinition] = []
	for e in enemies:
		out.append(e)
	return out

static func _apply_level(def: EnemyDefinition, level: int) -> EnemyDefinition:
	var stats := LevelProgression.suggest_enemy_stats(level)
	def.level = int(stats["level"])
	def.max_hp = int(stats["max_hp"])
	def.attack = int(stats["attack"])
	def.defence = int(stats["defence"])
	def.speed = float(stats["speed"])
	return def

static func _tuned_dummy(variant: int, level: int) -> EnemyDefinition:
	return _apply_level(EnemyDefinition.wooden_dummy_variant(variant), level)

static func _tuned_hound(level: int) -> EnemyDefinition:
	return _apply_level(EnemyDefinition.ash_hound(), level)
