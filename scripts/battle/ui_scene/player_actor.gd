class_name PlayerActor
extends Control
# Battlefield body of the player. Shows art only: HP, charge and status live in PlayerPanel.
# Call setup() after the actor has been added to the tree.

@export var max_scale := 1.0    # TUNABLE: 1.0 = never enlarge the art, only shrink it to fit

@onready var _slot: Control = $SpriteWrapper/SpriteSlot
@onready var _fit: Node2D = $SpriteWrapper/SpriteSlot/Fit
@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _placeholder: ColorRect = $Placeholder
@onready var _placeholder_label: Label = $Placeholder/Label

var _used := Rect2()    # opaque part of the texture, so the feet sit on the slot bottom


func _ready() -> void:
	_slot.resized.connect(_refit)


func setup(def: PlayerDefinition) -> void:
	if not is_node_ready():
		await ready
	var tex := AssetLookup.character(def.art_name)
	_sprite.visible = tex != null
	_placeholder.visible = tex == null
	_placeholder.color = def.placeholder_color
	_placeholder_label.text = def.display_name
	if tex == null:
		return
	var frames := SpriteFrames.new()          # a new SpriteFrames already has "default"
	frames.add_frame(&"default", tex)
	_sprite.sprite_frames = frames
	_sprite.play(&"default")
	_used = _opaque_rect(tex)
	_refit()


func set_dead(dead: bool) -> void:
	modulate = Color(0.45, 0.45, 0.45) if dead else Color.WHITE


# Fit the opaque art inside the slot, bottom-centred.
func _refit() -> void:
	if _sprite.sprite_frames == null or _used.size.x <= 0.0 or _used.size.y <= 0.0:
		return
	if _slot.size.x <= 0.0 or _slot.size.y <= 0.0:
		return
	var s := minf(minf(_slot.size.x / _used.size.x, _slot.size.y / _used.size.y), max_scale)
	_fit.scale = Vector2.ONE * s
	_fit.position = Vector2(_slot.size.x * 0.5, _slot.size.y)
	_sprite.position = -Vector2(_used.position.x + _used.size.x * 0.5, _used.position.y + _used.size.y)


static func _opaque_rect(tex: Texture2D) -> Rect2:
	var full := Rect2(Vector2.ZERO, tex.get_size())
	var img := tex.get_image()
	if img == null:
		return full
	if img.is_compressed():
		img.decompress()
	var r := img.get_used_rect()
	return full if r.size == Vector2i.ZERO else Rect2(r)
