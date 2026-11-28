class_name ZoneEncounters
extends RefCounted

## Zone 1 encounters: minor pools by primary terrain, dummy placeholders for elite/boss,
## bandit packs for karma / override.

const PRIMARY_LEVEL_BANDS := {
	"None": Vector2i(1, 4),
	"Snow": Vector2i(4, 8),
	"Forest": Vector2i(8, 12),
	"Desert": Vector2i(12, 16),
	"Volcano": Vector2i(16, 20),
}

static func for_zone(_zone_id: int, _band: StringName = &"mid") -> Array[EnemyDefinition]:
	return build_pending_encounter()

static func build_pending_encounter() -> Array[EnemyDefinition]:
	# Prefer autoload RunState when playing.
	var rs = null
	if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
		rs = Engine.get_main_loop().root.get_node_or_null("RunState")
	if rs == null:
		return for_terrain("None")
	if rs.pending_encounter_override == &"bandit":
		return bandit_pack(str(rs.pending_primary_terrain))
	var tier: StringName = rs.pending_encounter_tier
	if tier == &"elite" or tier == &"boss":
		return dummy_placeholder_pack(str(rs.pending_primary_terrain), tier)
	return for_terrain(str(rs.pending_primary_terrain))

static func for_terrain(primary: String) -> Array[EnemyDefinition]:
	var pool := MinorEnemyLibrary.pool_for_primary(primary)
	var level := roll_level_for_primary(primary)
	var size := 2 if randf() < 0.55 else 3
	var out: Array[EnemyDefinition] = []
	for _i in size:
		var pick: EnemyDefinition = pool[randi() % pool.size()].duplicate(true) as EnemyDefinition
		out.append(_apply_level(pick, level))
	return out

static func bandit_pack(primary: String) -> Array[EnemyDefinition]:
	var level := roll_level_for_primary(primary)
	var size := 2 if randf() < 0.55 else 3
	var out: Array[EnemyDefinition] = []
	for _i in size:
		out.append(_apply_level(MinorEnemyLibrary.human_bandit().duplicate(true) as EnemyDefinition, level))
	return out

static func dummy_placeholder_pack(primary: String, tier: StringName = &"elite") -> Array[EnemyDefinition]:
	var level := roll_level_for_primary(primary)
	var size := 2 if randf() < 0.55 else 3
	var out: Array[EnemyDefinition] = []
	for i in size:
		var d := EnemyDefinition.wooden_dummy_variant(i % 3)
		if tier == &"boss":
			d.rank = EnemyDefinition.Rank.BOSS
			d.display_name = "Wooden Dummy (Boss Placeholder)"
		elif tier == &"elite":
			d.rank = EnemyDefinition.Rank.ELITE
			d.display_name = "Wooden Dummy (Elite Placeholder)"
		out.append(_apply_level(d, level))
	return out

static func roll_level_for_primary(primary: String) -> int:
	var key := primary.strip_edges()
	if key.is_empty():
		key = "None"
	var band: Vector2i = PRIMARY_LEVEL_BANDS.get(key, PRIMARY_LEVEL_BANDS["None"])
	return randi_range(band.x, band.y)

static func _apply_level(def: EnemyDefinition, level: int) -> EnemyDefinition:
	var stats := LevelProgression.suggest_enemy_stats(level)
	# Per-kind bias × light per-spawn jitter so same kind still varies a bit.
	var j_hp := randf_range(0.92, 1.08)
	var j_atk := randf_range(0.90, 1.10)
	var j_def := randf_range(0.90, 1.10)
	var j_spd := randf_range(0.92, 1.08)
	def.level = int(stats["level"])
	def.max_hp = maxi(1, int(round(float(stats["max_hp"]) * def.hp_mult * j_hp)))
	def.attack = maxi(1, int(round(float(stats["attack"]) * def.attack_mult * j_atk)))
	def.defence = maxi(0, int(round(float(stats["defence"]) * def.defence_mult * j_def)))
	def.speed = maxf(0.5, float(stats["speed"]) * def.speed_mult * j_spd)
	return def
