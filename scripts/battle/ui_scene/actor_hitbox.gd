class_name ActorHitbox
extends Control
# Click / spell-drop target for one actor. Reports events; holds no game rules.

signal clicked
signal spell_dropped(definition: SpellDefinition)

const FRAME_COLOR := Color(1.0, 0.9, 0.1)
const FILL_COLOR := Color(0,0,0, 0)
const FRAME_WIDTH := 3.0

var enabled := true:                 # false once the actor is dead
	set(v):
		enabled = v
		queue_redraw()
var drop_enabled := false            # the controller enables this during the Casting Period
var selected := false:               # current target, set from the battle state
	set(v):
		selected = v
		queue_redraw()
var _lit := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	var lit := false
	if enabled and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		var vp := get_viewport()
		if vp.gui_is_dragging():
			lit = drop_enabled and _accepts(vp.gui_get_drag_data())
		else:
			lit = true
	if lit != _lit:
		_lit = lit
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	if _lit:
		draw_rect(Rect2(Vector2.ZERO, size), FILL_COLOR, true)
	if _lit or selected:
		var half := FRAME_WIDTH * 0.5
		draw_rect(Rect2(Vector2(half, half), size - Vector2(FRAME_WIDTH, FRAME_WIDTH)),
				FRAME_COLOR, false, FRAME_WIDTH)


func _gui_input(event: InputEvent) -> void:
	if enabled and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return enabled and drop_enabled and _accepts(data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	spell_dropped.emit(data["definition"])


func _accepts(data: Variant) -> bool:
	return data is Dictionary and data.get("definition") is SpellDefinition
