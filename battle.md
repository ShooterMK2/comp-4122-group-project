# Current Battle Mechanics

This is a human-readable reference for mechanics that currently function in
the playable Godot battle prototype. It describes the implementation, not
planned features.

## 1. Battle overview

| Item | Current implementation |
|---|---|
| Battle structure | Rounds; every living combatant acts once per round |
| Turn order | Highest effective Speed first |
| Speed ties | Player first, then lower enemy slot |
| Reordering | Remaining actors are re-sorted after every spell/action |
| Victory | All enemies reach 0 HP |
| Defeat | Player reaches 0 HP |
| Test encounter | Player plus three Wooden Dummies |
| Player defaults | 100 HP, 5 ATK, 3 DEF, 4 SPD |
| Wooden Dummy defaults | 60 HP, 1 ATK, 1 DEF, 0 SPD |
| Dummy action | **Mend**: heals itself for 10 HP |

### Effective Speed

For each combatant:

```text
Effective Speed =
    Base Speed
    × temporary Speed multiplier
    × max(1 - Chill stacks × 0.25, 0.50)
    × terrain Speed multiplier
```

The Chill term applies only when the combatant has Chill. A Speed buff or
debuff changes the order immediately when the order is refreshed.

## 2. Round and turn flow

```text
Start round
  -> sort living combatants by effective Speed
  -> take the next actor's turn
  -> resolve that actor's actions and end-of-turn effects
  -> remove the actor from the pending list
  -> re-sort remaining actors
  -> repeat until the list is empty
  -> start the next round
```

### Player-turn sequence

1. Age special board tiles; a special tile expires after two player-turn
   advances if it has not been used.
2. Reduce temporary ATK/DEF/SPD tile-effect durations by one.
3. Draw a hand of **4 fragments**, reduced by any Overload debt.
4. Place and rotate fragments on the **10 × 10** board.
5. Match spell patterns and add matches to the spell queue.
6. Continue placing fragments or reorder the queue.
7. Press **Cast** to resolve queued spells, then one basic board attack if
   occupied tiles remain.
8. Apply the player's end-of-turn Burn, Decay, and Chill effects.
9. Finish the player's action and continue the round.

## 3. Fragments, board, and spell matching

| Rule | Behaviour |
|---|---|
| Placement | A fragment must be fully inside the board |
| Collision | A fragment cannot overlap an occupied cell |
| Rotation | Clockwise with `R` or right-click |
| Matching | Tests possible anchors and rotations |
| Universal tile | Can satisfy elemental requirements under the matcher rules |
| Matched cells | Removed from the board and added to the spell queue |
| Unmatched cells | Remain on the board between casts/turns |
| Queue order | Can be changed before casting |

### Current spell library

Each element has 3 patterns, using 3, 5, or 8 cells:

| Element | 3-cell spell | 5-cell spell | 8-cell spell |
|---|---|---|---|
| Fire | Ember | Blazing Nova | Hellfire |
| Ice | Chill Touch | Frost Nova | Absolute Zero |
| Earth | Stone Crash | Smite | Tectonic Break |
| Wind | Gust | Crosswind | Tempest |
| Lightning | Spark | Chain Bolt | Thunderhead |
| Dark | Wither | Plague | Eclipse |

The spell's base damage is its matched pattern size (`3`, `5`, or `8`).
Effects are applied in addition to the base damage.

### Cast sequence

When **Cast** is pressed:

```text
Queued spell 1 -> queued spell 2 -> ... -> queued spell N
                                      -> basic attack, if board tiles > 0
```

Each step selects a living enemy, except self-targeting spells. The last
target is remembered. The targeting prompt is skipped when only one enemy is
alive. Casting can be cancelled only before the first step resolves.

## 4. Damage and defence

### Spell damage formula

For a damaging spell, `raw` is the spell base damage plus applicable direct
bonus damage such as Tailwind, Shatter, Conductive, Detonate, or Smite:

