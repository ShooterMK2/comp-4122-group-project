class_name EnemyDefinition
extends Resource

@export var display_name: String = "Enemy"
@export var max_hp: int = 50
@export var attack_damage: int = 0       # 0 = never attacks
@export var heavy_every: int = 0         # every Nth turn deals 2x (0 = never)
@export var art_name: String = ""        # file name(without extension) of the art to use for this enemy
@export var placeholder_color: Color = Color(0.5, 0.4, 0.3)

static func wooden_dummy() -> EnemyDefinition:
	var d := EnemyDefinition.new()
	d.display_name = "Wooden Dummy"
	d.max_hp = 60
	d.attack_damage = 0
	d.heavy_every = 0
	d.art_name = "enemy_wooden_dummy"
	d.placeholder_color = Color(0.55, 0.4, 0.25)
	return d
