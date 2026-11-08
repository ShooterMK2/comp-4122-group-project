class_name SpellZone
extends ScrollContainer
# A pool of SpellCard slots. Fills them from data. Never creates nodes.

enum Mode { CHANTING, CASTING }

signal card_clicked(definition: SpellDefinition, is_double: bool)

var _selected: SpellDefinition = null
var _slots: Array[SpellCard] = []

func _ready() -> void:
	for child in %Flow.get_children():
		var card := child as SpellCard
		if card == null:
			push_warning("SpellZone: '%s' has no spell_card.gd attached; it is ignored" % child.name)
			child.visible = false
			continue
		card.visible = false
		card.clicked.connect(func(d: SpellDefinition, dbl: bool): card_clicked.emit(d, dbl))
		_slots.append(card)

# entries: [{"definition": SpellDefinition, "count": int, "projected": int}]
func show_spells(entries: Array[Dictionary], mode: Mode) -> void:
	var compact := mode == Mode.CHANTING
	var used := 0
	for e in entries:
		if not compact and e["count"] <= 0:
			continue                              # Casting shows only spells that were built
		if used >= _slots.size():
			push_warning("SpellZone: more spells than card slots (%d)" % _slots.size())
			break
		var card := _slots[used]
		card.show_spell(e["definition"], e["count"], e.get("projected", -1), compact)
		card.draggable = not compact
		card.selectable = not compact
		card.set_selected(card.definition == _selected and not compact, true)
		used += 1
	for i in range(used, _slots.size()):
		_slots[i].visible = false

# Pass null to clear the selection.
func set_selected(definition: SpellDefinition) -> void:
	_selected = definition
	for card in _slots:
		card.set_selected(definition != null and card.visible and card.definition == definition)
