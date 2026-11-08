class_name SpellCard
extends Control
# One spell card. Shows a spell, a counter badge, and can be clicked or dragged in the Casting Period.

signal clicked(definition: SpellDefinition, is_double: bool)

const SHAPE_COLUMNS := 5                 # TUNABLE: must equal %ShapeGrid.columns
const SIZE_CHANT := Vector2(120, 174)    # TUNABLE: compact card (includes LIFT headroom)
const SIZE_CAST := Vector2(180, 274)     # TUNABLE: large card (includes LIFT headroom)
const LIFT := 24.0                       # TUNABLE: rise distance; must equal %Lift offset_top at rest
const SELECT_TIME := 0.12                # TUNABLE: seconds for the rise animation
const DIM_ALPHA := 0.45                  # TUNABLE: opacity of a card with count 0 in the Chanting Period

var definition: SpellDefinition
var count := 0
var draggable := false                   # set by SpellZone
var selectable := false                  # set by SpellZone
var _tween: Tween

@onready var _lift: Control = %Lift
@onready var _body: Control = %Body
@onready var _shape: Array[Node] = %ShapeGrid.get_children()

func _ready() -> void:
	_ignore_mouse(self)                   # only this root receives clicks and drags

func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)

# projected < 0 means "unknown"
func show_spell(def: SpellDefinition, p_count: int, projected: int, compact: bool) -> void:
	definition = def
	count = p_count
	visible = true
	custom_minimum_size = SIZE_CHANT if compact else SIZE_CAST
	%NameLabel.text = def.display_name
	var tex: Texture2D = Elements.texture_of(def.primary_element())
	%ElementIcon.texture = tex
	for c in _shape:
		(c as TextureRect).modulate.a = 0.0
	for p: Vector2i in def.pattern.cells:
		var i := p.y * SHAPE_COLUMNS + p.x
		if p.x >= SHAPE_COLUMNS or p.x < 0 or i < 0 or i >= _shape.size():
			push_warning("SpellCard: pattern of %s does not fit the shape grid" % def.display_name)
			continue
		var cell := _shape[i] as TextureRect
		cell.texture = tex
		cell.modulate = Color.WHITE
	var fx: Array[String] = []
	for e in def.effects:
		fx.append(e.describe())
	var fx_text := ", ".join(fx) if not fx.is_empty() else "no effects"
	%EffectLabel.text = fx_text
	%EffectLabel.visible = not compact
	tooltip_text = fx_text
	if projected < 0:
		%DamageLabel.text = "DMG %d" % def.base_damage
	else:
		%DamageLabel.text = "DMG %d > %d" % [def.base_damage, projected]
	%CountLabel.text = "x%d" % count
	_body.modulate.a = DIM_ALPHA if (count == 0 and compact) else 1.0

func set_selected(on: bool, instant: bool = false) -> void:
	if _tween:
		_tween.kill()
	var top := 0.0 if on else LIFT
	var bottom := -LIFT if on else 0.0
	if instant:
		_lift.offset_top = top
		_lift.offset_bottom = bottom
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_lift, "offset_top", top, SELECT_TIME)
	_tween.tween_property(_lift, "offset_bottom", bottom, SELECT_TIME)

func _gui_input(event: InputEvent) -> void:
	if selectable and definition != null and count > 0 \
			and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(definition, event.double_click)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or count <= 0 or definition == null:
		return null
	var ghost := _body.duplicate() as Control      # visual copy only; no scripts inside %Body
	ghost.custom_minimum_size = _body.size
	ghost.modulate.a = 0.85
	set_drag_preview(ghost)
	return {"kind": "spell_card", "definition": definition}