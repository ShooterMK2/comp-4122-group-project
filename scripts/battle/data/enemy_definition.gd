class_name EnemyDefinition
extends Resource

@export var display_name: String = "Enemy"
@export var max_hp: int = 50
@export var speed: float = 10.0
@export var art_name: String = ""
@export var placeholder_color: Color = Color(0.5, 0.4, 0.3)
# Enemy actions. They skip the casting board, so pattern/requirements are ignored.
# One spell per round, cycling in order.
@export var spells: Array[SpellDefinition] = []

static func wooden_dummy() -> EnemyDefinition:
	var d := EnemyDefinition.new()
	d.display_name = "Wooden Dummy"
	d.max_hp = 60
	d.speed = BattleConfig.DUMMY_BASE_SPEED
	d.art_name = BattleConfig.DUMMY_ART
	d.placeholder_color = Color(0.55, 0.4, 0.25)
	d.spells.append(EnemySpellLibrary.mend(BattleConfig.DUMMY_HEAL_PER_TURN))
	return d