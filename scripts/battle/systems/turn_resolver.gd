class_name TurnResolver
extends RefCounted

const S := StatusTypes.Status

# END of a unit's own turn: Burn, Decay, then natural stack loss.
static func end_turn_effects(c: CombatantState, _log: Array[String]) -> void:
	var burn := c.get_status(S.BURN)
	if burn > 0:
		var dmg := StatusSystem.deal_direct(c, burn * BattleConfig.BURN_DAMAGE_PER_STACK)
		c.consume_status(S.BURN, BattleConfig.BURN_LOSS_PER_TURN)
		_log.append("%s takes %d Burn damage." % [c.display_name, dmg])
	var decay := c.get_status(S.DECAY)
	if decay > 0:
		var dmg2 := StatusSystem.deal_direct(c, decay * BattleConfig.DECAY_DAMAGE_PER_STACK)
		c.consume_status(S.DECAY, BattleConfig.DECAY_LOSS_PER_TURN)
		_log.append("%s takes %d Decay damage." % [c.display_name, dmg2])
	c.consume_status(S.CHILL, BattleConfig.CHILL_LOSS_PER_TURN)

static func run_enemy_action(state: BattleState, i: int, _log: Array[String]) -> void:
	var e := state.enemies[i]
	if e.is_dead():
		return
	var corruption_triggered := 0

	if e.get_status(S.FREEZE) > 0:
		e.consume_status(S.FREEZE, BattleConfig.FREEZE_LOSS_PER_SKIP)
		_log.append("%s is Frozen and skips its turn (no Corruption trigger)." % e.display_name)
	else:
		var corr := e.get_status(S.CORRUPTION)
		if corr > 0:
			var cdmg := StatusSystem.deal_direct(e, corr * BattleConfig.CORRUPTION_DAMAGE_PER_STACK)
			e.consume_status(S.CORRUPTION, BattleConfig.CORRUPTION_STACKS_CONSUMED)
			corruption_triggered = corr
			_log.append("Corruption x%d deals %d Dark damage to %s." % [corr, cdmg, e.display_name])
		if e.is_dead():
			return
		var spell := EnemyIntentSystem.pick_spell(state.enemy_defs[i], state.turn)
		if spell != null:
			SpellResolver.cast(spell, e, state.player, state, _log)
		else:
			_log.append("%s stands still." % e.display_name)

	end_turn_effects(e, _log)

	if corruption_triggered > 0:
		var heal := state.player.heal(corruption_triggered * BattleConfig.CORRUPTION_LIFESTEAL_PER_STACK)
		_log.append("Life steal: you restore %d HP." % heal)