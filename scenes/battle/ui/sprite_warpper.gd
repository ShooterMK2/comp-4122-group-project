class_name SpriteFit
extends VBoxContainer
# Fits the child Sprite2D inside this container (aspect kept), bottom-centred.
# A VBoxContainer does not lay out Node2D children, so this script does it.

@export var trim_transparent := true    # fit the visible pixels, not the empty margin

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_sprite.centered = false
	resized.connect(fit)
	set_texture(_sprite.texture)


func set_texture(tex: Texture2D) -> void:
	_sprite.texture = tex
	_sprite.region_enabled = false
	if tex != null and trim_transparent:
		var img := tex.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var used := img.get_used_rect()
			if used.size != Vector2i.ZERO:
				_sprite.region_enabled = true
				_sprite.region_rect = Rect2(used)
	fit()


func fit() -> void:
	if _sprite.texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var src := _sprite.region_rect.size if _sprite.region_enabled else _sprite.texture.get_size()
	if src.x <= 0.0 or src.y <= 0.0:
		return
	var k := minf(size.x / src.x, size.y / src.y)
	_sprite.scale = Vector2.ONE * k
	_sprite.position = Vector2((size.x - src.x * k) * 0.5, size.y - src.y * k)
