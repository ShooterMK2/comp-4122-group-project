class_name SpellResolver
extends RefCounted

const K := SpellEffect.Kind
const S := StatusTypes.Status
const E := Elements.Element

# ---------- player side ----------
static func resolve_queue(queue: Array[QueuedSpell], state: BattleState,
		_log: Array[String]) -> int:
	var total := 0
	for q in queue:
		state.ensure_valid_target()
		if state.all_enemies_dead():
			_log.append("No targets left.")
			break
		total += resolve_spell(q, state, _log)
	return total

# A board spell: the caster is the player, the target is the selected enemy.
static func resolve_spell(q: QueuedSpell, state: BattleState, _log: Array[String]) -> int:
	return cast(q.definition, state.player, state.enemies[state.target_index], state, _log)

static func resolve_basic_attack(tile_count: int, state: BattleState,
		_log: Array[String]) -> int:
	state.ensure_valid_target()
	var target := state.enemies[state.target_index]
	if target.is_dead() or tile_count <= 0:
		return 0
	var dmg := DamageCalculator.basic_attack(tile_count, state.player, target)
	var res := target.take_damage(dmg)
	var dealt: int = res["hp"] + res["absorbed"]
	_log.append("Tiles on board: %d -> %d basic dmg to %s." % [tile_count, dealt, target.display_name])
	return dealt

# ---------- generic: anyone casts a spell ----------
# Order: 1 passive modifiers (Tailwind, Shatter, Conductive)  2 consumers (Detonate, Smite)
#        3 damage  4 Conductive splash  5 appliers (statuses, Fortify, Heal ...)
static func cast(d: SpellDefinition, caster: CombatantState, chosen: CombatantState,
		state: BattleState, _log: Array[String]) -> int:
	var target := caster if d.target_kind == SpellDefinition.TargetKind.SELF else chosen
	var elem := d.primary_element()
	var damaging := d.base_damage > 0
	var bonus := 0
	var conductive_hit := false
	var notes: Array[String] = []

	if damaging:
		var tw := caster.get_status(S.TAILWIND)
		if tw > 0 and elem in BattleConfig.TAILWIND_ELEMENTS:
			var b := tw * BattleConfig.TAILWIND_DAMAGE_PER_STACK
			caster.consume_status(S.TAILWIND, BattleConfig.TAILWIND_STACKS_CONSUMED)
			bonus += b
			notes.append("Tailwind x%d +%d" % [tw, b])
		var fr := target.get_status(S.FREEZE)
		if fr > 0 and elem in BattleConfig.SHATTER_ELEMENTS:
			var b2 := fr * BattleConfig.SHATTER_DAMAGE_PER_STACK
			target.consume_status(S.FREEZE)
			bonus += b2
			notes.append("SHATTER x%d +%d (unfrozen)" % [fr, b2])
		var cd := target.get_status(S.CONDUCTIVE)
		if cd > 0 and elem == E.LIGHTNING:
			var b3 := cd * BattleConfig.CONDUCTIVE_DAMAGE_PER_STACK
			target.consume_status(S.CONDUCTIVE, BattleConfig.CONDUCTIVE_STACKS_CONSUMED)
			bonus += b3
			conductive_hit = true
			notes.append("Conductive x%d +%d" % [cd, b3])

	for fx in d.effects:
		match fx.kind:
			K.DETONATE:
				var n := target.consume_status(S.BURN)
				bonus += n * fx.amount
				notes.append("Detonate %d Burn = +%d" % [n, n * fx.amount])
			K.SMITE:
				if caster.shield >= fx.amount:
					caster.shield -= fx.amount
					bonus += fx.amount * fx.amount2
					notes.append("Smite spent %d Shield = +%d" % [fx.amount, fx.amount * fx.amount2])
				else:
					notes.append("Smite fizzled (needs %d Shield)" % fx.amount)

	var final := DamageCalculator.finalize(d.base_damage + bonus, caster, target, elem,
		d.other_multiplier)
	var dealt := 0
	if final > 0:
		var res := target.take_damage(final)
		dealt = res["hp"] + res["absorbed"]

	if conductive_hit:
		for adj in state.adjacent_to(target):
			var splash := roundi(final * BattleConfig.CONDUCTIVE_SPLASH_RATIO)
			var r2 := adj.take_damage(splash)
			adj.add_status(S.CONDUCTIVE, 1)
			dealt += r2["hp"] + r2["absorbed"]
			notes.append("%s takes %d splash, now Conductive" % [adj.display_name, splash])

	var side: Array[String] = []
	for fx in d.effects:
		match fx.kind:
			K.BURN:
				dealt += StatusSystem.apply_status(target, S.BURN, fx.amount, side)
				notes.append("+%d Burn" % fx.amount)
			K.SELF_BURN:
				StatusSystem.apply_status(caster, S.BURN, fx.amount, side)
				notes.append("%s gains %d Burn" % [caster.display_name, fx.amount])
			K.CHILL:
				dealt += StatusSystem.apply_status(target, S.CHILL, fx.amount, side)
				notes.append("+%d Chill" % fx.amount)
			K.FORTIFY:
				caster.shield += fx.amount
				notes.append("+%d Shield" % fx.amount)
			K.TAILWIND:
				caster.add_status(S.TAILWIND, fx.amount)
				notes.append("+%d Tailwind" % fx.amount)
			K.DECAY:
				dealt += StatusSystem.apply_status(target, S.DECAY, fx.amount, side)
				notes.append("+%d Decay" % fx.amount)
			K.CONDUCTIVE:
				target.add_status(S.CONDUCTIVE, fx.amount)
				notes.append("+%d Conductive" % fx.amount)
			K.HEAL:
				notes.append("heals %d HP" % caster.heal(fx.amount))

	var on := "itself" if target == caster else target.display_name
	_log.append("%s casts %s on %s: %d dmg (base %d, bonus +%d)%s" % [
		caster.display_name, d.display_name, on, dealt, d.base_damage, bonus,
		(" | " + ", ".join(notes)) if not notes.is_empty() else ""])
	_log.append_array(side)
	return dealt

static func preview(queue: Array[QueuedSpell], tile_count: int, state: BattleState) -> Dictionary:
	var sim := state.duplicate_state()
	var lines: Array[String] = []
	var spell_damages: Array[int] = []
	var spells := 0
	for q in queue:
		sim.ensure_valid_target()
		if sim.all_enemies_dead():
			break
		var damage := resolve_spell(q, sim, lines)
		spell_damages.append(damage)
		spells += damage
	var basic := resolve_basic_attack(tile_count, sim, lines)
	var after: Array[Dictionary] = []
	for e in sim.enemies:
		after.append({"name": e.display_name, "hp": e.hp, "max_hp": e.max_hp})
	return {"spells": spells, "spell_damages": spell_damages, "basic": basic,
		"lines": lines, "enemies_after": after,
		"player_hp": sim.player.hp, "player_max_hp": sim.player.max_hp}