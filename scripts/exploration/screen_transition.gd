extends CanvasLayer

var fade_rect: ColorRect

func _ready() -> void:
	layer = 100 
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade_rect)

# Before changing scene
func fade_out(duration: float = 0.3) -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Block clicks during transition
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished

# After new scene is ready
func fade_in(duration: float = 0.6) -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
