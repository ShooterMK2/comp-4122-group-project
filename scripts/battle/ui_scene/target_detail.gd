class_name TargetDetail
extends PanelContainer
# Details of the inspected target. Display only.

# TUNABLE: [row label, key in the DamageCalculator.explain_* result]
const MULTS := [["Attack mod", "attack"], ["Ultimate", "ultimate"], ["Terrain", "attack_terrain"],
	["Spell tier", "other"], ["Defence", "defence"], ["Element", "elemental"],
	["Break", "break"], ["Random", "random"]]
const COLOR_UP := "#6fdc7a"      # multiplier above 1.0
const COLOR_DOWN := "#ff6b6b"    # multiplier below 1.0
const COLOR_FLAT := "#aaaaaa"    # multiplier about 1.0

@onready var _weak_chips: Array = %WeakRow.get_children().filter(func(n): return n is ElementChip)
@onready var _strong_chips: Array = %StrongRow.get_children().filter(func(n): return n is ElementChip)

func _ready() -> void:
	for chip in _weak_chips:
		chip.hide_chip()
	for chip in _strong_chips:
		chip.hide_chip()

# d keys (all optional): role, intent, spell_name, spell_effects, spell_info, basic_tiles, basic_info
func show_data(c: CombatantState, d: Dictionary) -> void:
	%RoleLabel.text = d.get("role", "TARGET")
	%NameLabel.text = c.display_name
	var spell_info: Dictionary = d.get("spell_info", {})
	var expected := int(spell_info.get("expected", 0))
	var after := maxi(c.hp - expected, 0)
	%HpBar.max_value = c.max_hp
	%HpBar.value = after
	if expected <= 0:
		%HpLabel.text = "HP %d/%d" % [c.hp, c.max_hp]
	else:
		%HpLabel.text = "HP %d -> %d  (-%d)" % [c.hp, after, expected]
	%IntentLabel.text = d.get("intent", "")
	%IntentLabel.visible = %IntentLabel.text != ""
	var spell_name: String = d.get("spell_name", "")
	%SpellTitle.text = ("Selected: " + spell_name) if spell_name != "" else "No spell selected. Click a card."
	%EffectsLabel.text = d.get("spell_effects", "")
	%EffectsLabel.visible = %EffectsLabel.text != ""
	%Breakdown.visible = not spell_info.is_empty()
	if not spell_info.is_empty():
		%Breakdown.text = _format(spell_info)
	var basic: Dictionary = d.get("basic_info", {})
	%BasicLabel.visible = not basic.is_empty()
	if not basic.is_empty():
		%BasicLabel.text = "End Turn basic attack: %d tiles -> %d dmg" % [
			int(d.get("basic_tiles", 0)), int(basic.get("expected", 0))]
	%StatusLabel.text = CombatantText.status_line(c)
	_fill_chips(_weak_chips, c.elemental_weaknesses, %WeakRow)
	_fill_chips(_strong_chips, c.elemental_strengths, %StrongRow)

func _fill_chips(chips: Array, elements: Array, row: Control) -> void:
	row.visible = not elements.is_empty()
	for i in chips.size():
		if i < elements.size():
			chips[i].show_element(elements[i])
		else:
			chips[i].hide_chip()

func _format(info: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("[b]Expected %d[/b]   (base %d)" % [int(info["expected"]), int(info["base"])])
	lines.append("ATK %d  (factor %.2fx)" % [int(info["effective_attack"]), float(info["attack_factor"])])
	for m in MULTS:
		var v: float = float(info[m[1]])
		var col := COLOR_FLAT
		if v > 1.001:
			col = COLOR_UP
		elif v < 0.999:
			col = COLOR_DOWN
		lines.append("%s  [color=%s]%.2fx[/color]" % [m[0], col, v])
	return "\n".join(lines)