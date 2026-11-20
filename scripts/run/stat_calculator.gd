class_name StatCalculator
extends RefCounted

static func build_snapshot(base: PlayerDefinition, loadout: EquipmentLoadout,
		pending: PendingBattleModifiers = null) -> PlayerStatSnapshot:
	var snap := PlayerStatSnapshot.new()
	snap.display_name = base.display_name
	snap.level = base.level
	snap.base_max_hp = base.max_hp
	snap.base_attack = base.attack
	snap.base_defence = base.defence
	snap.base_speed = base.speed
	snap.elemental_weaknesses = base.elemental_weaknesses.duplicate()
	snap.elemental_strengths = base.elemental_strengths.duplicate()
	snap.art_name = base.art_name
	snap.placeholder_color = base.placeholder_color
	for item in loadout.all_equipped():
		snap.equip_max_hp += item.bonus_max_hp
		snap.equip_attack += item.bonus_attack
		snap.equip_defence += item.bonus_defence
		snap.equip_speed += item.bonus_speed
		if item.passive == PassiveEffect.Kind.START_SHIELD:
			snap.start_shield += item.passive_amount
	if pending != null:
		snap.item_max_hp += pending.temp_max_hp
		snap.item_attack += pending.item_attack
		snap.item_defence += pending.item_defence
		snap.item_speed += pending.item_speed
		snap.start_shield += pending.start_shield
	return snap
