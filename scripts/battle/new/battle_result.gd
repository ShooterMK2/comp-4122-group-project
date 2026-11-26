class_name BattleResult
extends RefCounted
# What the battle reports to whoever launched it. Contains no scene or UI references.

var won := false
var run_over := false          # defeat is an instant loss; the launcher decides what that means
var rounds := 0
var hp_left := 0
var xp_gained := 0
var levels_gained := 0
var level_up_text := ""


func summary() -> String:
	var parts: Array[String] = ["Rounds %d" % rounds]
	if won:
		parts.append("HP left %d" % hp_left)
		parts.append("+%d XP" % xp_gained)
		if not level_up_text.is_empty():
			parts.append(level_up_text)
	return " | ".join(parts)
