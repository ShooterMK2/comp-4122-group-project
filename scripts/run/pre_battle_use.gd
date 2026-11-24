class_name PreBattleUse
extends RefCounted

## Usable anytime from inventory; battle-bound effects apply on the next fight.

static func is_usable_kind(entry: InventoryEntry) -> bool:
	if entry == null or entry.ref == null:
		return false
	if entry.category == ItemCategory.Kind.CONSUMABLE:
		return entry.ref is ConsumableDefinition
	if entry.category == ItemCategory.Kind.IMPORTANT:
		var imp := entry.ref as ImportantDefinition
		return imp != null and imp.usable
	return false

static func can_use(entry: InventoryEntry, run: Node, _unused: bool = true) -> String:
	if not is_usable_kind(entry):
		return "—"
	if entry.category == ItemCategory.Kind.CONSUMABLE:
		var c := entry.ref as ConsumableDefinition
		return _can_apply(c.use_effect, c.use_amount, run)
	var imp := entry.ref as ImportantDefinition
	return _can_apply(imp.use_effect, imp.use_amount, run)

static func _can_apply(effect: int, amount: int, run: Node) -> String:
	match effect:
		UseEffect.Kind.HEAL_HP:
			if run.run_hp >= run.run_max_hp():
				return "HP is already full."
			if amount <= 0:
				return "—"
			return ""
		UseEffect.Kind.START_SHIELD, UseEffect.Kind.TEMP_MAX_HP, \
		UseEffect.Kind.TEMP_ATK, UseEffect.Kind.TEMP_DEF, UseEffect.Kind.TEMP_SPD:
			return ""
		_:
			return "—"

static func use(entry: InventoryEntry, run: Node) -> String:
	var err := can_use(entry, run)
	if not err.is_empty():
		return err
	if entry.category == ItemCategory.Kind.CONSUMABLE:
		var c := entry.ref as ConsumableDefinition
		_apply(c.use_effect, c.use_amount, run)
		run.remove_item(entry.id, ItemCategory.Kind.CONSUMABLE, 1)
		return ""
	if entry.category == ItemCategory.Kind.IMPORTANT:
		var imp := entry.ref as ImportantDefinition
		_apply(imp.use_effect, imp.use_amount, run)
		if not imp.story_flag.is_empty():
			run.set_story_flag(imp.story_flag, true)
		if imp.consumed_on_use:
			run.remove_item(entry.id, ItemCategory.Kind.IMPORTANT, 1)
		return ""
	return "—"

static func _apply(effect: int, amount: int, run: Node) -> void:
	match effect:
		UseEffect.Kind.HEAL_HP:
			run.heal_run_hp(amount)
		UseEffect.Kind.START_SHIELD:
			run.pending.start_shield += amount
		UseEffect.Kind.TEMP_MAX_HP:
			run.pending.temp_max_hp += amount
			run.heal_run_hp(amount)
		UseEffect.Kind.TEMP_ATK:
			run.pending.item_attack += amount
		UseEffect.Kind.TEMP_DEF:
			run.pending.item_defence += amount
		UseEffect.Kind.TEMP_SPD:
			run.pending.item_speed += float(amount)
