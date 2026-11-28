extends Node
# Autoload: persists gold, inventory, decks, and pre-battle modifiers for a run.

signal changed
signal level_up_pending_changed

var gold: int = 0
var loadout := EquipmentLoadout.new()
var pending := PendingBattleModifiers.new()
var story_flags: Dictionary = {}

var _items: Dictionary = {}  # StringName -> InventoryEntry for consumable/equipment/important
var _spells: Dictionary = {}  # StringName -> SpellDefinition (owned bag)
var _spell_acquired: Dictionary = {}  # StringName -> int
var _spell_deck: Array[StringName] = []  # battle loadout (subset of owned)
var _fragments: Dictionary = {}  # StringName -> FragmentDefinition (bag)
var _fragment_acquired: Dictionary = {}  # StringName -> int
var _fragment_deck: Array[StringName] = []  # ordered deck ids (max RunConfig.FRAGMENT_DECK_SIZE)
var _ultimates: Dictionary = {}  # StringName -> UltimateDefinition
var _ultimate_acquired: Dictionary = {}  # StringName -> int
var equipped_ultimate_id: StringName = &""
var run_hp: int = 100
var _base_player: PlayerDefinition
var _acquire_seq: int = 0
var current_layer: int = -1 # records the Node (layer) currently on
var current_node_index: int = 0
var cleared_nodes: Array[String] = []
var pending_node_to_clear: String = ""
var map_seed: int = 0 # for Node generation
var morality: int = 0
var karma_pending: bool = false
var seen_events: Array[int] = []

# ---------- leveling (run-scoped) ----------
var player_level: int = RunConfig.PLAYER_LEVEL_MIN
var player_xp: int = 0
var level_bonus_max_hp: int = 0
var level_bonus_attack: int = 0
var level_bonus_defence: int = 0
var level_bonus_speed: float = 0.0
## Permanent start-of-battle shield from Importants (e.g. Shield of Hero).
var perm_start_shield: int = 0
var zone_id: int = 1
var zone_exit_claimed: bool = false
## early | mid | late — legacy; terrain bands own levels now
var pending_encounter_band: StringName = &"mid"
## Primary + secondary battle terrain — set by exploration before entering battle
var pending_primary_terrain: String = "None"
var pending_secondary_terrain: String = "Clearing"
## minor | elite | boss — map node encounter tier
var pending_encounter_tier: StringName = &"minor"
## "" | bandit | … — special encounter override (karma, events)
var pending_encounter_override: StringName = &""
## True when entering final map node (12_0) for zone-clear XP + screen
var pending_is_zone_finale: bool = false
## Last battle XP breakdown for Zone Cleared UI
var last_battle_xp: int = 0
var last_zone_bonus_xp: int = 0
## Queue of {level, stat_label, stat_text, offers: Array[LevelUpOffer]}
var _pending_level_ups: Array[Dictionary] = []

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	gold = RunConfig.STARTING_GOLD
	loadout = EquipmentLoadout.new()
	pending = PendingBattleModifiers.new()
	story_flags.clear()
	_items.clear()
	_spells.clear()
	_spell_acquired.clear()
	_spell_deck.clear()
	_fragments.clear()
	_fragment_acquired.clear()
	_fragment_deck.clear()
	_ultimates.clear()
	_ultimate_acquired.clear()
	equipped_ultimate_id = &""
	_acquire_seq = 0
	player_level = RunConfig.PLAYER_LEVEL_MIN
	player_xp = 0
	level_bonus_max_hp = 0
	level_bonus_attack = 0
	level_bonus_defence = 0
	level_bonus_speed = 0.0
	perm_start_shield = 0
	zone_id = 1
	zone_exit_claimed = false
	pending_encounter_band = &"mid"
	pending_primary_terrain = "None"
	pending_secondary_terrain = "Clearing"
	pending_encounter_tier = &"minor"
	pending_encounter_override = &""
	pending_is_zone_finale = false
	last_battle_xp = 0
	last_zone_bonus_xp = 0
	_pending_level_ups.clear()
	_base_player = PlayerDefinition.default_player()
	_seed_starter()
	_sync_run_hp_to_max()
	changed.emit()
	level_up_pending_changed.emit()
	map_seed = randi()
	morality = 0
	karma_pending = false
	seen_events.clear()

func _next_acquire_seq() -> int:
	_acquire_seq += 1
	return _acquire_seq

