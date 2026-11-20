class_name UltimateDefinition
extends Resource
# Player ultimate skill. Activated from the charge gauge in battle.

enum EffectKind {
	DAMAGE_BURST,  # existing: charge-scaled damage multiplier for the rest of the turn
	SECOND_WIND,   # heal (+ optional shield)
	IRON_WARD,     # large shield
	BLOODLUST,     # ATK buff for several turns (+ mild damage mult)
	SHOCKWAVE,     # instant damage to all living enemies (scaled by charge)
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var effect_kind: EffectKind = EffectKind.DAMAGE_BURST

# DAMAGE_BURST / BLOODLUST mild mult — charge-scaled between min and max
@export var damage_mult_min: float = BattleConfig.ULTIMATE_MIN_MULTIPLIER
@export var damage_mult_max: float = BattleConfig.ULTIMATE_MAX_MULTIPLIER

# SECOND_WIND
@export var heal_base: int = 25
@export var heal_charge_bonus: int = 35  # added at full overflow charge
@export var heal_shield: int = 0

# IRON_WARD
@export var ward_shield: int = 4

# BLOODLUST
@export var buff_turns: int = 3

# SHOCKWAVE — flat damage before ATK scaling feel; charge adds more
@export var shockwave_base: int = 18
@export var shockwave_charge_bonus: int = 22

static func make(p_id: StringName, p_name: String, p_desc: String,
		kind: EffectKind) -> UltimateDefinition:
	var u := UltimateDefinition.new()
	u.id = p_id
	u.display_name = p_name
	u.description = p_desc
	u.effect_kind = kind
	return u

func inventory_preview_text() -> String:
	var kind_line := effect_label()
	if description.strip_edges().is_empty():
		return kind_line
	return "%s\n%s" % [kind_line, description]

func effect_label() -> String:
	match effect_kind:
		EffectKind.DAMAGE_BURST:
			return "Damage Burst (%.2fx–%.2fx this turn)" % [damage_mult_min, damage_mult_max]
		EffectKind.SECOND_WIND:
			return "Heal %d–%d HP%s" % [
				heal_base, heal_base + heal_charge_bonus,
				(" +%d Shield" % heal_shield) if heal_shield > 0 else ""]
		EffectKind.IRON_WARD:
			return "Gain %d Shield" % ward_shield
		EffectKind.BLOODLUST:
			return "ATK up %d turns + mild damage burst" % buff_turns
		EffectKind.SHOCKWAVE:
			return "Hit all enemies (%d–%d base)" % [
				shockwave_base, shockwave_base + shockwave_charge_bonus]
	return "Ultimate"
