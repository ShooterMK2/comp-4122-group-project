class_name MinorEnemyLibrary
extends RefCounted
# Zone 1 minor enemies by primary terrain. Built in code (skills + weak/strong).
# Rule: if strengths.size() > 0 then weaknesses.size() >= 1. No weak/strong overlap.

const E := Elements.Element
const A := AilmentTypes.Ailment
const Tier := SkillDefinition.AttackTier
const TK := SkillDefinition.TargetKind

static func pool_for_primary(primary: String) -> Array[EnemyDefinition]:
	match primary.strip_edges():
		"Snow":
			return _snow()
		"Forest":
			return _forest()
		"Desert":
			return _desert()
		"Volcano":
			return _volcano()
		_:
			return _none()

static func human_bandit() -> EnemyDefinition:
	return _make("Human Bandit", Color(0.55, 0.35, 0.28), [E.FIRE, E.LIGHTNING], [], [
		SkillDefinition.make_attack(&"bandit_slash", "Bandit Slash", Tier.MEDIUM),
		SkillDefinition.make_support(&"dirty_feint", "Dirty Feint", TK.HOSTILE, [
			SkillEffect.stat_debuff(1, 3),
		]),
		SkillDefinition.make_attack(&"quick_stab", "Quick Stab", Tier.LIGHT),
	], {"hp": 0.95, "atk": 1.05, "def": 0.90, "spd": 1.05})

static func _none() -> Array[EnemyDefinition]:
	return [
		human_bandit(),
		_make("Stray Dog", Color(0.45, 0.4, 0.35), [E.ICE], [], [
			SkillDefinition.make_attack(&"nip", "Nip", Tier.LIGHT),
			SkillDefinition.make_ailment(&"hobble", "Hobble", A.SLOW, 3),
		], {"hp": 0.80, "atk": 1.00, "def": 0.75, "spd": 1.25}),
		_make("Field Slime", Color(0.35, 0.65, 0.35), [E.FIRE, E.WIND], [E.EARTH], [
			SkillDefinition.make_attack(&"blob_slap", "Blob Slap", Tier.MEDIUM),
			SkillDefinition.make_heal(&"ooze_mend", "Ooze Mend", 10),
		], {"hp": 1.25, "atk": 0.90, "def": 1.15, "spd": 0.75}),
		_make("Scarecrow Scout", Color(0.7, 0.6, 0.3), [E.FIRE], [E.WIND, E.EARTH], [
			SkillDefinition.make_support(&"rattle", "Rattle", TK.HOSTILE, [
				SkillEffect.stat_debuff(2, 2),
			]),
			SkillDefinition.make_attack(&"straw_jab", "Straw Jab", Tier.LIGHT),
		], {"hp": 0.75, "atk": 0.95, "def": 0.70, "spd": 1.15}),
		_make("Road Wisp", Color(0.75, 0.85, 1.0), [E.DARK], [E.LIGHTNING, E.WIND], [
			SkillDefinition.make_attack(&"spark_touch", "Spark Touch", Tier.LIGHT),
			SkillDefinition.make_ailment(&"static_snap", "Static Snap", A.SHOCK, 2),
		], {"hp": 0.70, "atk": 1.10, "def": 0.65, "spd": 1.30}),
		_make("Carrion Crow", Color(0.2, 0.2, 0.25), [E.LIGHTNING], [E.WIND, E.DARK], [
			SkillDefinition.make_attack(&"peck", "Peck", Tier.LIGHT),
			SkillDefinition.make_attack(&"peck2", "Peck", Tier.LIGHT),
			SkillDefinition.make_ailment(&"mark_prey", "Mark Prey", A.EXPOSE, 3),
		], {"hp": 0.85, "atk": 1.00, "def": 0.80, "spd": 1.20}),
	]

