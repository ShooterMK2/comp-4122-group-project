class_name _Battlefield
extends Control
# Main controller of the Battlefield node.
# Right now it builds the level from an EncounterDefinition.

signal enemy_clicked(index: int)
signal spell_dropped_on(target_index: int, definition: SpellDefinition)

var _drop_enabled := false

const ENEMY_SCENE := preload("res://scenes/battle/ui/enemy_actor.tscn")


@export var encounter: EncounterDefinition

@onready var _enemy_slots: HBoxContainer = %EnemySlots


func _ready() -> void:
	if encounter != null:
		load_encounter(encounter)


func load_encounter(data: EncounterDefinition) -> void:
	encounter = data
	for c in _enemy_slots.get_children():
		_enemy_slots.remove_child(c)
		c.queue_free()

	var count := mini(data.enemies.size(), EncounterDefinition.MAX_ENEMIES)
	if data.enemies.size() > count:
		push_warning("Encounter has %d enemies; only %d are shown." % [data.enemies.size(), count])

	for i in count:
		var actor: EnemyActor = ENEMY_SCENE.instantiate()
		actor.name = "Enemy%d" % (i + 1)
		actor.size_flags_vertical = Control.SIZE_SHRINK_END   # stand on the bottom of the zone
		_enemy_slots.add_child(actor)
		actor.setup(data.enemies[i])
		actor.clicked.connect(func(): enemy_clicked.emit(i))
		actor.spell_dropped.connect(func(d: SpellDefinition): spell_dropped_on.emit(i, d))
		actor.set_drop_enabled(_drop_enabled)
		
func set_drop_enabled(on: bool) -> void:
	_drop_enabled = on
	for a in _enemy_slots.get_children():
		a.set_drop_enabled(on)
		
func refresh(state: BattleState) -> void:
	for i in _enemy_slots.get_child_count():
		var actor: EnemyActor = _enemy_slots.get_child(i)
		var dead := state.enemies[i].is_dead()
		actor.set_alive(not dead)
		actor.set_selected(not dead and i == state.target_index)
