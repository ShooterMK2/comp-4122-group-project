class_name StatCalculator
extends RefCounted

static func build_snapshot(base: PlayerDefinition, loadout: EquipmentLoadout,
		pending: PendingBattleModifiers = null,
		level_bonuses: Dictionary = {},
		player_level: int = -1,
		perm_start_shield: int = 0) -> PlayerStatSnapshot:
	var snap := PlayerStatSnapshot.new()
	snap.display_name = base.display_name
	snap.level = player_level if player_level > 0 else base.level
	snap.base_max_hp = base.max_hp
	snap.base_attack = base.attack
	snap.base_defence = base.defence
	snap.base_speed = base.speed
	snap.elemental_weaknesses = base.elemental_weaknesses.duplicate()
	snap.elemental_strengths = base.elemental_strengths.duplicate()
	snap.art_name = base.art_name
	snap.placeholder_color = base.placeholder_color
	snap.start_shield = perm_start_shield
	snap.damage_taken_multiplier = 1.0
	for item in loadout.all_equipped():
		snap.equip_max_hp += item.bonus_max_hp
		snap.equip_attack += item.bonus_attack
		snap.equip_defence += item.bonus_defence
		snap.equip_speed += item.bonus_speed
		snap.max_hp_mult += item.max_hp_mult
		snap.speed_mult += item.speed_mult
		snap.damage_dealt_bonus += item.damage_dealt_bonus
		_merge_element_bonuses(snap.element_spell_damage_mult, item.element_damage_bonuses)
		_apply_passive(snap, item.passive, item.passive_amount)
		_apply_passive(snap, item.passive2, item.passive2_amount)
		if item.start_stat_buff != EquipmentDefinition.START_BUFF_NONE:
			snap.start_stat_buffs.append(item.start_stat_buff)
	if pending != null:
		snap.item_max_hp += pending.temp_max_hp
		snap.item_attack += pending.item_attack
		snap.item_defence += pending.item_defence
		snap.item_speed += pending.item_speed
		snap.start_shield += pending.start_shield
		_merge_element_bonuses(snap.element_spell_damage_mult, pending.element_spell_damage_mult)
	snap.level_max_hp = int(level_bonuses.get("max_hp", 0))
	snap.level_attack = int(level_bonuses.get("attack", 0))
	snap.level_defence = int(level_bonuses.get("defence", 0))
	snap.level_speed = float(level_bonuses.get("speed", 0.0))
	return snap

static func _merge_element_bonuses(dest: Dictionary, src: Dictionary) -> void:
	for key in src.keys():
		dest[int(key)] = float(dest.get(int(key), 0.0)) + float(src[key])

static func _apply_passive(snap: PlayerStatSnapshot, kind: int, amount: int) -> void:
	match kind:
		PassiveEffect.Kind.START_SHIELD:
			snap.start_shield += amount
		PassiveEffect.Kind.DAMAGE_RESISTANCE:
			# amount is percent reduction (20 => ×0.8); stack multiplicatively.
			var resist := clampf(float(amount) / 100.0, 0.0, 0.95)
			snap.damage_taken_multiplier *= (1.0 - resist)
		PassiveEffect.Kind.ELEMENT_DAMAGE_BONUS:
			pass  # Prefer EquipmentDefinition.element_damage_bonuses
		_:
			pass
