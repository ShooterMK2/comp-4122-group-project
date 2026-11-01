class_name CombatantState
extends RefCounted

var display_name := ""
var max_hp := 1
var hp := 1
var level := 1
var attack := 1
var defence := 0
var elemental_weaknesses: Array[int] = []
var elemental_strengths: Array[int] = []
var shield := 0
var statuses := {}

func _init(p_name: String = "", p_max_hp: int = 1, p_level: int = 1,
		p_attack: int = 1, p_defence: int = 0) -> void:
	display_name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	level = p_level
	attack = p_attack
	defence = p_defence

static func from_definition(definition: CombatantDefinition,
		name_override: String = "") -> CombatantState:
	var name := definition.display_name if name_override.is_empty() else name_override
	var state := CombatantState.new(name, definition.max_hp, definition.level,
		definition.attack, definition.defence)
	state.elemental_weaknesses = definition.elemental_weaknesses.duplicate()
	state.elemental_strengths = definition.elemental_strengths.duplicate()
	return state


func get_status(s: int) -> int:
	return statuses.get(s, 0)

func add_status(s: int, n: int) -> void:
	statuses[s] = get_status(s) + n

func consume_status(s: int, n: int = -1) -> int:
	var cur := get_status(s)
	var take := cur if n < 0 else mini(n, cur)
	if cur - take <= 0:
		statuses.erase(s)
	else:
		statuses[s] = cur - take
	return take

func take_damage(amount: int) -> Dictionary:
	var absorbed := mini(shield, amount)
	shield -= absorbed
	var lost := mini(hp, amount - absorbed)
	hp -= lost
	return {"absorbed": absorbed, "hp": lost}

func heal(n: int) -> int:
	var healed := mini(n, max_hp - hp)
	hp += healed
	return healed

func is_dead() -> bool:
	return hp <= 0

func duplicate_state() -> CombatantState:
	var c := CombatantState.new(display_name, max_hp, level, attack, defence)
	c.elemental_weaknesses = elemental_weaknesses.duplicate()
	c.elemental_strengths = elemental_strengths.duplicate()
	c.hp = hp
	c.shield = shield
	c.statuses = statuses.duplicate()
	return c