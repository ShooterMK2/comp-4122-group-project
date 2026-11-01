class_name CombatantDefinition
extends Resource

@export var display_name: String = "Combatant"
@export var max_hp: int = 1
@export var level: int = 1
@export var attack: int = 1
@export var defence: int = 0
@export var speed: float = 1.0
@export var elemental_weaknesses: Array[int] = []
@export var elemental_strengths: Array[int] = []
@export var art_name: String = ""
@export var placeholder_color: Color = Color(0.35, 0.35, 0.4)
