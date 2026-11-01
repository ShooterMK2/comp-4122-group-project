class_name BattleConfig
extends RefCounted
# ALL balance numbers live here. Tweak freely.

const E := Elements.Element
const BOARD_SIZE := Vector2i(10, 10)

# ---------- General ----------
const HAND_SIZE := 4                    # fragments drawn at the start of each turn
const BASIC_DAMAGE_PER_TILE := 1        # damage per tile left on the board when you Cast
const DOT_IGNORES_SHIELD := true        # Burn / Decay / Detonate bypass shield if true
const CONFIRM_ENEMY_ACTIONS := false    # Require confirmation before enemy actions
const OTHER_MULTIPLIER_DEFAULT := 1.0
const OTHER_MULTIPLIER_LOW := 0.20
const OTHER_MULTIPLIER_MEDIUM := 0.45
const OTHER_MULTIPLIER_HIGH := 0.90
const SPELL_ATTACK_FACTOR := 0.25
const DAMAGE_RANDOM_MIN := 0.90
const DAMAGE_RANDOM_MAX := 1.15
const ELEMENTAL_MULTIPLIER_DEFAULT := 1.0
const ELEMENTAL_MULTIPLIER_COUNTERED := 1.75
const ELEMENTAL_MULTIPLIER_COUNTERING := 0.65
const DEFENCE_MULTIPLIER_BASE := 100.0

# ---------- Fire ----------
const BURN_DAMAGE_PER_STACK := 2        # end of turn: stacks * this
const BURN_LOSS_PER_TURN := 1           # stacks lost after each tick
const DETONATE_THRESHOLD := 8           # Burn stacks that auto-detonate
const DETONATE_FIXED_DAMAGE := 20       # damage dealt by the auto-detonation

# ---------- Ice ----------
const CHILL_SPEED_REDUCTION_PER_STACK := 0.25 # -25% Speed per Chill stack (to discuss)
const CHILL_MIN_SPEED_FRACTION := 0.50        # Speed never drops below 50% of base
const CHILL_LOSS_PER_TURN := 1          # lost at end of the chilled unit's turn
const FREEZE_THRESHOLD := 3             # Chill consumed per conversion
const FREEZE_STACKS_PER_CONVERSION := 1
const FREEZE_LOSS_PER_SKIP := 1         # Freeze stacks lost each skipped turn
const SHATTER_DAMAGE_PER_STACK := 12    # bonus per Freeze stack consumed
const SHATTER_ELEMENTS := [E.FIRE, E.EARTH, E.WIND]   # spells that can Shatter

# ---------- Earth ----------
# Fortify amount and Smite cost / per-point damage are set per spell in DemoSpellLibrary.

# ---------- Wind ----------
const TAILWIND_DAMAGE_PER_STACK := 3    # bonus = this * current stacks
const TAILWIND_STACKS_CONSUMED := 1     # stacks used by the next spell
const TAILWIND_ELEMENTS := [E.FIRE, E.ICE, E.EARTH, E.WIND]  # "core" elements

# ---------- Lightning ----------
const CONDUCTIVE_DAMAGE_PER_STACK := 4  # bonus = this * stacks on the target
const CONDUCTIVE_STACKS_CONSUMED := 1
const CONDUCTIVE_SPLASH_RATIO := 0.5    # adjacent enemies take this share of the hit

# ---------- Dark ----------
const DECAY_DAMAGE_PER_STACK := 2       # end of turn: stacks * this
const DECAY_LOSS_PER_TURN := 0          # 0 = Decay persists until converted
const CORRUPTION_THRESHOLD := 4         # Decay consumed per conversion
const CORRUPTION_DAMAGE_PER_STACK := 6  # before the enemy acts: stacks * this
const CORRUPTION_STACKS_CONSUMED := 1   # stacks lost after triggering
const CORRUPTION_LIFESTEAL_PER_STACK := 3  # HP restored to the player per stack

# ---------- Deadlock: Backlash / Fizzle ----------
const BACKLASH_BASE_FRACTION := 0.10        # HP cost = this * max HP ...
const BACKLASH_PROGRESSION_FRACTION := 0.05 # ... + this * max HP per earlier Backlash this battle
const BACKLASH_MIN_HP_AFTER := 1            # Backlash is refused if it would leave you below this

# ---------- Speed / turn order ----------
const DUMMY_HEAL_PER_TURN := 10    # Mend: HP a dummy heals on each of its actions
