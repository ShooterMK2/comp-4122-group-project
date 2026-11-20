class_name UltimateLibrary
extends RefCounted
# Starter / unlockable player ultimates. Damage Burst matches the original ultimate.

static func all() -> Array[UltimateDefinition]:
	var out: Array[UltimateDefinition] = []
	out.append(damage_burst())
	out.append(second_wind())
	out.append(iron_ward())
	out.append(bloodlust())
	out.append(shockwave())
	return out

static func by_id(id: StringName) -> UltimateDefinition:
	for u in all():
		if u.id == id:
			return u
	return null

## Original battle ultimate: spend charge for a strong damage multiplier this turn.
static func damage_burst() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_damage_burst",
		"Overdrive",
		"The classic ultimate. Spend your charge for a huge damage multiplier until the turn ends. Fuller gauges hit harder.",
		UltimateDefinition.EffectKind.DAMAGE_BURST)
	u.damage_mult_min = BattleConfig.ULTIMATE_MIN_MULTIPLIER
	u.damage_mult_max = BattleConfig.ULTIMATE_MAX_MULTIPLIER
	u.icon = IconLookup.spell()
	return u

static func second_wind() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_second_wind",
		"Second Wind",
		"Recover HP based on charge spent. A small shield steadies you for the next hits.",
		UltimateDefinition.EffectKind.SECOND_WIND)
	u.heal_base = 28
	u.heal_charge_bonus = 40
	u.heal_shield = 1
	u.icon = IconLookup.for_item_id(&"minor_tonic")
	return u

static func iron_ward() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_iron_ward",
		"Iron Ward",
		"Raise a heavy ward. Gain several shield layers immediately.",
		UltimateDefinition.EffectKind.IRON_WARD)
	u.ward_shield = 4
	u.icon = IconLookup.for_item_id(&"warding_charm")
	return u

static func bloodlust() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_bloodlust",
		"Bloodlust",
		"Enter a fury: ATK buff for several turns, plus a milder damage multiplier this turn.",
		UltimateDefinition.EffectKind.BLOODLUST)
	u.damage_mult_min = 1.75
	u.damage_mult_max = 2.25
	u.buff_turns = 3
	u.icon = IconLookup.for_item_id(&"blessed_sigil")
	return u

static func shockwave() -> UltimateDefinition:
	var u := UltimateDefinition.make(
		&"ult_shockwave",
		"Shockwave",
		"Slam every living enemy for charge-scaled damage. Does not apply a lasting damage multiplier.",
		UltimateDefinition.EffectKind.SHOCKWAVE)
	u.shockwave_base = 20
	u.shockwave_charge_bonus = 28
	u.icon = IconLookup.spell()
	return u
