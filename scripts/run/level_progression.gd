class_name LevelProgression
extends RefCounted

enum StatKind { MAX_HP, ATTACK, DEFENCE, SPEED }

## XP required to go from `level` -> level+1.
static func xp_to_next(level: int) -> int:
	var lv := clampi(level, RunConfig.PLAYER_LEVEL_MIN, RunConfig.PLAYER_LEVEL_MAX)
	# Gentler early curve so Zone 1 (Lv 1–20) advances with map battles + milestones.
	if lv <= 20:
		return 16 + lv * 8 + int((lv * lv) / 8.0)
	return 20 + lv * 12 + int((lv * lv) / 5.0)

static func battle_xp_for_enemies(defs: Array) -> int:
	var total := 0
	for d in defs:
		if d == null:
			continue
		var lv := 1
		if d is CombatantDefinition:
			lv = (d as CombatantDefinition).level
		total += RunConfig.BATTLE_XP_BASE + lv * RunConfig.BATTLE_XP_PER_ENEMY_LEVEL
	return maxi(0, total)

static func overlevel_gap(player_level: int, encounter_level: int) -> int:
	return maxi(0, encounter_level - player_level)

## 0 at gap 0, ~mild at OVERLEVEL_MILD_GAP, 1 at OVERLEVEL_HARSH_GAP.
static func overlevel_t(gap: int) -> float:
	if gap <= 0:
		return 0.0
	var harsh := float(RunConfig.OVERLEVEL_HARSH_GAP)
	var t := clampf(float(gap) / harsh, 0.0, 1.25)
	# Ease-in so gap ~5 stays mild.
	return t * t

static func player_damage_mult(gap: int) -> float:
	var t := overlevel_t(gap)
	return lerpf(1.0, RunConfig.OVERLEVEL_PLAYER_DEALT_AT_HARSH, clampf(t, 0.0, 1.0))

static func damage_taken_mult(gap: int) -> float:
	var t := overlevel_t(gap)
	return lerpf(1.0, RunConfig.OVERLEVEL_DAMAGE_TAKEN_AT_HARSH, clampf(t, 0.0, 1.0))

static func _stat_dict(kind: int) -> Dictionary:
	match kind:
		StatKind.MAX_HP:
			return {"kind": kind, "label": "MAX HP", "amount_i": RunConfig.LEVEL_UP_HP, "amount_f": 0.0}
		StatKind.ATTACK:
			return {"kind": kind, "label": "ATK", "amount_i": RunConfig.LEVEL_UP_ATTACK, "amount_f": 0.0}
		StatKind.DEFENCE:
			return {"kind": kind, "label": "DEF", "amount_i": RunConfig.LEVEL_UP_DEFENCE, "amount_f": 0.0}
		_:
			return {"kind": StatKind.SPEED, "label": "SPD", "amount_i": 0, "amount_f": RunConfig.LEVEL_UP_SPEED}

static func format_stat_text(stat: Dictionary) -> String:
	if int(stat["kind"]) == StatKind.SPEED:
		return "+%.2f %s" % [float(stat["amount_f"]), str(stat["label"])]
	return "+%d %s" % [int(stat["amount_i"]), str(stat["label"])]

## Always MAX HP, plus two distinct random of ATK / DEF / SPD.
static func pick_level_up_stats(_level_after: int = 1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(_stat_dict(StatKind.MAX_HP))
	var others: Array[int] = [StatKind.ATTACK, StatKind.DEFENCE, StatKind.SPEED]
	others.shuffle()
	out.append(_stat_dict(others[0]))
	out.append(_stat_dict(others[1]))
	return out

## Deprecated alias — prefer pick_level_up_stats.
static func pick_guaranteed_stat(level_after: int) -> Dictionary:
	var picked := pick_level_up_stats(level_after)
	return picked[0]

static func roll_non_stat_offers(run: Node, count: int = 3) -> Array[LevelUpOffer]:
	var pool: Array[LevelUpOffer] = []
	pool.append(LevelUpOffer.gold(randi_range(RunConfig.LEVEL_UP_GOLD_MIN, RunConfig.LEVEL_UP_GOLD_MAX)))
	pool.append(LevelUpOffer.heal(RunConfig.LEVEL_UP_HEAL_AMOUNT))
	pool.append(LevelUpOffer.consumable(&"healing_potion", "Healing Potion"))
	pool.append(LevelUpOffer.consumable(&"protective_ring", "Protective Ring"))
	pool.append(LevelUpOffer.consumable(&"fire_booster", "Fire Booster"))
	for frag in StarterContent.reward_fragments():
		if run != null and run.has_method("owns_fragment") and run.owns_fragment(frag.id):
			continue
		pool.append(LevelUpOffer.fragment(frag.id, frag.display_name))
	for spell in StarterContent.reward_spells():
		if run != null and run.has_method("owns_spell") and run.owns_spell(spell.id):
			continue
		pool.append(LevelUpOffer.spell(spell.id, spell.display_name))
	pool.shuffle()
	var out: Array[LevelUpOffer] = []
	var used_labels: Dictionary = {}
	for o in pool:
		if out.size() >= count:
			break
		if used_labels.has(o.label):
			continue
		used_labels[o.label] = true
		out.append(o)
	# Pad with gold variants if pool was thin.
	var pad := 1
	while out.size() < count:
		var g := LevelUpOffer.gold(RunConfig.LEVEL_UP_GOLD_MIN + pad * 5)
		if not used_labels.has(g.label):
			used_labels[g.label] = true
			out.append(g)
		pad += 1
		if pad > 10:
			break
	return out

## Suggest authored-ish stats for a Zone 1 enemy level (1–20) in the 1–500 band.
static func suggest_enemy_stats(level: int) -> Dictionary:
	var lv := clampi(level, 1, 20)
	var t := float(lv - 1) / 19.0
	return {
		"level": lv,
		"max_hp": int(lerpf(50.0, 220.0, t)),
		"attack": int(lerpf(3.0, 28.0, t)),
		"defence": int(lerpf(1.0, 14.0, t)),
		"speed": lerpf(2.0, 6.0, t),
	}