static func _snow() -> Array[EnemyDefinition]:
	return [
		_make("Frost Hare", Color(0.85, 0.9, 1.0), [E.FIRE], [E.ICE], [
			SkillDefinition.make_attack(&"frost_nip", "Frost Nip", Tier.LIGHT),
			SkillDefinition.make_ailment(&"chill_bind", "Chill Bind", A.SLOW, 3),
			SkillDefinition.make_attack(&"frost_nip2", "Frost Nip", Tier.LIGHT),
		], {"hp": 0.75, "atk": 1.05, "def": 0.70, "spd": 1.35}),
		_make("Ice Golem Shard", Color(0.55, 0.7, 0.9), [E.FIRE, E.LIGHTNING], [E.ICE, E.EARTH], [
			SkillDefinition.make_attack(&"shard_slam", "Shard Slam", Tier.MEDIUM),
			SkillDefinition.make_support(&"ice_armor", "Ice Armor", TK.SELF, [
				SkillEffect.stat_buff(1, 3),
			]),
		], {"hp": 1.30, "atk": 0.95, "def": 1.35, "spd": 0.65}),
		_make("Snow Stalker", Color(0.7, 0.75, 0.8), [E.FIRE], [E.ICE, E.WIND], [
			SkillDefinition.make_attack(&"ambush", "Ambush", Tier.MEDIUM),
			SkillDefinition.make_ailment(&"sapping_cold", "Sapping Cold", A.WEAKEN, 3),
		], {"hp": 0.95, "atk": 1.15, "def": 0.90, "spd": 1.15}),
		_make("Glacier Slug", Color(0.5, 0.7, 0.75), [E.FIRE, E.WIND], [E.ICE], [
			SkillDefinition.make_ailment(&"toxic_melt", "Toxic Melt", A.POISON, 3),
			SkillDefinition.make_heal(&"glacial_ooze", "Glacial Ooze", 12),
		], {"hp": 1.20, "atk": 0.85, "def": 1.10, "spd": 0.60}),
		_make("Rime Bat", Color(0.6, 0.65, 0.8), [E.LIGHTNING], [E.ICE, E.WIND], [
			SkillDefinition.make_attack(&"rime_bite", "Rime Bite", Tier.LIGHT),
			SkillDefinition.make_ailment(&"wing_shock", "Wing Shock", A.SHOCK, 2),
		], {"hp": 0.70, "atk": 1.00, "def": 0.70, "spd": 1.40}),
		_make("Frozen Marionette", Color(0.75, 0.8, 0.9), [E.FIRE], [E.ICE, E.DARK], [
			SkillDefinition.make_support(&"cut_strings", "Cut Strings", TK.HOSTILE, [
				SkillEffect.stat_debuff(0, 3),
			]),
			SkillDefinition.make_attack(&"puppet_slash", "Puppet Slash", Tier.LIGHT),
		], {"hp": 0.90, "atk": 0.95, "def": 0.95, "spd": 1.00}),
	]

static func _forest() -> Array[EnemyDefinition]:
	return [
		_make("Thorn Boar", Color(0.45, 0.55, 0.3), [E.FIRE, E.ICE], [E.EARTH], [
			SkillDefinition.make_attack(&"gore", "Gore", Tier.HEAVY),
			SkillDefinition.make_support(&"frenzy", "Frenzy", TK.SELF, [
				SkillEffect.stat_buff(0, 2),
			]),
		], {"hp": 1.15, "atk": 1.25, "def": 1.05, "spd": 0.90}),
		_make("Canopy Sprite", Color(0.4, 0.8, 0.5), [E.DARK, E.ICE], [E.WIND, E.EARTH], [
			SkillDefinition.make_heal(&"leaf_balm", "Leaf Balm", 14),
			SkillDefinition.make_attack(&"thorn_dart", "Thorn Dart", Tier.LIGHT),
		], {"hp": 0.80, "atk": 0.85, "def": 0.80, "spd": 1.20}),
		_make("Rootbound Horror", Color(0.35, 0.4, 0.25), [E.FIRE], [E.EARTH, E.DARK], [
			SkillDefinition.make_ailment(&"entangle", "Entangle", A.SLOW, 3),
			SkillDefinition.make_attack(&"root_lash", "Root Lash", Tier.MEDIUM),
		], {"hp": 1.20, "atk": 1.05, "def": 1.20, "spd": 0.70}),
		_make("Venom Asp", Color(0.3, 0.55, 0.35), [E.ICE], [E.EARTH], [
			SkillDefinition.make_ailment(&"venom", "Venom", A.POISON, 3),
			SkillDefinition.make_attack(&"fang", "Fang", Tier.LIGHT),
		], {"hp": 0.85, "atk": 1.10, "def": 0.85, "spd": 1.15}),
		_make("Owlkin Stalker", Color(0.4, 0.35, 0.3), [E.LIGHTNING], [E.WIND, E.DARK], [
			SkillDefinition.make_ailment(&"expose_prey", "Expose Prey", A.EXPOSE, 3),
			SkillDefinition.make_attack(&"talon", "Talon", Tier.MEDIUM),
		], {"hp": 0.90, "atk": 1.15, "def": 0.85, "spd": 1.20}),
		_make("Moss Golem", Color(0.3, 0.5, 0.3), [E.FIRE, E.WIND], [E.EARTH, E.ICE], [
			SkillDefinition.make_attack(&"boulder_fist", "Boulder Fist", Tier.MEDIUM),
			SkillDefinition.make_support(&"moss_shell", "Moss Shell", TK.SELF, [
				SkillEffect.stat_buff(1, 3),
			]),
		], {"hp": 1.35, "atk": 0.95, "def": 1.40, "spd": 0.60}),
	]

