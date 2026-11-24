class_name UltimateResolver
extends RefCounted
# Applies the equipped player ultimate. Charge spend / gauge clear happen in the controller.

static func charge_ratio(spent: float) -> float:
	return clampf((spent - 100.0) / 50.0, 0.0, 1.0)

static func scaled_damage_mult(ult: UltimateDefinition, spent: float) -> float:
	var ratio := charge_ratio(spent)
	return lerpf(ult.damage_mult_min, ult.damage_mult_max, ratio)

static func activate(state: BattleState, ult: UltimateDefinition, spent: float,
		log_lines: Array[String]) -> void:
	if state == null or state.player == null or ult == null:
		return
	var ratio := charge_ratio(spent)
	state.ultimate_active = true
	match ult.effect_kind:
		UltimateDefinition.EffectKind.DAMAGE_BURST:
			var mult := scaled_damage_mult(ult, spent)
			state.player.set_damage_output_multiplier(mult)
			log_lines.append("%s: %.2fx damage this turn." % [ult.display_name, mult])
		UltimateDefinition.EffectKind.SECOND_WIND:
			var heal_amt := ult.heal_base + int(round(float(ult.heal_charge_bonus) * ratio))
			var healed := state.player.heal(heal_amt)
			if ult.heal_shield > 0:
				state.player.shield += ult.heal_shield
			log_lines.append("%s: restored %d HP%s." % [
				ult.display_name, healed,
				(" and +%d Shield" % ult.heal_shield) if ult.heal_shield > 0 else ""])
		UltimateDefinition.EffectKind.IRON_WARD:
			state.player.shield += ult.ward_shield
			log_lines.append("%s: +%d Shield." % [ult.display_name, ult.ward_shield])
		UltimateDefinition.EffectKind.BLOODLUST:
			var mild := scaled_damage_mult(ult, spent)
			state.player.set_damage_output_multiplier(mild)
			state.player.apply_stat_mod(0, true, ult.buff_turns)  # ATK
			log_lines.append("%s: %.2fx damage this turn, ATK up %d turns." % [
				ult.display_name, mild, ult.buff_turns])
		UltimateDefinition.EffectKind.SHOCKWAVE:
			var raw := ult.shockwave_base + int(round(float(ult.shockwave_charge_bonus) * ratio))
			var hits: Array[String] = []
			for enemy in state.enemies:
				if enemy.is_dead():
					continue
				# Scale lightly with player ATK so gear still matters.
				var dmg := maxi(1, ceili(float(raw) * maxf(1.0, float(state.player.attack)) / 5.0))
				dmg = maxi(1, ceili(float(dmg) * DamageCalculator.overlevel_multiplier_of(
					state.player, enemy)))
				var res := enemy.take_damage(dmg)
				hits.append("%s %d" % [enemy.display_name, res["hp"] + res["absorbed"]])
			log_lines.append("%s hits all: %s." % [
				ult.display_name, ", ".join(hits) if not hits.is_empty() else "no targets"])
		_:
			log_lines.append("%s activated." % ult.display_name)
