extends Node
# Autoload: persists gold, inventory, decks, and pre-battle modifiers for a run.

signal changed

var gold: int = 0
var loadout := EquipmentLoadout.new()
var pending := PendingBattleModifiers.new()
var story_flags: Dictionary = {}

var _items: Dictionary = {}  # StringName -> InventoryEntry for consumable/equipment/important
var _spells: Dictionary = {}  # StringName -> SpellDefinition (owned = deck)
var _spell_acquired: Dictionary = {}  # StringName -> int
var _fragments: Dictionary = {}  # StringName -> FragmentDefinition (bag)
var _fragment_acquired: Dictionary = {}  # StringName -> int
var _fragment_deck: Array[StringName] = []  # ordered deck ids (max RunConfig.FRAGMENT_DECK_SIZE)
var run_hp: int = 100
var _base_player: PlayerDefinition
var _acquire_seq: int = 0

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
	_fragments.clear()
	_fragment_acquired.clear()
	_fragment_deck.clear()
	_acquire_seq = 0
	_base_player = PlayerDefinition.default_player()
	_seed_starter()
	_sync_run_hp_to_max()
	changed.emit()

func _next_acquire_seq() -> int:
	_acquire_seq += 1
	return _acquire_seq

func _seed_starter() -> void:
	for spell in DemoSpellLibrary.build():
		_spells[spell.id] = spell
		_spell_acquired[spell.id] = _next_acquire_seq()
	for frag in StarterContent.fragments():
		_fragments[frag.id] = frag
		_fragment_acquired[frag.id] = _next_acquire_seq()
		_fragment_deck.append(frag.id)
	for eq in StarterContent.all_equipment():
		_add_entry(eq.id, ItemCategory.Kind.EQUIPMENT, 1, eq)
	loadout.equip(StarterContent.wooden_rod())
	_add_entry(&"minor_tonic", ItemCategory.Kind.CONSUMABLE, 2, StarterContent.minor_tonic())
	_add_entry(&"warding_charm", ItemCategory.Kind.CONSUMABLE, 1, StarterContent.warding_charm())
	_add_entry(&"sealed_letter", ItemCategory.Kind.IMPORTANT, 1, StarterContent.sealed_letter())
	_add_entry(&"blessed_sigil", ItemCategory.Kind.IMPORTANT, 1, StarterContent.blessed_sigil())

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
	return StatCalculator.build_snapshot(_base_player, loadout, pending)

func base_player() -> PlayerDefinition:
	return _base_player

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
	for spell in DemoSpellLibrary.build():
		# Preserve demo order while only including owned.
		if _spells.has(spell.id):
			out.append(_spells[spell.id])
	if out.is_empty():
		for spell in _spells.values():
			out.append(spell)
	return out

func owns_spell(id: StringName) -> bool:
	return _spells.has(id)

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

func clear_pending_after_battle() -> void:
	pending.clear()
	_clamp_run_hp()
	changed.emit()

func apply_pending_to_combatant(player: CombatantState) -> void:
	if pending.heal_amount > 0:
		player.heal(pending.heal_amount)
	# Shield / temp HP already reflected via snapshot construction.
