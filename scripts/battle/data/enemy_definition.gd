class_name EnemyDefinition
extends CombatantDefinition

# Enemy actions. They skip the casting board, so pattern/requirements are ignored.
# One spell per round, cycling in order.
@export var spells: Array[SpellDefinition] = []

static func wooden_dummy() -> EnemyDefinition:
	return wooden_dummy_variant(0)

static func wooden_dummy_variant(index: int) -> EnemyDefinition:
	var paths := [
		"res://resources/enemies/wooden_dummy_fire.tres",
		"res://resources/enemies/wooden_dummy_ice.tres",
		"res://resources/enemies/wooden_dummy_lightning.tres",
	]
	var path: String = paths[clampi(index, 0, paths.size() - 1)]
	var d := load(path) as EnemyDefinition
	if d == null:
		push_error("Unable to load enemy definition resource: %s" % path)
		return EnemyDefinition.new()
	d = d.duplicate(true) as EnemyDefinition
	d.spells.append(EnemySpellLibrary.mend(BattleConfig.DUMMY_HEAL_PER_TURN))
	return d