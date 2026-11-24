extends CanvasLayer

signal choice_made(effect: String)

@onready var title_label = %TitleLabel
@onready var desc_label = %DescLabel
@onready var choice_container = %ChoiceContainer

func show_event(event_data: Dictionary) -> void:
	title_label.text = event_data["title"]
	desc_label.text = event_data["description"]
	for child in choice_container.get_children():
		child.queue_free()
	for choice in event_data["choices"]:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.custom_minimum_size = Vector2(0, 50)
		
		# Visual for button
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.1, 0.05, 0.6)
		style_normal.set_corner_radius_all(8)
		style_normal.set_border_width_all(2)
		style_normal.border_color = Color(0.4, 0.25, 0.1, 1.0)
		style_normal.content_margin_left = 20
		style_normal.content_margin_right = 20
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.3, 0.15, 0.05, 0.8)
		style_hover.border_color = Color(0.8, 0.6, 0.3, 1.0)
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)
		btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		
		btn.pressed.connect(func(): 
			choice_made.emit(choice["effect"])
			hide()
		)
		choice_container.add_child(btn)
	show()
