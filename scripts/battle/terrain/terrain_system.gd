class_name TerrainSystem
extends RefCounted

const E := Elements.Element
const T := TerrainDefinition.Stat

static func forest() -> TerrainDefinition:
	return TerrainDefinition.make("Forest", [
		_modifier(E.WIND, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_LOW),
		_modifier(E.WIND, T.SPEED, BattleConfig.OTHER_MULTIPLIER_LOW, true),
		_modifier(E.EARTH, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_MEDIUM),
		_modifier(E.FIRE, T.ATTACK, -BattleConfig.OTHER_MULTIPLIER_LOW),
		_modifier(E.ICE, T.ATTACK, -BattleConfig.OTHER_MULTIPLIER_LOW),
	])

static func volcano() -> TerrainDefinition:
	return TerrainDefinition.make("Volcano", [
		_modifier(E.FIRE, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_HIGH),
		_modifier(E.ICE, T.ATTACK, -BattleConfig.OTHER_MULTIPLIER_MEDIUM),
		_modifier(E.WIND, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_LOW),
	])

static func plain() -> TerrainDefinition:
	return TerrainDefinition.make("Plain", [
		_modifier(E.WIND, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_MEDIUM),
		_modifier(E.ICE, T.ATTACK, BattleConfig.OTHER_MULTIPLIER_MEDIUM),
		_modifier(E.FIRE, T.ATTACK, -BattleConfig.OTHER_MULTIPLIER_LOW),
	])

static func random_terrain() -> TerrainDefinition:
	return [forest(), volcano(), plain()].pick_random()

static func _modifier(element: int, stat: T, delta: float,
		player_only: bool = false) -> Dictionary:
	return {"element": element, "stat": stat, "delta": delta,
		"player_only": player_only}