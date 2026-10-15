class_name DebugPanel
extends HFlowContainer

signal give_element(element: int)
signal reroll_pressed

const ELEMENT_LIST := [
	Elements.Element.FIRE, Elements.Element.ICE, Elements.Element.EARTH,
	Elements.Element.WIND, Elements.Element.LIGHTNING, Elements.Element.DARK,
]

func _init() -> void:
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 6)
	for e in ELEMENT_LIST:
		var b := Button.new()
		b.text = "Debug give " + Elements.name_of(e)
		b.pressed.connect(_on_give.bind(e))
		add_child(b)
	var r := Button.new()
	r.text = "Reroll hand"
	r.pressed.connect(_on_reroll)
	add_child(r)

func _on_give(e: int) -> void:
	give_element.emit(e)

func _on_reroll() -> void:
	reroll_pressed.emit()