static func _desert() -> Array[EnemyDefinition]:
	return [
		_make("Dune Scarab", Color(0.7, 0.55, 0.25), [E.ICE], [E.FIRE, E.EARTH], [
			SkillDefinition.make_attack(&"carapace_bash", "Carapace Bash", Tier.MEDIUM),
			SkillDefinition.make_support(&"harden", "Harden", TK.SELF, [
				SkillEffect.stat_buff(1, 3),
			]),
		], {"hp": 1.20, "atk": 1.00, "def": 1.30, "spd": 0.80}),
		_make("Sand Serpent", Color(0.8, 0.65, 0.35), [E.ICE, E.WIND], [E.FIRE], [
			SkillDefinition.make_ailment(&"sand_venom", "Sand Venom", A.POISON, 3),
			SkillDefinition.make_attack(&"coil_strike", "Coil Strike", Tier.MEDIUM),
		], {"hp": 1.00, "atk": 1.15, "def": 0.95, "spd": 1.10}),
		_make("Mirage Jackal", Color(0.75, 0.6, 0.4), [E.ICE], [E.FIRE, E.WIND], [
			SkillDefinition.make_attack(&"mirage_bite", "Mirage Bite", Tier.LIGHT),
			SkillDefinition.make_support(&"heat_haze", "Heat Haze", TK.SELF, [
				SkillEffect.stat_buff(2, 2),
			]),
		], {"hp": 0.85, "atk": 1.05, "def": 0.80, "spd": 1.35}),
		_make("Cactus Brute", Color(0.4, 0.65, 0.3), [E.FIRE, E.ICE], [E.EARTH], [
			SkillDefinition.make_attack(&"spine_crash", "Spine Crash", Tier.HEAVY),
			SkillDefinition.make_ailment(&"needle_mark", "Needle Mark", A.EXPOSE, 3),
		], {"hp": 1.25, "atk": 1.20, "def": 1.15, "spd": 0.75}),
		_make("Dust Wraith", Color(0.65, 0.6, 0.5), [E.LIGHTNING], [E.DARK, E.WIND], [
			SkillDefinition.make_ailment(&"withering_dust", "Withering Dust", A.WEAKEN, 3),
			SkillDefinition.make_attack(&"dust_claw", "Dust Claw", Tier.LIGHT),
		], {"hp": 0.75, "atk": 1.00, "def": 0.70, "spd": 1.25}),
		_make("Sunbaked Skeleton", Color(0.9, 0.85, 0.7), [E.EARTH, E.WIND], [E.FIRE, E.DARK], [
			SkillDefinition.make_attack(&"bone_swing", "Bone Swing", Tier.MEDIUM),
			SkillDefinition.make_heal(&"bone_mend", "Bone Mend", 12),
		], {"hp": 1.05, "atk": 1.05, "def": 1.00, "spd": 0.95}),
	]