```text
Effective Spell ATK = ceil(max(1, ATK) × 0.25)

Base =
  ceil(raw × Effective Spell ATK
       × ATK multiplier
       × terrain element ATK multiplier)

Base = ceil(Base × ultimate damage multiplier)

Defence multiplier =
  100 / (100 + effective DEF × 100 / effective ATK)

Final damage =
  max(0, ceil(Base
       × Other multiplier
       × Defence multiplier
       × Elemental multiplier
       × Break multiplier
       × random multiplier))
```

Where:

- `effective ATK = max(1, ATK × ATK multiplier)`.
- `effective DEF = max(0, DEF × DEF multiplier)`, additionally multiplied by
  the terrain DEF modifier for the spell element.
- `Break multiplier` is `1.45` while the target is Broken, otherwise `1.00`.
- `random multiplier` is uniformly selected from `0.90` to `1.15`.
- The default `Other multiplier` is `1.00`. Defined tier values are Low
  `0.20`, Medium `0.45`, and High `0.90`.

### Basic board attack

```text
Base = ceil(board tiles × 1 × effective ATK
            × terrain neutral-element ATK multiplier)
Base = ceil(Base × ultimate damage multiplier)
Final damage = the same defence, elemental, Break, and random calculation
```

The basic attack uses element `NONE`, so it normally receives the default
elemental multiplier of `1.00`.

### Elemental multipliers

| Target relationship | Multiplier |
|---|---:|
| Target weakness (Countered) | 1.75× |
| Target strength (Countering) | 0.65× |
| No weakness/strength match | 1.00× |

Normal damage removes Shield first, then HP. Burn, Decay, and Detonate are
direct damage and currently bypass Shield.

## 5. Status effects

| Status/effect | Exact behaviour |
|---|---|
| **Burn** | End of affected unit's turn: `stacks × 2` direct damage; remove 1 stack |
| **Detonate threshold** | At 8 Burn stacks: consume all Burn and deal 20 direct damage |
| **Chill** | Reduce Speed by 25% per stack, capped at 50% of base; remove 1 at end of turn |
| **Freeze** | Every 3 Chill converts to 1 Freeze; Frozen enemy skips its action and loses 1 Freeze |
| **Shatter** | Fire, Earth, or Wind damaging spell consumes Freeze and adds `Freeze stacks × 12` bonus damage |
| **Fortify** | Adds the spell's configured Shield amount to the caster |
| **Smite** | Spend 4 Shield; if available, add `4 × 2 = 8` bonus damage |
| **Tailwind** | Eligible next core-element spell consumes 1 stack and adds `stacks × 3` damage |
| **Conductive** | Lightning hit consumes 1 stack and adds `stacks × 4` damage |
| **Conductive splash** | Adjacent living enemies take `50%` of the final hit and gain 1 Conductive |
| **Decay** | End of turn: `stacks × 2` direct damage; stacks persist |
| **Corruption conversion** | Every 4 Decay converts to 1 Corruption |
| **Corruption trigger** | Before an enemy acts: `stacks × 6` Dark damage; consume 1 Corruption |
| **Corruption life steal** | Player restores `triggered Corruption stacks × 3` HP |

### Spell-specific status effects

| Spell | Active additional effect |
|---|---|
| Hellfire | Applies 4 Burn to the target and 2 Self Burn to the player |
| Chain Bolt | Applies 2 Conductive and triggers Overload |
| Three-cell Fire/Ice/Earth/Wind/Lightning/Dark spells | Apply their configured status or defensive effect |

## 6. Break, charge, and ultimate

### Break

1. A hit using an enemy weakness increments its Break-hit counter.
2. A minor enemy breaks after a random threshold from **3–5 hits**. Elite
   thresholds are configured as **6–9 hits**.
3. Breaking applies Broken for **2 turns**.
4. A Broken enemy skips its action.
5. A Broken target takes `1.45×` damage.
6. After the Broken period ends, the hit counter resets when the Break status
   has cleared.

