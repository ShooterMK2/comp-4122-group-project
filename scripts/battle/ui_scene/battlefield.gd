extends HBoxContainer
signal enemy_clicked(index: int)
signal player_clicked
signal ultimate_pressed
signal spell_dropped_on(target_index: int, definition)
func setup(_state) -> void:
	pass
func refresh(_state) -> void:
	pass
func set_drop_enabled(_on: bool) -> void:
	pass
