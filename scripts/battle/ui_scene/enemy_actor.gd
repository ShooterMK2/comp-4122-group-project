class_name EnemyActor
extends Control
# An enemy on the battlefield: sprite, hitbox, name, weak-spot icons, HP bar, status icons.
# Scene nodes: ActorHitbox, SpriteWarpper/SpriteSlot (with Sprite), Placeholder (with Label),
# and SpriteUI holding NameLabel, WeakspotRow, HpBar (with HpLabel), StatusRow.

signal clicked
signal spell_dropped(definition: SpellDefinition)

const MAX_STATUS_CHIPS := 8          # TUNABLE: more than this collapses into a "+N" chip
const ELEMENT_CHIP_PATH := "res://scenes/battle/ui/element_chip.tscn"
const STATUS_CHIP_PATH := "res://scenes/battle/ui/status_chip.tscn"

@onready var _hitbox: ActorHitbox = $ActorHitbox
@onready var _slot: SpriteSlot = $SpriteWarpper/SpriteSlot
@onready var _placeholder: ColorRect = $Placeholder
@onready var _name_label: Label = %NameLabel
@onready var _weak_row: Container = %WeakspotRow
@onready var _hp_bar: Range = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _status_row: Container = %StatusRow

var _element_chip_scene: PackedScene
var _status_chip_scene: PackedScene
var _weak_key: Array = []
var _status_sig := "!"


func _ready() -> void:
	_hitbox.clicked.connect(func(): clicked.emit())
	_hitbox.spell_dropped.connect(func(d: SpellDefinition): spell_dropped.emit(d))
	_clear(_weak_row)                    # drop any chips left in the scene
	_clear(_status_row)
	_element_chip_scene = load(ELEMENT_CHIP_PATH) as PackedScene
	_status_chip_scene = load(STATUS_CHIP_PATH) as PackedScene


# Call after the actor has been added to the tree.
func setup(def: EnemyDefinition) -> void:
	_name_label.text = def.display_name
	_hp_bar.max_value = def.max_hp
	_hp_bar.value = def.max_hp
	_hp_label.text = "%d/%d" % [def.max_hp, def.max_hp]
	var tex := AssetLookup.character(def.art_name)
	_slot.visible = tex != null
	_placeholder.visible = tex == null
	if tex == null:
		_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_placeholder.color = def.placeholder_color
		$Placeholder/Label.text = def.display_name
		return
	var frames := SpriteFrames.new()
	if not frames.has_animation(&"default"):
		frames.add_animation(&"default")
	frames.add_frame(&"default", tex)
	%Sprite.sprite_frames = frames
	%Sprite.play(&"default")
	_slot.refit.call_deferred()
	
func setup_enemy(def: EnemyDefinition, height: float) -> void:
	setup(def)
	var base_height := size.y
	if base_height > 0.0:
		var s := height / base_height
		scale = Vector2(s, s)

# Redraws HP, weaknesses and statuses from the battle state.
func refresh(c: CombatantState) -> void:
	_name_label.text = c.display_name
	_hp_bar.max_value = c.max_hp
	_hp_bar.value = c.hp
	_hp_label.text = "%d/%d" % [c.hp, c.max_hp]
	_sync_weaknesses(c.elemental_weaknesses)
	_sync_statuses(c)


func set_drop_enabled(on: bool) -> void:
	_hitbox.drop_enabled = on


func set_alive(alive: bool) -> void:
	_hitbox.enabled = alive
	modulate = Color.WHITE if alive else Color(0.45, 0.45, 0.45)


func set_selected(on: bool) -> void:
	_hitbox.selected = on


# ---------- weakness and status chips ----------

func _sync_weaknesses(list: Array) -> void:
	if list == _weak_key:
		return
	_weak_key = list.duplicate()
	_clear(_weak_row)
	for e in list:
		var chip: Node = _element_chip_scene.instantiate()
		_weak_row.add_child(chip)
		chip.call("show_element", e)
	_weak_row.visible = not list.is_empty()


func _sync_statuses(c: CombatantState) -> void:
	var entries := StatusDisplay.entries(c)
	var overflow := 0
	if entries.size() > MAX_STATUS_CHIPS:
		overflow = entries.size() - (MAX_STATUS_CHIPS - 1)
		entries = entries.slice(0, MAX_STATUS_CHIPS - 1)
	var parts: Array[String] = []
	for e in entries:
		parts.append("%s:%d" % [e["key"], e["count"]])
	var sig := ",".join(parts) + "+%d" % overflow
	if sig == _status_sig:
		return
	_status_sig = sig
	_clear(_status_row)
	for e in entries:
		var chip: Node = _status_chip_scene.instantiate()
		_status_row.add_child(chip)
		chip.call("show_entry", e)
	if overflow > 0:
		var more: Node = _status_chip_scene.instantiate()
		_status_row.add_child(more)
		more.call("show_overflow", overflow)
	_status_row.visible = not entries.is_empty()


func _clear(row: Node) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