### Charge gain

| Event | Charge |
|---|---:|
| 3-cell matched spell | 5 |
| 5-cell matched spell | 8 |
| 8-cell matched spell | 15 |
| Each special tile included in a matched spell | 6 |
| Basic board attack | 3 |
| Player hit on an elemental weakness | 20 |
| Gauge maximum | 150 |

Charge is not added while an ultimate is active.

### Ultimate

The ultimate is available at **100 or more charge**. On activation:

```text
spent charge = current gauge
ratio = clamp((spent charge - 100) / 50, 0, 1)
damage multiplier = lerp(4.65, 6.30, ratio)
```

The gauge is reset to `0`, and the multiplier applies to the player's damage
for the current turn.

## 7. Terrain

One terrain is selected randomly at battle start:

| Terrain | Active modifiers |
|---|---|
| **Forest** | Wind ATK `+20%`; player Wind SPD `+20%`; Earth ATK `+45%`; Fire ATK `-20%`; Ice ATK `-20%` |
| **Volcano** | Fire ATK `+90%`; Wind ATK `+20%`; Ice ATK `-45%` |
| **Plain** | Wind ATK `+45%`; Ice ATK `+45%`; Fire ATK `-20%` |

The active terrain and its description are displayed above the battlefield.

## 8. Special board tiles

At the start of a player turn, each special-tile category has a **25%**
independent chance to spawn in an empty board cell. A tile remains for two
player-turn advances unless consumed by a match.

| Tile | Effect on match |
|---|---|
| Heal | Restores `ceil(player max HP × 0.10)` HP to the player |
| ATK/DEF/SPD buff | Increases the selected player stat by `60%` for 3 turns |
| ATK/DEF/SPD debuff | Decreases the selected target stat by `60%` for 3 turns |

Special tiles are consumed with the matched spell. A special tile included in
a spell also grants **6 charge**.

## 9. Overload

When **Chain Bolt** is matched:

1. Draw **1 extra fragment immediately**.
2. Add **1 Overload debt**.
3. On the next player turn, draw `max(1, 4 - 1) = 3` fragments.
4. Clear the debt after that draw.

## 10. Deadlock: Backlash and Fizzle

A deadlock appears only when all of these conditions are true:

```text
not battle over
not currently casting
no fragment has been placed this turn
spell queue is empty
no hand fragment fits anywhere on the board in any rotation
```

| Choice | Result |
|---|---|
| **Backlash** | Pay HP, clear the board, deal a basic attack using the cleared tile count, then end the turn |
| **Fizzle** | Clear the board with no HP cost or damage, then end the turn |

Backlash cost is:

```text
cost = max(1, ceil(max HP × (0.10 + 0.05 × earlier Backlash uses)))
```

Backlash is refused if `current HP - cost < 1`.

## 11. Enemy resolution

Enemy intent is shown in the battlefield UI. Enemy spells use the same generic
spell resolver as player spells, but enemies do not use the casting board.

The current configuration has enemy confirmation disabled:

```text
CONFIRM_ENEMY_ACTIONS = false
```

Therefore, enemy actions proceed automatically after the player's turn.
Frozen or Broken enemies skip their action before normal enemy spell
resolution.

## 12. Controls

| Control | Action |
|---|---|
| Left-click fragment | Select/deselect fragment |
| Drag fragment onto board | Preview and place fragment |
| Left-click board cell | Place selected fragment at that anchor |
| `R` / right-click fragment | Rotate clockwise |
| Left-click enemy | Select current target |
| `Enter` / `Space` | Confirm target or enemy prompt |
| `Esc` | Cancel targeting before the first player spell resolves |
| **Cast** | Resolve queued spells, then the board attack |
| **Reset** | Restore the current turn; after battle, reload the encounter |
| **Reroll hand** | Draw a replacement hand in the debug panel |

