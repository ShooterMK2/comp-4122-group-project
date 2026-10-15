class_name TurnSystem
extends RefCounted

const S := StatusTypes.Status

static func start_player_turn(state: BattleState) -> void:
	state.turn += 1

# END of a unit's turn: Burn, Decay, then natural stack loss.
static func end_turn_effects(c: CombatantState, log: Array[String]) -> void:
	var burn := c.get_status(S.BURN)
	if burn > 0:
		var dmg := StatusSystem.deal_direct(c, burn * BattleConfig.BURN_DAMAGE_PER_STACK)
		c.consume_status(S.BURN, BattleConfig.BURN_LOSS_PER_TURN)
		log.append("%s takes %d Burn damage." % [c.display_name, dmg])
	var decay := c.get_status(S.DECAY)
	if decay > 0:
		var dmg2 := StatusSystem.deal_direct(c, decay * BattleConfig.DECAY_DAMAGE_PER_STACK)
		c.consume_status(S.DECAY, BattleConfig.DECAY_LOSS_PER_TURN)
		log.append("%s takes %d Decay damage." % [c.display_name, dmg2])
	c.consume_status(S.CHILL, BattleConfig.CHILL_LOSS_PER_TURN)

static func run_enemies_turn(state: BattleState, log: Array[String]) -> void:
	for i in state.enemies.size():
		if state.player.is_dead():
			return
		if state.enemies[i].is_dead():
			continue
		_run_enemy(state, i, log)

static func _run_enemy(state: BattleState, i: int, log: Array[String]) -> void:
	var e := state.enemies[i]
	var corruption_triggered := 0

	if e.get_status(S.FREEZE) > 0:
		e.consume_status(S.FREEZE, BattleConfig.FREEZE_LOSS_PER_SKIP)
		log.append("%s is Frozen and skips its turn (no Corruption trigger)." % e.display_name)
	else:
		var corr := e.get_status(S.CORRUPTION)
		if corr > 0:
			var cdmg := StatusSystem.deal_direct(e, corr * BattleConfig.CORRUPTION_DAMAGE_PER_STACK)
			e.consume_status(S.CORRUPTION, BattleConfig.CORRUPTION_STACKS_CONSUMED)
			corruption_triggered = corr
			log.append("Corruption x%d deals %d Dark damage to %s." % [corr, cdmg, e.display_name])
		if e.is_dead():
			return
		var intent := EnemyIntentSystem.get_intent(state.enemy_defs[i], state.turn)
		if intent["damage"] > 0:
			var dmg := DamageCalculator.finalize(intent["damage"], e)
			var res := state.player.take_damage(dmg)
			log.append("%s uses %s: %d dmg (%d blocked, %d HP lost)." % [
				e.display_name, intent["name"], dmg, res["absorbed"], res["hp"]])
		else:
			log.append("%s: %s." % [e.display_name, intent["name"]])

	end_turn_effects(e, log)

	if corruption_triggered > 0:
		var heal := state.player.heal(corruption_triggered * BattleConfig.CORRUPTION_LIFESTEAL_PER_STACK)
		log.append("Life steal: you restore %d HP." % heal)