class_name BattleSetup
extends RefCounted
# Builds a BattleSession from the run: RunState (stats, gear, HP, decks) + an encounter.


static func create(encounter: EncounterDefinition) -> BattleSession:
	if encounter == null:
		push_error("BattleSetup: no encounter given.")
		return null
	var defs := encounter.make_enemies()
	if defs.is_empty():
		push_error("BattleSetup: encounter '%s' has no enemies." % encounter.id)
		return null
	var state := BattleState.new(defs, encounter.make_terrain())
	_apply_player(state)
	return BattleSession.new(state, _fragment_draw(), spell_loadout())


# The spells the player carries into battle: RunState's spell deck, capped at
# RunConfig.SPELL_DECK_SIZE (the cap itself is set in run_config.gd).
static func spell_loadout() -> Array[SpellDefinition]:
	var out: Array[SpellDefinition] = []
	var cap: int = RunConfig.SPELL_DECK_SIZE
	for spell in RunState.spell_deck():
		if out.size() >= cap:
			push_warning("Spell deck has more than %d spells; extras are left out of battle." % cap)
			break
		out.append(spell)
	return out


static func _fragment_draw() -> FragmentDeckDraw:
	if RunState.fragment_deck_count() == 0:
		push_warning("Fragment deck is empty; autofilling it from the bag.")
		RunState.autofill_fragment_deck()
	return RunState.create_battle_draw()


# The default BattleState builds a placeholder player from default_player(); replace it
# with the real one: stats from RunState.snapshot(), carried HP, start shield, pending heal.
static func _apply_player(state: BattleState) -> void:
	var snap := RunState.snapshot()
	var player := CombatantState.new(snap.display_name, snap.max_hp(), snap.level,
			snap.attack(), snap.defence())
	player.elemental_weaknesses = snap.elemental_weaknesses.duplicate()
	player.elemental_strengths = snap.elemental_strengths.duplicate()
	player.is_player = true
	player.hp = clampi(RunState.run_hp, 1, player.max_hp)
	player.shield = snap.start_shield
	RunState.apply_pending_to_combatant(player)
	state.player = player
	state.player_speed = snap.speed()
	# Overlevel gap: the player compares against the strongest enemy, enemies against the player.
	var top_level := 1
	for enemy in state.enemies:
		top_level = maxi(top_level, enemy.level)
		enemy.is_player = false
		enemy.compare_level = snap.level
	player.compare_level = top_level
