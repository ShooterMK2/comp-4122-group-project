class_name SpriteSlot
extends Control
# Fits an animated sprite into this slot: aspect kept, bottom-centred, never
# enlarged past max_upscale. Tree:  SpriteSlot (this) > Fit (Node2D) > Sprite
# Animate only "Sprite". Fit carries the fitted scale; never animate it.

@export var reference_size := Vector2.ZERO   # frame size used for fitting; ZERO = auto
@export var max_upscale := 1.0               # 1.0 = never enlarge art beyond native size

@onready var _fit: Node2D = $Fit
@onready var _sprite: Node2D = $Fit/Sprite


func _ready() -> void:
	resized.connect(refit)
	refit.call_deferred()


func set_frames(frames: SpriteFrames, anim: StringName = &"default") -> void:
	var a := _sprite as AnimatedSprite2D
	a.sprite_frames = frames
	a.play(anim)
	refit()


func refit() -> void:
	var ref := _frame_size()
	if ref.x <= 0.0 or ref.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return
	var k := minf(minf(size.x / ref.x, size.y / ref.y), max_upscale)
	_fit.scale = Vector2.ONE * k
	_fit.position = Vector2(size.x * 0.5, size.y)      # bottom-centre of the slot
	_sprite.set("centered", true)
	_sprite.set("offset", Vector2(0.0, -ref.y * 0.5))   # feet sit on Fit's origin


func _frame_size() -> Vector2:
	if reference_size != Vector2.ZERO:
		return reference_size
	if _sprite is AnimatedSprite2D:
		var a := _sprite as AnimatedSprite2D
		if a.sprite_frames != null and a.sprite_frames.has_animation(a.animation) \
				and a.sprite_frames.get_frame_count(a.animation) > 0:
			var tex := a.sprite_frames.get_frame_texture(a.animation, 0)
			if tex != null:
				return tex.get_size()
	elif _sprite is Sprite2D:
		var s := _sprite as Sprite2D
		if s.texture != null:
			var sz := s.region_rect.size if s.region_enabled else s.texture.get_size()
			return sz / Vector2(maxi(s.hframes, 1), maxi(s.vframes, 1))
	return Vector2.ZERO
