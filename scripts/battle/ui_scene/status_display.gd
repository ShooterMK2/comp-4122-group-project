class_name StatusDisplay
extends RefCounted
# Turns a CombatantState into a flat list of chip entries (status stacks, shield, stat buffs).
# Entry: {key, icon, letter, color, count, tooltip}

const COLORS := {
	"burn": Color(0.95, 0.4, 0.15),
	"chill": Color(0.5, 0.8, 1.0),
	"freeze": Color(0.75, 0.92, 1.0),
	"decay": Color(0.55, 0.4, 0.65),
	"corruption": Color(0.5, 0.2, 0.6),
	"tailwind": Color(0.6, 0.95, 0.7),
	"conductive": Color(0.85, 0.6, 1.0),
	"break": Color(1.0, 0.8, 0.2),
	"shield": Color(0.6, 0.7, 0.9),
	"buff": Color(0.5, 0.9, 0.5),
	"debuff": Color(0.95, 0.5, 0.5),
}
const STAT_NAMES := ["ATK", "DEF", "SPD"]

static func entries(c: CombatantState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in c.statuses.keys():
		var n: int = c.statuses[s]
		if n <= 0:
			continue
		var nm := StatusTypes.status_name(s)
		var key := nm.to_snake_case()
		var tip := "%s x%d" % [nm, n]
		if s == StatusTypes.Status.BREAK:
			tip = "Break (%d turn(s) left)" % n
		out.append(_entry("s_" + key, key, nm.substr(0, 2), n, tip))
	if c.shield > 0:
		out.append(_entry("shield", "shield", "Sh", c.shield, "Shield x%d (cuts one hit per charge)" % c.shield))
	for i in STAT_NAMES.size():
		if c.stat_buff_turns[i] > 0:
			out.append(_entry("buff_%d" % i, "buff", STAT_NAMES[i].substr(0, 1) + "+", c.stat_buff_turns[i],
				"%s up (%d turn(s))" % [STAT_NAMES[i], c.stat_buff_turns[i]]))
		if c.stat_debuff_turns[i] > 0:
			out.append(_entry("debuff_%d" % i, "debuff", STAT_NAMES[i].substr(0, 1) + "-", c.stat_debuff_turns[i],
				"%s down (%d turn(s))" % [STAT_NAMES[i], c.stat_debuff_turns[i]]))
	return out

static func _entry(key: String, icon_key: String, letter: String, count: int, tip: String) -> Dictionary:
	return {
		"key": key,
		"icon": AssetLookup.status_icon(icon_key),
		"letter": letter,
		"color": COLORS.get(icon_key, Color(0.8, 0.8, 0.8)),
		"count": count,
		"tooltip": tip,
	}