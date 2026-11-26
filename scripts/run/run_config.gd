class_name RunConfig
extends RefCounted

const STARTING_GOLD := 0
const FRAGMENT_DECK_SIZE := 12
const SPELL_DECK_SIZE := 18  # soft cap; owned spells can fill up to this
const HEALING_POTION_HEAL := 20
const PIECES_OF_HP_BONUS := 10
const PIECES_OF_ATK_BONUS := 1
const SHIELD_OF_HERO_BONUS := 3
const FIRE_BOOSTER_SPELL_BONUS := 0.20  # +20% fire spell damage
## Deprecated aliases kept for any stray references.
const MINOR_TONIC_HEAL := HEALING_POTION_HEAL
const BLESSED_SIGIL_MAX_HP_BONUS := PIECES_OF_HP_BONUS

# ---------- leveling ----------
const PLAYER_LEVEL_MIN := 1
const PLAYER_LEVEL_MAX := 120
const STAT_BAND_MAX := 500

const LEVEL_UP_HP := 8
const LEVEL_UP_ATTACK := 1
const LEVEL_UP_DEFENCE := 1
const LEVEL_UP_SPEED := 0.25

const BATTLE_XP_BASE := 12
const BATTLE_XP_PER_ENEMY_LEVEL := 4
const MILESTONE_ZONE_EXIT_XP := 60
const MILESTONE_NODE_XP := 15

# Soft overlevel combat curve (gap = encounter_level - player_level)
const OVERLEVEL_MILD_GAP := 5
const OVERLEVEL_HARSH_GAP := 18
const OVERLEVEL_PLAYER_DEALT_AT_HARSH := 0.4
const OVERLEVEL_DAMAGE_TAKEN_AT_HARSH := 2.0

const LEVEL_UP_GOLD_MIN := 15
const LEVEL_UP_GOLD_MAX := 40
const LEVEL_UP_HEAL_AMOUNT := 25
