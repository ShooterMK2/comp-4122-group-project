class_name UltimateLibrary
extends RefCounted
# Chapter-1 player ultimates. None are equipped by default.

static func all() -> Array[UltimateDefinition]:
	var out: Array[UltimateDefinition] = []
	out.append(powerful_charge())
	out.append(emergency_aid())
	out.append(fighting_spirit())
	out.append(crowd_control())
	return out

static func by_id(id: StringName) -> UltimateDefinition:
	for u in all():
		if u.id == id:
			return u
	return null

static func powerful_charge() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_powerful_charge",
		"Powerful Charge",
		"Unleash powerful strike to enemy, higher spell damage for a turn",
		UltimateDefinition.EffectKind.DAMAGE_BURST)
	u.damage_mult_min = BattleConfig.ULTIMATE_MIN_MULTIPLIER
	u.damage_mult_max = BattleConfig.ULTIMATE_MAX_MULTIPLIER
	u.icon = IconLookup.for_item_id(&"ult_powerful_charge")
	return u

static func emergency_aid() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_emergency_aid",
		"Emergency Aid",
		"Stabilize your position in battlefield, recover HP & gain shields",
		UltimateDefinition.EffectKind.EMERGENCY_AID)
	u.heal_percent_min = 0.15
	u.heal_percent_max = 0.30
	u.shield_min = 1
	u.shield_max = 4
	u.icon = IconLookup.for_item_id(&"ult_emergency_aid")
	return u

static func fighting_spirit() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_fighting_spirit",
		"Fighting Spirit",
		"Keep yourself rose in the battle, provide ATK, DEF, SPD buff",
		UltimateDefinition.EffectKind.FIGHTING_SPIRIT)
	u.buff_turns_min = 4
	u.buff_turns_max = 7
	u.icon = IconLookup.for_item_id(&"ult_fighting_spirit")
	return u

static func crowd_control() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_crowd_control",
		"Crowd Control",
		"Harm multiple opponents at once in the field, deal fixed damage for all enemy",
		UltimateDefinition.EffectKind.SHOCKWAVE)
	u.shockwave_base = 20
	u.shockwave_charge_bonus = 28
	u.icon = IconLookup.for_item_id(&"ult_crowd_control")
	return u

## Compatibility alias used by older call sites.
static func damage_burst() -> UltimateDefinition:
	return powerful_charge()
