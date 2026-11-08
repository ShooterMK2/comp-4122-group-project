class_name CombatantText
extends RefCounted
# Shared text helpers for CombatantPanel and TargetDetail.

static func status_line(c: CombatantState) -> String:
	var status_text := StatusSystem.describe(c)
	if c.break_threshold > 0:
		var stage := ""
		if c.is_broken():
			stage = "Break (%d turns total, %d remaining)" % [
				BattleConfig.BREAK_TURNS, c.get_status(StatusTypes.Status.BREAK)]
		else:
			stage = _break_stage(c)
		var brk := "Shield Break: %s (%d/%d)" % [stage, c.break_hits, c.break_threshold]
		status_text = brk if status_text.is_empty() else brk + " | " + status_text
	return status_text

static func _break_stage(c: CombatantState) -> String:
	if c.is_broken():
		return "Break"
	if c.break_hits <= 0:
		return "No"
	var progress := float(c.break_hits) / float(c.break_threshold)
	if progress < 0.34:   # TUNABLE: Minor stage upper bound
		return "Minor"
	if progress < 0.67:   # TUNABLE: Medium stage upper bound
		return "Medium"
	return "Major"