static func _volcano() -> Array[EnemyDefinition]:
	return [
		_make("Magma Beetle", Color(0.85, 0.35, 0.15), [E.ICE, E.WIND], [E.FIRE, E.EARTH], [
			SkillDefinition.make_attack(&"magma_ram", "Magma Ram", Tier.MEDIUM),
			SkillDefinition.make_attack(&"eruption_horn", "Eruption Horn", Tier.HEAVY),
			SkillDefinition.make_support(&"shell_heat", "Shell Heat", TK.SELF, [
				SkillEffect.stat_buff(1, 2),
			]),
		], {"hp": 1.20, "atk": 1.15, "def": 1.25, "spd": 0.80}),
		_make("Ember Imp", Color(0.95, 0.4, 0.2), [E.ICE], [E.FIRE, E.DARK], [
			SkillDefinition.make_attack(&"ember_poke", "Ember Poke", Tier.LIGHT),
			SkillDefinition.make_support(&"kindle", "Kindle", TK.SELF, [
				SkillEffect.stat_buff(0, 2),
			]),
		], {"hp": 0.70, "atk": 1.15, "def": 0.65, "spd": 1.40}),
		_make("Ash Elemental", Color(0.45, 0.4, 0.4), [E.ICE, E.WIND], [E.FIRE, E.LIGHTNING], [
			SkillDefinition.make_attack(&"ash_blast", "Ash Blast", Tier.MEDIUM),
			SkillDefinition.make_ailment(&"choking_ash", "Choking Ash", A.WEAKEN, 3),
		], {"hp": 1.05, "atk": 1.10, "def": 0.95, "spd": 1.00}),
		_make("Obsidian Crab", Color(0.2, 0.2, 0.25), [E.EARTH, E.LIGHTNING], [E.FIRE, E.ICE], [
			SkillDefinition.make_attack(&"obsidian_pinch", "Obsidian Pinch", Tier.MEDIUM),
			SkillDefinition.make_support(&"glass_shell", "Glass Shell", TK.SELF, [
				SkillEffect.stat_buff(1, 3),
			]),
		], {"hp": 1.30, "atk": 1.00, "def": 1.45, "spd": 0.55}),
		_make("Lava Skitter", Color(0.9, 0.45, 0.15), [E.ICE], [E.FIRE], [
			SkillDefinition.make_attack(&"skitter_bite", "Skitter Bite", Tier.LIGHT),
			SkillDefinition.make_ailment(&"spark_frenzy", "Spark Frenzy", A.SHOCK, 2),
		], {"hp": 0.75, "atk": 1.05, "def": 0.75, "spd": 1.35}),
		_make("Cinder Drake Pup", Color(0.8, 0.3, 0.2), [E.ICE], [E.FIRE, E.WIND, E.DARK], [
			SkillDefinition.make_attack(&"cinder_breath", "Cinder Breath", Tier.HEAVY),
			SkillDefinition.make_support(&"drake_rage", "Drake Rage", TK.SELF, [
				SkillEffect.stat_buff(0, 2),
			]),
		], {"hp": 1.15, "atk": 1.30, "def": 1.05, "spd": 1.05}),
	]

## mults: {hp, atk, def, spd} relative to level curve (1.0 = average).
static func _make(display_name: String, color: Color, weak: Array, strong: Array,
		skills: Array, mults: Dictionary = {}) -> EnemyDefinition:
	var e := EnemyDefinition.new()
	e.display_name = display_name
	e.rank = EnemyDefinition.Rank.MINOR
	e.max_hp = 60
	e.level = 1
	e.attack = 4
	e.defence = 2
	e.speed = 3.0
	e.art_name = "enemy_wooden_dummy.png"
	e.placeholder_color = color
	e.hp_mult = float(mults.get("hp", 1.0))
	e.attack_mult = float(mults.get("atk", 1.0))
	e.defence_mult = float(mults.get("def", 1.0))
	e.speed_mult = float(mults.get("spd", 1.0))
	e.elemental_weaknesses = _to_int_array(weak)
	e.elemental_strengths = _to_int_array(strong)
	if e.elemental_strengths.size() > 0 and e.elemental_weaknesses.is_empty():
		push_error("MinorEnemyLibrary: %s has strengths but no weakness" % display_name)
	for s in skills:
		if s is SkillDefinition:
			e.skills.append(s)
	return e

static func _to_int_array(raw: Array) -> Array[int]:
	var out: Array[int] = []
	for v in raw:
		out.append(int(v))
	return out
