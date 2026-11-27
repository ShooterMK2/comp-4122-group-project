class_name TerrainSystem
extends RefCounted

const E := Elements.Element
const T := TerrainDefinition.Stat
const L := BattleConfig.TERRAIN_MULT_LOW
const M := BattleConfig.TERRAIN_MULT_MEDIUM
const H := BattleConfig.TERRAIN_MULT_HIGH

const PRIMARY_IDS: Array[String] = ["None", "Snow", "Forest", "Desert", "Volcano"]
const SECONDARY_IDS: Array[String] = [
	"Mountain", "Waterside", "Clearing", "Ruins", "Cave", "Indoor", "City",
]

const ALLOWED_SECONDARIES := {
	"None": ["Clearing", "Ruins", "Indoor", "Mountain", "City"],
	"Snow": ["Mountain", "Waterside", "Cave", "Clearing", "Ruins", "City"],
	"Forest": ["Mountain", "Waterside", "Clearing", "Ruins", "Cave"],
	"Desert": ["Mountain", "Ruins", "Indoor", "Clearing", "City"],
	"Volcano": ["Mountain", "Cave", "Ruins"],
}

static func primary(id: String) -> TerrainDefinition:
	var key := _normalize_primary(id)
	match key:
		"None":
			return TerrainDefinition.make("None", [
				_atk(E.WIND, L),
				_def(L),
			], key)
		"Snow":
			return TerrainDefinition.make("Snow", [
				_atk(E.ICE, M),
				_atk(E.WIND, L),
				_atk(E.FIRE, -M),
			], key)
		"Forest":
			return TerrainDefinition.make("Forest", [
				_atk(E.WIND, L),
				_atk(E.EARTH, M),
				_atk(E.FIRE, -L),
				_atk(E.ICE, -L),
				_spd(L),
			], key)
		"Desert":
			return TerrainDefinition.make("Desert", [
				_atk(E.FIRE, M),
				_atk(E.EARTH, L),
				_atk(E.ICE, -M),
				_atk(E.WIND, -L),
			], key)
		"Volcano":
			return TerrainDefinition.make("Volcano", [
				_atk(E.FIRE, H),
				_atk(E.WIND, L),
				_atk(E.ICE, -M),
				_def(-L),
			], key)
	return primary("None")

static func secondary(id: String) -> TerrainDefinition:
	var key := _normalize_secondary(id)
	match key:
		"Mountain":
			return TerrainDefinition.make("Mountain", [
				_atk(E.WIND, M),
				_def(L),
				_spd(L),
				_atk(E.LIGHTNING, -L),
			], "", key)
		"Waterside":
			return TerrainDefinition.make("Waterside", [
				_atk(E.ICE, M),
				_atk(E.LIGHTNING, L),
				_atk(E.FIRE, -M),
				_atk(E.EARTH, -L),
			], "", key)
		"Clearing":
			return TerrainDefinition.make("Clearing", [
				_atk(E.WIND, L),
				_atk(E.ICE, L),
				_atk(E.DARK, -L),
			], "", key)
		"Ruins":
			return TerrainDefinition.make("Ruins", [
				_atk(E.DARK, M),
				_atk(E.EARTH, L),
				_atk(E.WIND, -L),
				_def(-L),
			], "", key)
		"Cave":
			return TerrainDefinition.make("Cave", [
				_atk(E.EARTH, M),
				_atk(E.DARK, L),
				_def(L),
				_atk(E.WIND, -M),
				_spd(-L),
			], "", key)
		"Indoor":
			return TerrainDefinition.make("Indoor", [
				_def(L),
				_atk(E.LIGHTNING, L),
				_atk(E.WIND, -M),
				_atk(E.FIRE, -L),
			], "", key)
		"City":
			return TerrainDefinition.make("City", [
				_atk(E.LIGHTNING, M),
				_atk(E.DARK, L),
				_def(L),
				_atk(E.EARTH, -L),
				_atk(E.WIND, -L),
			], "", key)
	return secondary("Clearing")

static func allowed_secondaries(primary_id: String) -> Array[String]:
	var key := _normalize_primary(primary_id)
	var raw: Array = ALLOWED_SECONDARIES.get(key, ALLOWED_SECONDARIES["None"])
	var out: Array[String] = []
	for s in raw:
		out.append(str(s))
	return out

static func pick_secondary(primary_id: String) -> String:
	var allowed := allowed_secondaries(primary_id)
	if allowed.is_empty():
		return "Clearing"
	return allowed.pick_random()

static func compose(primary_id: String, secondary_id: String) -> TerrainDefinition:
	var p := primary(primary_id)
	var allowed := allowed_secondaries(p.primary_id)
	var sid := _normalize_secondary(secondary_id)
	if sid not in allowed:
		sid = allowed[0] if not allowed.is_empty() else "Clearing"
	var s := secondary(sid)
	var mods: Array[Dictionary] = []
	mods.append_array(p.modifiers)
	mods.append_array(s.modifiers)
	var name := "%s · %s" % [p.display_name, s.display_name]
	return TerrainDefinition.make(name, mods, p.primary_id, s.secondary_id)

static func by_ids(primary_id: String, secondary_id: String) -> TerrainDefinition:
	return compose(primary_id, secondary_id)

## Legacy single-id lookup for old encounter resources.
static func by_id(id: String) -> TerrainDefinition:
	var key := id.strip_edges()
	if key.is_empty():
		return compose("None", "Clearing")
	match key.to_lower():
		"forest":
			return compose("Forest", pick_secondary("Forest"))
		"volcano":
			return compose("Volcano", pick_secondary("Volcano"))
		"plain", "none", "clearing":
			return compose("None", "Clearing")
		"snow":
			return compose("Snow", pick_secondary("Snow"))
		"desert":
			return compose("Desert", pick_secondary("Desert"))
	# Treat as primary if known, else None · Clearing
	for p in PRIMARY_IDS:
		if p.to_lower() == key.to_lower():
			return compose(p, pick_secondary(p))
	for s in SECONDARY_IDS:
		if s.to_lower() == key.to_lower():
			return compose("None", s)
	return compose("None", "Clearing")

static func random_terrain() -> TerrainDefinition:
	var p: String = PRIMARY_IDS.pick_random()
	return compose(p, pick_secondary(p))

static func plain() -> TerrainDefinition:
	return compose("None", "Clearing")

static func _normalize_primary(id: String) -> String:
	var key := id.strip_edges()
	if key.is_empty():
		return "None"
	for p in PRIMARY_IDS:
		if p.to_lower() == key.to_lower():
			return p
	return "None"

static func _normalize_secondary(id: String) -> String:
	var key := id.strip_edges()
	if key.is_empty():
		return "Clearing"
	for s in SECONDARY_IDS:
		if s.to_lower() == key.to_lower():
			return s
	return "Clearing"

static func _atk(element: int, delta: float) -> Dictionary:
	return {"element": element, "stat": T.ATTACK, "delta": delta, "player_only": true}

static func _def(delta: float) -> Dictionary:
	return {"element": E.NONE, "stat": T.DEFENCE, "delta": delta, "player_only": true}

static func _spd(delta: float) -> Dictionary:
	return {"element": E.NONE, "stat": T.SPEED, "delta": delta, "player_only": true}