func _seed_starter() -> void:
	for spell in DemoSpellLibrary.build():
		_spells[spell.id] = spell
		_spell_acquired[spell.id] = _next_acquire_seq()
		if _spell_deck.size() < RunConfig.SPELL_DECK_SIZE:
			_spell_deck.append(spell.id)
	for frag in StarterContent.fragments():
		_fragments[frag.id] = frag
		_fragment_acquired[frag.id] = _next_acquire_seq()
		_fragment_deck.append(frag.id)
	for eq in StarterContent.all_equipment():
		_add_entry(eq.id, ItemCategory.Kind.EQUIPMENT, 1, eq)
	# Chapter 1: own gear but start unequipped (1A). All catalog items owned for testing.
	_add_entry(&"healing_potion", ItemCategory.Kind.CONSUMABLE, 5, StarterContent.healing_potion())
	_add_entry(&"greater_healing_potion", ItemCategory.Kind.CONSUMABLE, 3, StarterContent.greater_healing_potion())
	_add_entry(&"protective_ring", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.protective_ring())
	_add_entry(&"barrier_charm", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.barrier_charm())
	_add_entry(&"fire_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.fire_booster())
	_add_entry(&"ice_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.ice_booster())
	_add_entry(&"earth_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.earth_booster())
	_add_entry(&"wind_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.wind_booster())
	_add_entry(&"lightning_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.lightning_booster())
	_add_entry(&"dark_booster", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.dark_booster())
	_add_entry(&"strength_tonic", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.strength_tonic())
	_add_entry(&"iron_skin_elixir", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.iron_skin_elixir())
	_add_entry(&"swift_draft", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.swift_draft())
	_add_entry(&"vitality_draft", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.vitality_draft())
	_add_entry(&"pieces_of_hp", ItemCategory.Kind.CONSUMABLE, 1, StarterContent.pieces_of_hp())
	_add_entry(&"pieces_of_atk", ItemCategory.Kind.CONSUMABLE, 1, StarterContent.pieces_of_atk())
	_add_entry(&"pieces_of_def", ItemCategory.Kind.CONSUMABLE, 1, StarterContent.pieces_of_def())
	_add_entry(&"pieces_of_spd", ItemCategory.Kind.CONSUMABLE, 1, StarterContent.pieces_of_spd())
	_add_entry(&"gold_dust", ItemCategory.Kind.CONSUMABLE, 3, StarterContent.gold_dust())
	_add_entry(&"sealed_letter", ItemCategory.Kind.IMPORTANT, 1, StarterContent.sealed_letter())
	_add_entry(&"shield_of_hero", ItemCategory.Kind.IMPORTANT, 1, StarterContent.shield_of_hero())
	for ult in UltimateLibrary.all():
		_ultimates[ult.id] = ult
		_ultimate_acquired[ult.id] = _next_acquire_seq()
	equipped_ultimate_id = &""

func _add_entry(id: StringName, category: int, qty: int, ref: Resource) -> void:
	var seq := _next_acquire_seq()
	if _items.has(id):
		var entry: InventoryEntry = _items[id]
		entry.quantity += qty
		entry.acquired_at = seq  # restack counts as a fresh get
	else:
		_items[id] = InventoryEntry.new(id, category, qty, ref, seq)

func _sync_run_hp_to_max() -> void:
	run_hp = run_max_hp()

func run_max_hp() -> int:
	return snapshot().max_hp()

func snapshot() -> PlayerStatSnapshot:
	return StatCalculator.build_snapshot(_base_player, loadout, pending, level_bonuses(),
		player_level, perm_start_shield)

func level_bonuses() -> Dictionary:
	return {
		"max_hp": level_bonus_max_hp,
		"attack": level_bonus_attack,
		"defence": level_bonus_defence,
		"speed": level_bonus_speed,
	}

func xp_to_next() -> int:
	if player_level >= RunConfig.PLAYER_LEVEL_MAX:
		return 0
	return LevelProgression.xp_to_next(player_level)

func base_player() -> PlayerDefinition:
	return _base_player

# ---------- XP / level-up ----------
func add_xp(amount: int) -> int:
	if amount <= 0 or player_level >= RunConfig.PLAYER_LEVEL_MAX:
		return 0
	player_xp += amount
	var levels_gained := 0
	while player_level < RunConfig.PLAYER_LEVEL_MAX:
		var need := LevelProgression.xp_to_next(player_level)
		if player_xp < need:
			break
		player_xp -= need
		player_level += 1
		levels_gained += 1
		_queue_level_up(player_level)
	if player_level >= RunConfig.PLAYER_LEVEL_MAX:
		player_xp = 0
	if levels_gained > 0:
		_clamp_run_hp()
		level_up_pending_changed.emit()
	changed.emit()
	return levels_gained

func grant_battle_xp(enemy_defs: Array) -> int:
	last_battle_xp = LevelProgression.battle_xp_for_enemies(enemy_defs)
	return add_xp(last_battle_xp)

func grant_milestone_xp(amount: int = RunConfig.MILESTONE_NODE_XP) -> int:
	return add_xp(amount)

func claim_zone_exit_xp() -> int:
	if zone_exit_claimed:
		last_zone_bonus_xp = 0
		return 0
	zone_exit_claimed = true
	last_zone_bonus_xp = RunConfig.MILESTONE_ZONE_EXIT_XP
	return grant_milestone_xp(last_zone_bonus_xp)

func clear_battle_encounter_flags() -> void:
	pending_encounter_tier = &"minor"
	pending_encounter_override = &""
	pending_is_zone_finale = false


func has_pending_level_ups() -> bool:
	return not _pending_level_ups.is_empty()

func peek_pending_level_up() -> Dictionary:
	if _pending_level_ups.is_empty():
		return {}
	return _pending_level_ups[0]

func _queue_level_up(new_level: int) -> void:
	var stats := LevelProgression.pick_level_up_stats(new_level)
	for stat in stats:
		_apply_guaranteed_stat(stat)
	var offers := LevelProgression.roll_non_stat_offers(self, 3)
	var parts: PackedStringArray = PackedStringArray()
	for stat in stats:
		parts.append(LevelProgression.format_stat_text(stat))
	var stat_text := ", ".join(parts)
	_pending_level_ups.append({
		"level": new_level,
		"stat_label": str(stats[0]["label"]) if not stats.is_empty() else "",
		"stat_text": stat_text,
		"offers": offers,
	})

func _apply_guaranteed_stat(stat: Dictionary) -> void:
	match int(stat["kind"]):
		LevelProgression.StatKind.MAX_HP:
			level_bonus_max_hp += int(stat["amount_i"])
		LevelProgression.StatKind.ATTACK:
			level_bonus_attack += int(stat["amount_i"])
		LevelProgression.StatKind.DEFENCE:
			level_bonus_defence += int(stat["amount_i"])
		LevelProgression.StatKind.SPEED:
			level_bonus_speed += float(stat["amount_f"])

func choose_level_up_offer(offer_index: int) -> String:
	if _pending_level_ups.is_empty():
		return "No pending level-up."
	var entry: Dictionary = _pending_level_ups[0]
	var offers: Array = entry.get("offers", [])
	if offer_index < 0 or offer_index >= offers.size():
		return "Invalid offer."
	var offer: LevelUpOffer = offers[offer_index]
	var err := _apply_level_up_offer(offer)
	if err != "":
		return err
	_pending_level_ups.remove_at(0)
	_clamp_run_hp()
	changed.emit()
	level_up_pending_changed.emit()
	return ""

func _apply_level_up_offer(offer: LevelUpOffer) -> String:
	match offer.kind:
		LevelUpOffer.Kind.GOLD:
			add_gold(offer.amount)
		LevelUpOffer.Kind.HEAL:
			heal_run_hp(offer.amount)
		LevelUpOffer.Kind.CONSUMABLE:
			var cons := StarterContent.consumable_by_id(offer.item_id)
			if cons == null:
				return "Unknown consumable."
			_add_entry(cons.id, ItemCategory.Kind.CONSUMABLE, 1, cons)
		LevelUpOffer.Kind.FRAGMENT:
			var frag := _reward_fragment_by_id(offer.item_id)
			if frag == null:
				return "Unknown fragment."
			if _fragments.has(frag.id):
				return "Fragment already owned."
			_fragments[frag.id] = frag
			_fragment_acquired[frag.id] = _next_acquire_seq()
		LevelUpOffer.Kind.SPELL:
			var spell := _reward_spell_by_id(offer.item_id)
			if spell == null:
				return "Unknown spell."
			if _spells.has(spell.id):
				return "Spell already owned."
			_spells[spell.id] = spell
			_spell_acquired[spell.id] = _next_acquire_seq()
		_:
			return "Unknown offer."
	return ""

func _reward_fragment_by_id(id: StringName) -> FragmentDefinition:
	for f in StarterContent.reward_fragments():
		if f.id == id:
			return f
	return null

func _reward_spell_by_id(id: StringName) -> SpellDefinition:
	for s in StarterContent.reward_spells():
		if s.id == id:
			return s
	return null

func owns_fragment(id: StringName) -> bool:
	return _fragments.has(id)

# ---------- gold ----------
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	changed.emit()

func can_afford(amount: int) -> bool:
	return gold >= amount

func spend_gold(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	gold -= amount
	changed.emit()
	return true

# ---------- HP between battles ----------
func heal_run_hp(amount: int) -> int:
	var before := run_hp
	run_hp = mini(run_max_hp(), run_hp + maxi(0, amount))
	changed.emit()
	return run_hp - before

func set_run_hp(value: int) -> void:
	run_hp = clampi(value, 0, run_max_hp())
	changed.emit()

# ---------- inventory queries ----------
func list_entries(filter: int = -1) -> Array[InventoryEntry]:
	var out: Array[InventoryEntry] = []
	for entry in _items.values():
		var e: InventoryEntry = entry
		if filter < 0 or e.category == filter:
			out.append(e)
	if filter < 0 or filter == ItemCategory.Kind.SPELL:
		for spell in _spells.values():
			var s: SpellDefinition = spell
			var seq: int = int(_spell_acquired.get(s.id, 0))
			out.append(InventoryEntry.new(s.id, ItemCategory.Kind.SPELL, 1, s, seq))
	if filter < 0 or filter == ItemCategory.Kind.FRAGMENT:
		for frag_id in _fragments.keys():
			var f: FragmentDefinition = _fragments[frag_id]
			var seq: int = int(_fragment_acquired.get(frag_id, 0))
			out.append(InventoryEntry.new(f.id, ItemCategory.Kind.FRAGMENT, 1, f, seq))
	if filter < 0 or filter == ItemCategory.Kind.ULTIMATE:
		for ult_id in _ultimates.keys():
			var u: UltimateDefinition = _ultimates[ult_id]
			var seq: int = int(_ultimate_acquired.get(ult_id, 0))
			out.append(InventoryEntry.new(u.id, ItemCategory.Kind.ULTIMATE, 1, u, seq))
	out.sort_custom(_sort_entries)
	return out

func _sort_entries(a: InventoryEntry, b: InventoryEntry) -> bool:
	var ra := ItemCategory.group_rank(a.category)
	var rb := ItemCategory.group_rank(b.category)
	if ra != rb:
		return ra < rb
	if a.acquired_at != b.acquired_at:
		return a.acquired_at > b.acquired_at  # newest first within group
	return a.display_name() < b.display_name()

func get_item(id: StringName) -> InventoryEntry:
	return _items.get(id, null) as InventoryEntry

func remove_item(id: StringName, category: int, qty: int = 1) -> bool:
	if not _items.has(id):
		return false
	var entry: InventoryEntry = _items[id]
	if entry.category != category:
		return false
	entry.quantity -= qty
	if entry.quantity <= 0:
		_items.erase(id)
	changed.emit()
	return true

func set_story_flag(flag: StringName, value: bool = true) -> void:
	story_flags[flag] = value
	changed.emit()

# ---------- equipment ----------
func equip_item(id: StringName) -> String:
	var entry := get_item(id)
	if entry == null or entry.category != ItemCategory.Kind.EQUIPMENT:
		return "Not equipment."
	var eq := entry.ref as EquipmentDefinition
	if eq == null:
		return "Invalid equipment."
	var previous := loadout.equip(eq)
	if previous != null and previous.id != eq.id and not _items.has(previous.id):
		_add_entry(previous.id, ItemCategory.Kind.EQUIPMENT, 1, previous)
	# Keep owned copy; equipment stays in bag while equipped (quantity 1).
	_clamp_run_hp()
	changed.emit()
	return ""

func unequip_slot(slot: int) -> String:
	var previous := loadout.unequip(slot)
	if previous == null:
		return "Nothing equipped."
	if not _items.has(previous.id):
		_add_entry(previous.id, ItemCategory.Kind.EQUIPMENT, 1, previous)
	_clamp_run_hp()
	changed.emit()
	return ""

func is_equipped(id: StringName) -> bool:
	for item in loadout.all_equipped():
		if item.id == id:
			return true
	return false

func _clamp_run_hp() -> void:
	run_hp = mini(run_hp, run_max_hp())

# ---------- spells ----------
func spell_deck() -> Array[SpellDefinition]:
	var out: Array[SpellDefinition] = []
	for id in _spell_deck:
		if _spells.has(id):
			out.append(_spells[id])
	return out

func spell_deck_count() -> int:
	return _spell_deck.size()

func owns_spell(id: StringName) -> bool:
	return _spells.has(id)

func is_in_spell_deck(id: StringName) -> bool:
	return _spell_deck.has(id)

func add_to_spell_deck(id: StringName) -> String:
	if not _spells.has(id):
		return "Spell not owned."
	if _spell_deck.has(id):
		return "Already in deck."
	if _spell_deck.size() >= RunConfig.SPELL_DECK_SIZE:
		return "Deck is full (%d)." % RunConfig.SPELL_DECK_SIZE
	_spell_deck.append(id)
	changed.emit()
	return ""

func remove_from_spell_deck(id: StringName) -> String:
	var idx := _spell_deck.find(id)
	if idx < 0:
		return "Not in deck."
	if _spell_deck.size() <= 1:
		return "Keep at least one spell in the deck."
	_spell_deck.remove_at(idx)
	changed.emit()
	return ""

# ---------- fragments ----------
func fragment_bag() -> Array[FragmentDefinition]:
	var out: Array[FragmentDefinition] = []
	for f in _fragments.values():
		out.append(f)
	out.sort_custom(func(a: FragmentDefinition, b: FragmentDefinition) -> bool:
		return a.display_name < b.display_name)
	return out

func fragment_deck_defs() -> Array[FragmentDefinition]:
	var out: Array[FragmentDefinition] = []
	for id in _fragment_deck:
		if _fragments.has(id):
			out.append(_fragments[id])
	return out

func fragment_deck_count() -> int:
	return _fragment_deck.size()

func is_in_fragment_deck(id: StringName) -> bool:
	return _fragment_deck.has(id)

func add_to_fragment_deck(id: StringName) -> String:
	if not _fragments.has(id):
		return "Fragment not owned."
	if _fragment_deck.has(id):
		return "Already in deck."
	if _fragment_deck.size() >= RunConfig.FRAGMENT_DECK_SIZE:
		return "Deck is full (%d)." % RunConfig.FRAGMENT_DECK_SIZE
	_fragment_deck.append(id)
	changed.emit()
	return ""

func remove_from_fragment_deck(id: StringName) -> String:
	var idx := _fragment_deck.find(id)
	if idx < 0:
		return "Not in deck."
	_fragment_deck.remove_at(idx)
	changed.emit()
	return ""

func autofill_fragment_deck() -> void:
	if _fragment_deck.size() >= RunConfig.FRAGMENT_DECK_SIZE:
		return
	for id in _fragments.keys():
		if _fragment_deck.size() >= RunConfig.FRAGMENT_DECK_SIZE:
			break
		if not _fragment_deck.has(id):
			_fragment_deck.append(id)
	changed.emit()

func create_battle_draw() -> FragmentDeckDraw:
	var draw := FragmentDeckDraw.new()
	draw.setup_from_definitions(fragment_deck_defs())
	return draw

# ---------- ultimates ----------
func owns_ultimate(id: StringName) -> bool:
	return _ultimates.has(id)

func is_ultimate_equipped(id: StringName) -> bool:
	return equipped_ultimate_id == id

func equipped_ultimate() -> UltimateDefinition:
	if equipped_ultimate_id == &"" or not _ultimates.has(equipped_ultimate_id):
		return null
	return _ultimates[equipped_ultimate_id]

func equip_ultimate(id: StringName) -> String:
	if id == &"":
		equipped_ultimate_id = &""
		changed.emit()
		return ""
	if not _ultimates.has(id):
		return "Ultimate not owned."
	equipped_ultimate_id = id
	changed.emit()
	return ""

func clear_ultimate() -> void:
	equipped_ultimate_id = &""
	changed.emit()

func clear_pending_after_battle() -> void:
	pending.clear()
	clear_battle_encounter_flags()
	_clamp_run_hp()
	changed.emit()

func apply_pending_to_combatant(player: CombatantState) -> void:
	if pending.heal_amount > 0:
		player.heal(pending.heal_amount)
	# Shield / temp HP already reflected via snapshot construction.
