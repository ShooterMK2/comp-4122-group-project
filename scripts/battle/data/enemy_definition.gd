class_name EnemyDefinition
extends CombatantDefinition

enum Rank { MINOR, ELITE, BOSS }

@export var rank: Rank = Rank.MINOR

# Enemy turn actions (skills). One skill per action, cycling in list order.
# Author on the .tres; factories only load + duplicate.
@export var skills: Array[SkillDefinition] = []

## Kind bias applied after level curve (1.0 = average). Used for role fantasy.
@export var hp_mult: float = 1.0
@export var attack_mult: float = 1.0
@export var defence_mult: float = 1.0
@export var speed_mult: float = 1.0

static func _load_enemy(path: String) -> EnemyDefinition:
	var d := load(path) as EnemyDefinition
	if d == null:
		push_error("Unable to load enemy definition resource: %s" % path)
		return EnemyDefinition.new()
	return d.duplicate(true) as EnemyDefinition

static func wooden_dummy() -> EnemyDefinition:
	return wooden_dummy_variant(0)

static func wooden_dummy_variant(index: int) -> EnemyDefinition:
	var paths := [
		"res://resources/enemies/wooden_dummy_fire.tres",
		"res://resources/enemies/wooden_dummy_ice.tres",
		"res://resources/enemies/wooden_dummy_lightning.tres",
	]
	return _load_enemy(paths[clampi(index, 0, paths.size() - 1)])

static func human_bandit() -> EnemyDefinition:
	return MinorEnemyLibrary.human_bandit().duplicate(true) as EnemyDefinition
