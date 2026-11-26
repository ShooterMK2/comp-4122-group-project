class_name EnemyActor
extends Actor
# An enemy in the world plus its header: name, weak-spot icons, HP bar, status icons.
# Scene unique-name nodes: Header (VBoxContainer), NameLabel, WeakspotRow (HFlowContainer),
# HpBar (ProgressBar or TextureProgressBar) with child HpLabel, StatusRow (HFlowContainer).

const HEADER_WIDTH := 96.0           # TUNABLE: on-screen width of the header in pixels
const HEADER_GAP := 4.0              # TUNABLE: space between header and the sprite's head
const MAX_STATUS_CHIPS := 8          # TUNABLE: more than this collapses into a "+N" chip
const HP_TWEEN_TIME := 0.25
const ELEMENT_CHIP_PATH := "res://scenes/battle/ui/element_chip.tscn"
const STATUS_CHIP_PATH := "res://scenes/battle/ui/status_chip.tscn"

var _element_chip_scene: PackedScene
var _status_chip_scene: PackedScene

@onready var _header: Control = %Header
@onready var _name_label: Label = %NameLabel
@onready var _weak_row: Container = %WeakspotRow
@onready var _hp_bar: Range = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _status_row: Container = %StatusRow

var _weak_key: Array[int] = []
var _status_sig := "!"
var _hp_tween: Tween

func _ready() -> void:
	_header.custom_minimum_size.x = HEADER_WIDTH
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.resized.connect(_place_header)
	_hp_bar.min_value = 0.0
	_hp_bar.max_value = 100.0           # the bar works in percent
	_clear(_weak_row)                    # drop any chips left in the scene
	_clear(_status_row)
	_element_chip_scene = load(ELEMENT_CHIP_PATH) as PackedScene
	_status_chip_scene = load(STATUS_CHIP_PATH) as PackedScene

func setup_enemy(def: EnemyDefinition, height: float) -> void:
	setup(def.art_name, def.placeholder_color, def.display_name.substr(0, 6).to_upper(), height)
	_name_label.text = def.display_name
	_refit_header()

func refresh(c: CombatantState) -> void:
	_set_hp(c)
	_sync_weaknesses(c.elemental_weaknesses)
	_sync_statuses(c)

func get_hit_rect(with_header: bool = false) -> Rect2:
	var r := body_rect
	if with_header and _header.visible:
		r = r.merge(Rect2(_header.position, _header.size))
	return r

func _set_hp(c: CombatantState) -> void:
	var pct := 100.0 * float(c.hp) / float(maxi(c.max_hp, 1))
	_hp_label.text = "%d/%d" % [c.hp, c.max_hp]
	if _hp_tween != null:
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(_hp_bar, "value", pct, HP_TWEEN_TIME)

func _sync_weaknesses(list: Array[int]) -> void:
	if list == _weak_key:
		return
	_weak_key = list.duplicate()
	_clear(_weak_row)
	for e in list:
		var chip: ElementChip = _element_chip_scene.instantiate()
		_weak_row.add_child(chip)
		chip.show_element(e)
	_weak_row.visible = not list.is_empty()
	_refit_header()

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
		var chip: StatusChip = _status_chip_scene.instantiate()
		_status_row.add_child(chip)
		chip.show_entry(e)
	if overflow > 0:
		var more: StatusChip = _status_chip_scene.instantiate()
		_status_row.add_child(more)
		more.show_overflow(overflow)
	_status_row.visible = not entries.is_empty()
	_refit_header()

func _clear(row: Node) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()

func _refit_header() -> void:
	_header.reset_size.call_deferred()
	_place_header.call_deferred()

# The header sits above the sprite's head and grows upward as chips are added.
func _place_header() -> void:
	_header.position = Vector2(-_header.size.x / 2.0,
		body_rect.position.y - _header.size.y - HEADER_GAP)
		
