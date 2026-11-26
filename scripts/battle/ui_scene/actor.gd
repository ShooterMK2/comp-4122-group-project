class_name Actor
extends Node2D
# One combatant's body in the 2D world. Origin = feet, so position.y is the ground line.
# Scene needs: Sprite (Sprite2D), Placeholder (ColorRect) with a child Label.

const FRAME_COLOR := Color(1.0, 0.85, 0.2)   # TUNABLE: selection frame
const FRAME_WIDTH := 2.0
const FRAME_PAD := 3.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _placeholder: ColorRect = $Placeholder
@onready var _placeholder_label: Label = $Placeholder/Label

var body_rect := Rect2()        # sprite bounds in local space (feet at the origin)
var _frame: Line2D
var _vanished := false

func setup(art_name: String, color: Color, label_text: String, height: float) -> void:
	var tex: Texture2D = AssetLookup.character(art_name.get_basename())
	_sprite.visible = tex != null
	if tex != null:
		var used := _opaque_rect(tex)
		var s := height / maxf(used.size.x, used.size.y)
		_sprite.centered = false
		_sprite.position = Vector2.ZERO
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.texture = tex
		_sprite.region_enabled = true
		_sprite.region_rect = used
		_sprite.offset = Vector2(-used.size.x / 2.0, -used.size.y)
		_sprite.scale = Vector2.ONE * s
		body_rect = Rect2(Vector2(-used.size.x * s / 2.0, -used.size.y * s), used.size * s)
	else:
		body_rect = Rect2(Vector2(-height / 2.0, -height), Vector2(height, height))
	_placeholder.visible = tex == null
	_placeholder.color = color
	_placeholder.size = Vector2(height, height)
	_placeholder.position = body_rect.position
	_placeholder_label.text = label_text
	_build_frame()

# Rectangle (local space) that should react to clicks and drops.
func get_hit_rect(_with_header: bool = false) -> Rect2:
	return body_rect

func set_targeted(on: bool) -> void:
	if _frame != null:
		_frame.visible = on and not _vanished

func set_dead(dead: bool) -> void:
	if _vanished:
		return
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE

func is_vanished() -> bool:
	return _vanished

func vanish(duration: float = 0.4) -> void:
	if _vanished:
		return
	_vanished = true
	if _frame != null:
		_frame.visible = false
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, duration)
	t.tween_callback(func(): visible = false)

# Visual effects driven by statuses (see StatusVisuals).
func apply_statuses(statuses: Dictionary) -> void:
	_sprite.self_modulate = StatusVisuals.tint_for(statuses)

func _build_frame() -> void:
	if _frame == null:
		_frame = Line2D.new()
		_frame.width = FRAME_WIDTH
		_frame.default_color = FRAME_COLOR
		_frame.joint_mode = Line2D.LINE_JOINT_SHARP
		_frame.z_index = 5
		_frame.visible = false
		add_child(_frame)
	var r := body_rect.grow(FRAME_PAD)
	_frame.points = PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end,
		Vector2(r.position.x, r.end.y), r.position])

func _opaque_rect(tex: Texture2D) -> Rect2:
	var img := tex.get_image()
	if img == null:
		return Rect2(Vector2.ZERO, tex.get_size())
	if img.is_compressed():
		img.decompress()
	var r := img.get_used_rect()
	if r.size == Vector2i.ZERO:
		return Rect2(Vector2.ZERO, tex.get_size())
	return Rect2(r)
