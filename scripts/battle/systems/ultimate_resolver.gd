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
		UltimateDefinition.EffectKind.EMERGENCY_AID:
			var pct := lerpf(ult.heal_percent_min, ult.heal_percent_max, ratio)
			var heal_amt := maxi(1, ceili(float(state.player.max_hp) * pct))
			var healed := state.player.heal(heal_amt)
			var shields := int(round(lerpf(float(ult.shield_min), float(ult.shield_max), ratio)))
			shields = clampi(shields, ult.shield_min, ult.shield_max)
			state.player.shield += shields
			log_lines.append("%s: restored %d HP and +%d Shield." % [
				ult.display_name, healed, shields])
		UltimateDefinition.EffectKind.FIGHTING_SPIRIT:
			var turns := int(round(lerpf(float(ult.buff_turns_min), float(ult.buff_turns_max), ratio)))
			turns = clampi(turns, ult.buff_turns_min, ult.buff_turns_max)
			state.player.apply_stat_mod(0, true, turns)  # ATK
			state.player.apply_stat_mod(1, true, turns)  # DEF
			state.player.apply_stat_mod(2, true, turns)  # SPD
			log_lines.append("%s: ATK/DEF/SPD up for %d turns." % [ult.display_name, turns])
		UltimateDefinition.EffectKind.SHOCKWAVE:
			var raw := ult.shockwave_base + int(round(float(ult.shockwave_charge_bonus) * ratio))
			var hits: Array[String] = []
			for enemy in state.enemies:
				if enemy.is_dead():
					continue
				# Fixed damage — no ATK gear scaling (Crowd Control).
				var dmg := maxi(1, raw)
				dmg = maxi(1, ceili(float(dmg) * DamageCalculator.overlevel_multiplier_of(
					state.player, enemy)))
				var res := enemy.take_damage(dmg)
				hits.append("%s %d" % [enemy.display_name, res["hp"] + res["absorbed"]])
			log_lines.append("%s hits all: %s." % [
				ult.display_name, ", ".join(hits) if not hits.is_empty() else "no targets"])
		_:
			log_lines.append("%s activated." % ult.display_name)
