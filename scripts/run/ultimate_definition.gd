class_name UltimateDefinition
extends Resource
# Player ultimate skill. Activated from the charge gauge in battle.

enum EffectKind {
	DAMAGE_BURST,    # Powerful Charge: charge-scaled damage multiplier for the turn
	EMERGENCY_AID,   # Heal % HP + shields (charge-scaled)
	FIGHTING_SPIRIT, # ATK+DEF+SPD buff for charge-scaled turns
	SHOCKWAVE,       # Crowd Control: fixed damage to all living enemies
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var effect_kind: EffectKind = EffectKind.DAMAGE_BURST

# DAMAGE_BURST — charge-scaled between min and max
@export var damage_mult_min: float = BattleConfig.ULTIMATE_MIN_MULTIPLIER
@export var damage_mult_max: float = BattleConfig.ULTIMATE_MAX_MULTIPLIER

# EMERGENCY_AID — percent of max HP heal + shields
@export var heal_percent_min: float = 0.15
@export var heal_percent_max: float = 0.30
@export var shield_min: int = 1
@export var shield_max: int = 4

# FIGHTING_SPIRIT
@export var buff_turns_min: int = 4
@export var buff_turns_max: int = 7

# SHOCKWAVE / Crowd Control — fixed damage (no ATK gear scaling)
@export var shockwave_base: int = 20
@export var shockwave_charge_bonus: int = 28

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
		EffectKind.EMERGENCY_AID:
			return "Heal %d%%–%d%% HP + %d–%d Shield" % [
				int(heal_percent_min * 100.0), int(heal_percent_max * 100.0),
				shield_min, shield_max]
		EffectKind.FIGHTING_SPIRIT:
			return "ATK/DEF/SPD up %d–%d turns" % [buff_turns_min, buff_turns_max]
		EffectKind.SHOCKWAVE:
			return "Hit all enemies (%d–%d fixed)" % [
				shockwave_base, shockwave_base + shockwave_charge_bonus]
	return "Ultimate"
