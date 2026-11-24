class_name BattleWorld
extends Node2D
# The 2D stage. The two ReferenceRect zones in battlefield.tscn decide where
# the player and the enemies stand; this script only reads them (via layout()).

const ENEMY_SPACING_MAX := 170.0        # TUNABLE: widest gap between enemy centres
const PLAYER_HEIGHT := 100.0
const ENEMY_HEIGHT := 80.0
const ENEMY_SCENE := preload("res://scenes/battle/ui/enemy_actor.tscn")

@onready var player_actor: Actor = $Actors/Player
@onready var actors: Node2D = $Actors
@onready var _floor: Sprite2D = $Floor

var enemy_actors: Array[EnemyActor] = []
var ground_y := 0.0
var enemy_spacing := ENEMY_SPACING_MAX
var _world_size := Vector2(1280.0, 360.0)


func spawn_enemies(defs: Array[EnemyDefinition]) -> void:
	for a in enemy_actors:
		a.queue_free()
	enemy_actors.clear()
	if defs.size() > EncounterDefinition.MAX_ENEMIES:
		push_warning("More than %d enemies: the extras are not drawn." % EncounterDefinition.MAX_ENEMIES)
	for i in mini(defs.size(), EncounterDefinition.MAX_ENEMIES):
		var a: EnemyActor = ENEMY_SCENE.instantiate()
		a.name = "Enemy%d" % (i + 1)
		actors.add_child(a)
		a.setup_enemy(defs[i], ENEMY_HEIGHT)
		enemy_actors.append(a)


# Zones are Rect2s in world (SubViewport) pixels. Their bottom edge is the feet line.
func layout(world_size: Vector2, player_zone: Rect2, enemy_zone: Rect2) -> void:
	_world_size = world_size
	ground_y = player_zone.end.y
	player_actor.position = Vector2(player_zone.get_center().x, ground_y)
	var n := enemy_actors.size()
	if n > 0:
		enemy_spacing = minf(enemy_zone.size.x / float(n), ENEMY_SPACING_MAX)
		for i in n:
			enemy_actors[i].position = Vector2(
				enemy_zone.get_center().x + (i - (n - 1) / 2.0) * enemy_spacing,
				enemy_zone.end.y)
	_fit_floor()


func set_floor(tex: Texture2D) -> void:
	_floor.texture = tex
	_floor.visible = tex != null
	_fit_floor()


# Tiles the floor texture across the width and squashes it into the strip under the zones.
func _fit_floor() -> void:
	if _floor.texture == null:
		return
	var tex_h := float(_floor.texture.get_height())
	_floor.centered = false
	_floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_floor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_floor.region_enabled = true
	_floor.region_rect = Rect2(0.0, 0.0, _world_size.x, tex_h)
	_floor.position = Vector2(0.0, ground_y)
	_floor.scale = Vector2(1.0, maxf(_world_size.y - ground_y, 1.0) / tex_h)
