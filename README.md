# COMP4122 Group Project

## Pending work

## 1. Foundation and Open Decisions

- [x] Define base damage and the damage formula () - Loky
- [ ] Decide whether special grids are random or fixed ()
- [ ] Decide the boss ultimate interval ()
- [ ] Decide whether levels and talents exist ()
- [ ] Create the autoload singleton for run state ()

## 2. Core Battle System

- [x] Build the battle state machine: player turn, enemy turn, resolve, end — Jimmy
- [x] Build the casting board and grid data structure — Jimmy
- [ ] Implement the element system and weakness table ()
- [ ] Implement damage multiplier modification ()
- [ ] Implement board buffs to elements (damage +/−)
- [ ] Implement special grids on the board ()
- [x] Implement turn order based on the Speed stat — Jimmy
- [ ] Implement the turn timer and its timeout behaviour ()
- [ ] Build the status effect framework: duration, stacking, removal ()
- [ ] Implement knock-down status: weakness trigger, enemy disabled for x turns, ×1.5 damage (to be tuned) ()
- [] Add win/lose conditions and a result screen ()

## 3. Spells and Fragments

- [ ] Add more spells ()
- [ ] Run a spell balance pass ()

## 4. Player Systems

- [x] Implement base stats: HP, damage multipliers, DEF, Speed () - Loky
- [ ] Implement the charging gauge ()
- [ ] Implement FEVER mode: trigger, duration, effects ()
- [ ] Implement the character ultimate ()
- [ ] Implement talents (element buffs, stat changes) **[?]** 
- [ ] Implement levels/progression **[?]** 
- [ ] Add more selectable characters and a select screen **[?]**

## 5. Enemy and Boss AI

- [ ] Build the enemy base class and stats ()
- [ ] Implement minion AI with fixed damage ()
- [ ] Add minion effects **[?]**
- [ ] Implement elite AI: multiple spells, one per attack, forming a combo ()
- [x] Show enemy intent (telegraphing) — Jimmy
- [ ] Implement boss AI built on the elite framework with higher damage ()
- [ ] Add boss ultimate spells on the set interval ()
- [ ] Add the boss ability to ban grids on the board ()
- [ ] Add boss terrain-change status **[?]**
- [ ] Add more enemies ()

## 6. Equipment, Inventory and Economy

- [ ] Implement armour (player stat modifiers)
- [ ] Implement casting boards (weapons): board shape and board buffs ()
- [ ] Build the backpack/inventory system ()
- [ ] Add spell and fragment capacity limits ()
- [ ] Implement equip/unequip logic with stat recalculation ()
- [ ] Implement buff items **[?]**
- [ ] Implement consumables **[?]**
- [ ] Let inventory affect stats, storyline and economy **[?]**
- [ ] Implement the gold economy: income, prices, sinks ()

## 7. Exploration and Run Flow

- [ ] Generate the node-based map ()
- [ ] Add battle nodes with scaling difficulty ()
- [ ] Add elite battle nodes ()
- [ ] Add the boss node ()
- [ ] Add shop nodes ()
- [ ] Add treasure nodes ()
- [ ] Add event nodes with choices and outcomes ()
- [ ] Implement save/load and run resume ()

## 8. Terrain **[?]**

- [ ] Implement the terrain system **[?]**
- [ ] Add terrain buffs/debuffs to specific elements **[?]**
- [ ] Add terrain–equipment interaction **[?]**

## 9. UI ()

- [ ] Explore background
- [ ] Battle background
- [ ] Battle HUD: HP, timer, gauge, fragments
- [ ] Node descriptions
- [ ] Story presentation
- [ ] Dialogue system, if used
- [ ] Event node UI: choices and buttons
- [ ] Shop UI
- [ ] Inventory/backpack UI
- [ ] Main menu, pause and settings

## 10. Art, Animation and Audio ()

- [ ] Player character art
- [ ] Enemy art
- [ ] Item art
- [ ] Spell icons
- [ ] Character animations
- [ ] Attack action animations
- [ ] Spell animations and FX
- [ ] Enemy action animations
- [ ] Status and state-change FX
- [ ] UI animations
- [ ] Sound effects and music

This repository contains a Godot 4 prototype for a turn-based, elemental
spell-casting game. Players build spells by placing rotatable fragments on a
casting board, match the board against spell patterns, and resolve the
resulting attacks and status effects against a group of enemies.

The project is currently focused on validating the battle system and its user
interface. It is a playable combat prototype, not yet a complete game.

## Requirements

- [Godot 4.7](https://godotengine.org/)
- A local clone of this repository

The project uses the Godot **GL Compatibility** renderer and is configured for
a 1280 x 720 viewport.

## Running the prototype

1. Open Godot.
2. Select **Import** and choose the repository folder.
3. Open `project.godot`.
4. Press **F6** to run the current scene, or **F5** to run the project.

The project entry point is:

```text
res://scenes/battle/battle_scene.tscn
```

## How to play

Combat runs in rounds. Every living combatant acts once per round, ordered by
effective Speed from highest to lowest. Speed ties go to the player, then the
lower enemy slot. The remaining order is re-sorted after every spell and every
action, so Speed changes from status effects take effect immediately.

On the player's turn:

1. Draw a hand of elemental fragments.
2. Place fragments on the 10 x 10 casting board and rotate them to fit.
3. Match the board against spell patterns and reorder the matched spell queue
   if needed.
4. Press **Cast**. Each queued spell is presented in order, followed by one
   basic attack when the board is not empty.
5. Confirm a target for each step. The last target is remembered; the prompt
   is skipped when only one enemy is alive. Confirm with Enter or Space, or
   cancel with Esc before the first spell resolves.
6. Continue placing and casting while the board's unmatched tiles remain
   between turns. The basic attack counts every tile on the board each time it
   is cast.

If no fragment has been placed this turn and no hand fragment fits the board in
any rotation, a deadlock overlay offers **Backlash** and **Fizzle**. Backlash
costs HP, clears the board, deals base damage per cleared tile, and ends the
turn. Its cost and minimum remaining HP are configured in
`scripts/battle/data/battle_config.gd`; Fizzle clears the board for free
without dealing damage and also ends the turn. Either choice can be refused or
cancelled only according to the controls shown by the overlay.

Enemy actions are spells resolved by the same generic spell resolver as player
spells. The Wooden Dummies in the test encounter currently cast only Mend on
themselves, so they heal rather than attack. The
`CONFIRM_ENEMY_ACTIONS` setting in `battle_config.gd` controls whether a
Continue prompt appears before an enemy spell.

### Elements

The available tile elements are Fire, Ice, Earth, Wind, Lightning, Dark,
Universal, and Empty. Universal tiles can satisfy elemental requirements
according to the matching rules.

### Status effects

The battle systems currently model Burn, Chill, Freeze, Decay, Corruption,
Tailwind, and Conductive, with Fortify represented as Shield. Burn deals
damage at the end of the affected unit's turn and can trigger Detonate.
Chill reduces effective Speed by 0.25 per stack, down to 0.50 of base Speed,
and loses one stack at the end of the unit's turn. Three Chill converts to one
Freeze; Freeze skips an enemy action and loses one stack on each skipped
action. Shatter consumes Freeze on a damaging Fire, Earth, or Wind spell for
bonus damage. Fortify adds persistent Shield. Smite spends the required Shield
and adds its configured damage per point. Tailwind adds a bonus to the next
eligible damaging core-element spell, while Conductive adds Lightning damage
and can spread half of that hit to adjacent enemies. Overload draws extra
fragments immediately and adds a next-turn hand-size penalty. Decay deals
end-of-turn damage and converts to Corruption. Corruption triggers damage
before an enemy acts and restores player HP through life steal. The numeric
values and thresholds come from `scripts/battle/data/battle_config.gd` and
the current spell definitions.

## Controls

- **Left-click a fragment**: select or deselect it.
- **Drag a fragment onto the board**: preview and place it.
- **Left-click a board cell**: place the selected fragment with that cell as
  its anchor.
- **R**: rotate the selected fragment clockwise.
- **Right-click a fragment**: rotate it clockwise.
- **Left-click an enemy**: select the enemy as the current target.
- **Enter** or **Space**: confirm the current target or enemy Continue prompt.
- **Esc**: cancel targeting before the first player spell resolves.
- **Cast**: step through the current spell queue and board attack.
- **Reset**: restore the current turn, or reload the encounter after victory or
  defeat.
- **Reroll hand**: draw a replacement hand in the debug panel.

The debug panel also provides tools for testing individual elemental values.

## Project layout

The project is organized by responsibility. Godot `.uid` files and imported
`.import` files are generated metadata paired with their source files and are
not listed individually below.

```text
.
├── .vscode/
│   └── settings.json                 # Workspace settings
├── addons/
│   └── godot_mcp/                    # Godot MCP editor integration
│       ├── plugin.cfg                # Add-on metadata
│       ├── plugin.gd                 # Add-on entry point
│       ├── mcp_client.gd             # MCP connection client
│       ├── tool_executor.gd          # Executes MCP tools
│       ├── runtime/
│       │   └── mcp_runtime.gd        # Runtime MCP support
│       ├── tools/                    # Editor automation tool handlers
│       │   ├── analysis_tools.gd
│       │   ├── animation_tools.gd
│       │   ├── animation_tree_tools.gd
│       │   ├── asset_tools.gd
│       │   ├── audio_tools.gd
│       │   ├── batch_tools.gd
│       │   ├── file_tools.gd
│       │   ├── navigation_tools.gd
│       │   ├── netcode_tools.gd
│       │   ├── particle_tools.gd
│       │   ├── physics_tools.gd
│       │   ├── project_tools.gd
│       │   ├── scene_tool_base.gd
│       │   ├── scene_tools.gd
│       │   ├── scene3d_tools.gd
│       │   ├── script_tools.gd
│       │   ├── shader_tools.gd
│       │   ├── testing_tools.gd
│       │   ├── theme_tools.gd
│       │   ├── tilemap_tools.gd
│       │   └── visualizer_tools.gd
│       └── utils/                    # MCP logging, paths, and data helpers
│           ├── activity_log.gd
│           ├── debugger_watch.gd
│           ├── path_guard.gd
│           ├── paths.gd
│           ├── variant_codec.gd
│           └── wire_text.gd
├── assets/                           # Artwork loaded by the game
│   ├── audio/
│   │   ├── music/
│   │   │   └── .gitkeep
│   │   └── sfx/
│   │       └── .gitkeep
│   ├── characters/
│   │   └── .gitkeep
│   ├── enemies/
│   │   └── enemy_wooden_dummy.png    # Wooden dummy artwork
│   ├── fonts/
│   │   └── .gitkeep
│   ├── icons/
│   │   ├── elements/
│   │   │   └── .gitkeep
│   │   ├── items/
│   │   │   └── .gitkeep
│   │   ├── spells/
│   │   │   └── .gitkeep
│   │   └── statuses/
│   │       └── .gitkeep
│   ├── textures/
│   │   ├── environments/
│   │   │   └── .gitkeep
│   │   └── tiles/                    # Element tile textures
│   │       ├── tile_dark.png
│   │       ├── tile_earth.png
│   │       ├── tile_fire.png
│   │       ├── tile_ice.png
│   │       ├── tile_lightning.png
│   │       ├── tile_none.png
│   │       ├── tile_universal.png
│   │       └── tile_wind.png
│   ├── ui/
│   │   └── .gitkeep
│   └── vfx/
│       └── .gitkeep
├── scenes/
│   └── battle/
│       └── battle_scene.tscn          # Scene entry point
├── scripts/
│   ├── battle/                       # Main battle prototype
│   │   ├── ai/
│   │   │   └── .gitkeep
│   │   ├── battle_controller.gd      # Battle setup and interaction flow
│   │   ├── terrain/
│   │   │   └── .gitkeep
│   │   ├── data/                     # Definitions and balance data
│   │   │   ├── battle_config.gd
│   │   │   ├── element_requirement.gd
│   │   │   ├── enemy_definition.gd
│   │   │   ├── fragment_data.gd
│   │   │   ├── player_definition.gd
│   │   │   ├── spell_definition.gd
│   │   │   ├── spell_effect.gd
│   │   │   ├── spell_pattern.gd
│   │   │   └── status_types.gd
│   │   ├── models/                   # Mutable runtime battle state
│   │   │   ├── battle_state.gd
│   │   │   ├── casting_board_model.gd
│   │   │   ├── combatant_state.gd
│   │   │   └── queued_spell.gd
│   │   ├── systems/                  # Battle rules and resolution
│   │   │   ├── damage_calculator.gd
│   │   │   ├── deadlock_detector.gd
│   │   │   ├── deadlock_resolver.gd
│   │   │   ├── enemy_intent_system.gd
│   │   │   ├── fragment_generator.gd
│   │   │   ├── spell_matcher.gd
│   │   │   ├── spell_resolver.gd
│   │   │   ├── status_system.gd
│   │   │   ├── turn_order_system.gd
│   │   │   └── turn_resolver.gd
│   │   └── ui/                       # Battle interface components
│   │       ├── battle_log_view.gd
│   │       ├── battlefield_view.gd
│   │       ├── casting_board_view.gd
│   │       ├── combatant_view.gd
│   │       ├── deadlock_overlay.gd
│   │       ├── fragment_card.gd
│   │       ├── fragment_preview.gd
│   │       ├── fragment_zone.gd
│   │       ├── spell_entry.gd
│   │       ├── spell_queue_view.gd
│   │       ├── target_prompt.gd
│   │       ├── tile_cell.gd
│   │       ├── turn_indicator.gd
│   │       └── turn_order_bar.gd
│   ├── content/                      # Playable prototype content
│   │   ├── enemies/
│   │   │   └── .gitkeep
│   │   ├── encounters/
│   │   │   └── test_encounter.gd
│   │   ├── items/
│   │   │   └── .gitkeep
│   │   └── spells/
│   │       ├── demo_spell_library.gd
│   │       └── enemy_spell_library.gd
│   ├── debug/
│   │   └── debug_panel.gd
│   └── shared/                       # Cross-system definitions and helpers
│       ├── asset_lookup.gd
│       └── elements.gd
├── .editorconfig                     # Editor formatting defaults
├── .gitattributes                    # Git file handling rules
├── .gitignore                        # Ignored generated and local files
├── icon.svg                          # Project icon
├── project.godot                     # Godot project configuration
└── README.md                         # Project documentation
```

The empty `scripts/battle/ai/`, `scripts/battle/terrain/`,
`scripts/content/enemies/`, and `scripts/content/items/` folders are reserved
for future content. Generated Godot editor data in `.godot/` is local project
state and is not source code.

## Asset access and texture loading

Godot assets are addressed with project-relative `res://` paths. The code
centralizes texture lookup instead of hard-coding texture assignments in every
UI control.

### Element tile textures

`scripts/shared/elements.gd` owns the element-to-texture mapping. Its
`TILE_DIRS` includes `res://assets/texture/tiles/` and
`res://assets/textures/tiles/`, and `TILE_ALIASES` maps element enum values to
filenames such as `tile_fire.png`, `tile_ice.png`, and
`tile_universal.png`. `Elements.texture_of(element)` validates the element,
searches the configured tile directories and extensions, and returns a
`Texture2D` loaded with Godot's `load(path)`.

The tile UI calls this helper whenever it displays a tile:

```gdscript
var tex: Texture2D = Elements.texture_of(element)
```

This is used by `scripts/battle/ui/tile_cell.gd` for board cells and by
`scripts/battle/ui/fragment_preview.gd` for fragment cards and drag previews. Adding a
new elemental texture therefore requires updating the element metadata and
placing the corresponding file in the configured asset directory; callers do
not need separate path logic.

### Character and enemy artwork

`scripts/shared/asset_lookup.gd` provides `AssetLookup.character(art_name)`. It
searches
the directories listed in `CHARACTER_DIRS`, tries the extensions in
`EXTENSIONS` (`png` and `webp`), and returns the first matching texture.
`scripts/battle/ui/combatant_view.gd` uses this helper when it receives an enemy or
player art name. If no file is found, the view uses its configured
placeholder color and label instead of failing to construct the combatant UI.

The art name comes from data definitions. For example,
`scripts/battle/data/battle_config.gd` contains the current player and
wooden-dummy
art identifiers. Keep those identifiers consistent with the filename in an
asset directory searched by `AssetLookup`.

### Adding a new asset

1. Put the image in the appropriate `assets/` subdirectory.
2. Update `scripts/shared/elements.gd` for a new tile element, or update
   `AssetLookup.CHARACTER_DIRS` in `scripts/shared/asset_lookup.gd` when adding
   a new character-art directory.
3. Update the relevant data definition with the asset identifier.
4. Let Godot import the file, then run the battle scene and verify the UI.

## Battle architecture

The battle code is separated into data resources, mutable models, systems,
and UI views. `scripts/battle/battle_controller.gd` creates the runtime objects,
connects signals, and coordinates these layers. Rules should generally stay
in models or systems; UI scripts should present state and emit input events.

### Implemented gameplay systems

#### `scripts/battle/systems/damage_calculator.gd`

Calculates spell damage using `ceil(Spell Damage * (ATK * 0.25))`, then applies
`(Base * Other Multiplier) * Defence Multiplier * Elemental Multiplier` and a
random 90%-115% factor before rounding up. Basic board attacks use their
tile-based base damage and also receive the final multipliers and randomness.
The default Other Multiplier is 100%; the available default tier values are
Low 20%, Medium 45%, and High 90%. Enemy weaknesses apply a 175% Countered
multiplier, strengths apply a 65% Countering multiplier, and unmatched elements
use 100%. Chill is not a damage modifier; it reduces effective Speed in
`turn_order_system.gd`.

#### `scripts/battle/systems/enemy_intent_system.gd`

Selects the current action an enemy intends to perform for a given turn.
The battlefield UI displays the selected spell, while `turn_resolver.gd`
executes it through `SpellResolver.cast()`.

#### `scripts/battle/systems/fragment_generator.gd`

Creates random fragments from the configured shape and element pools and
draws a requested number for the player's hand. It also provides helpers for
creating a fragment containing a specific element, which is useful to the
debug panel and deterministic demo content.

#### `scripts/battle/systems/spell_matcher.gd`

Scans the casting board for spell patterns. It tests possible anchors,
compares occupied cells and element requirements, accounts for Universal
tiles, and returns matched spell information for the spell queue.

#### `scripts/battle/systems/spell_resolver.gd`

Provides generic `cast()` resolution for player and enemy spells, resolves
queued player spells in order, and resolves the filled-board basic attack.
It handles base damage, Tailwind, Shatter, Conductive, Detonate, Smite,
status application, Conductive splash, shields, and combat logging. Its
preview function duplicates the battle state so the UI can show projected
results without mutating the real encounter.

#### `scripts/battle/systems/status_system.gd`

Provides shared status operations: describing a combatant's statuses,
dealing direct damage that can bypass shields when configured, applying
stacks, and processing threshold conversions such as Chill to Freeze and
Decay to Corruption.

#### `scripts/battle/systems/turn_order_system.gd`

Builds and refreshes round order from effective Speed, with player and lower
enemy-slot tie breaking. It tracks pending and acted actors and re-sorts after
spells and actions.

#### `scripts/battle/systems/turn_resolver.gd`

Applies end-of-turn Burn, Decay, and Chill behavior and runs one living
enemy's action. Frozen enemies skip their action; otherwise the selected enemy
spell, Corruption trigger, life steal, and end-of-turn effects are processed.

#### `scripts/battle/systems/deadlock_detector.gd` and `deadlock_resolver.gd`

Detect a hand that cannot be placed anywhere on the board in any rotation and
resolve the Backlash or Fizzle choice. Backlash uses the configured
progressive HP cost, clears the board, and applies the basic tile damage;
Fizzle clears the board without cost or damage.

### Implemented state models

- `scripts/battle/models/battle_state.gd` stores the player, enemy definitions,
  enemy combatant states, remembered target, player and enemy Speeds, round
  number, pending and acted actors, current actor, and game-over state. It also
  repairs invalid targets, finds adjacent enemies, and duplicates the state for
  previews.
- `scripts/battle/models/combatant_state.gd` stores HP, maximum HP, shield, and status
  stacks. It owns damage, healing, status-stack, death, and duplication
  operations.
- `scripts/battle/models/casting_board_model.gd` stores the 10 x 10 element grid,
  checks bounds and collisions, places fragments, counts filled cells, and
  supports snapshots, restoration, and clearing.
- `scripts/battle/models/queued_spell.gd` stores a matched spell definition and the
  elements used to satisfy that match.

## Data and configuration scripts

The scripts in `scripts/battle/data/` define content and centralize tunable rules.
They are lightweight resources or enums so systems can consume consistent
data without embedding content-specific logic.

- `scripts/battle/data/combatant_definition.gd` is the shared stat schema for
  player and enemy records. Both use `max_hp`, `level`, `attack`, `defence`, and
  `speed`, plus editable elemental weakness and strength lists, with
  presentation fields for the display name and artwork.
- `resources/characters/player.tres` and
  `resources/enemies/wooden_dummy_*.tres` are the local Godot resource database
  records loaded by the battle state. They require no external service and can
  be edited in the Godot Inspector.
- `scripts/battle/data/battle_config.gd` is the main balance/configuration file.
  It defines board size, hand size, basic damage, enemy-action confirmation,
  shield behavior, damage-over-time values, status thresholds and decay rates, Shatter, Tailwind, Conductive,
  Corruption, Backlash, and deadlock behavior.
- `scripts/battle/data/element_requirement.gd` represents a minimum count of one
  element needed by a spell and provides a construction helper.
- `scripts/battle/data/player_definition.gd` loads the player record from the
  local resource database.
- `scripts/battle/data/enemy_definition.gd` describes enemy content and loads
  enemy records from the local resource database. `wooden_dummy()` adds the
  current demo enemy's runtime spell list.
- `scripts/battle/data/fragment_data.gd` stores a fragment's relative cell positions
  and element values. It normalizes shapes, rotates them clockwise, and
  produces preview text.
- `scripts/battle/data/player_definition.gd` defines player-facing combat data used
  when constructing player state.
- `scripts/battle/data/spell_definition.gd` stores a spell ID, display name, pattern,
  element requirements, base damage, primary element, and effects.
- `scripts/battle/data/spell_effect.gd` defines effect kinds and their numeric
  parameters, including damage, Burn, Chill, Fortify, Tailwind, Decay,
  Conductive, Detonate, Smite, and related effects.
- `scripts/battle/data/spell_pattern.gd` stores the relative cells that make up a
  spell shape.
- `scripts/battle/data/status_types.gd` defines the status enum and converts status
  values to display names.
- `scripts/content/spells/demo_spell_library.gd` builds the current demo spell list
  in code. It defines spell IDs, names, shapes, element requirements, base
  damage, and effect parameters for Fire, Ice, Earth, Wind, Lightning, and
  Dark spells.
- `scripts/content/spells/enemy_spell_library.gd` builds enemy spells. The
  current wooden dummy uses Mend, which targets itself and heals it.
- `scripts/content/encounters/test_encounter.gd` builds the current test
  encounter by loading three wooden-dummy enemy records.

The shared scripts complement these data definitions:

- `scripts/shared/elements.gd` defines the element enum, names, letters, colors,
  aliases, validation, and tile texture loading.
- `scripts/shared/asset_lookup.gd` resolves character-art identifiers to
  textures.

## UI scripts

The UI layer is created at runtime by `scripts/battle/battle_controller.gd`.

- `scripts/battle/ui/battlefield_view.gd` displays the player and enemies, enemy
  intent, HP/status information, and target selection.
- `scripts/battle/ui/casting_board_view.gd` displays the grid, placement previews,
  spell outlines, and drag-and-drop targets.
- `scripts/battle/ui/tile_cell.gd` renders one board cell and handles tile drop input.
- `scripts/battle/ui/fragment_zone.gd`, `fragment_card.gd`, and
  `fragment_preview.gd` display the hand, selection, rotation, and drag data.
- `scripts/battle/ui/spell_queue_view.gd` and `spell_entry.gd` display matched spells,
  projected final damage, previews, and queue reorder controls.
- `scripts/battle/ui/turn_indicator.gd` displays the round and Cast/Reset actions.
- `scripts/battle/ui/turn_order_bar.gd` displays actor order and effective Speed.
- `scripts/battle/ui/target_prompt.gd` displays target confirmation and
  cancellation controls.
- `scripts/battle/ui/deadlock_overlay.gd` displays the Backlash and Fizzle
  choices for a deadlocked hand.
- `scripts/battle/ui/battle_log_view.gd` displays combat-resolution messages.
- `scripts/battle/ui/combatant_view.gd` renders an individual player or enemy.
- `scripts/debug/debug_panel.gd` exposes testing controls for rerolling and
  granting elemental fragments.

## Important files

- `scripts/battle/battle_controller.gd` — scene setup, signal wiring, turn flow, and
  battle interaction coordination.
- `scenes/battle/battle_scene.tscn` — the scene entry point; the controller builds
  the rest of the interface at runtime.
- `scripts/battle/systems/spell_matcher.gd` — board-pattern and requirement matching.
- `scripts/battle/systems/spell_resolver.gd` — generic spell and basic-attack resolution.
- `scripts/battle/data/battle_config.gd` — centralized balance, turn-order,
  Backlash, deadlock, and art configuration.
- `scripts/shared/elements.gd` — shared element metadata and tile texture access.
- `scripts/shared/asset_lookup.gd` — character-art texture access.

## Development notes

Most demo content is generated at runtime by the battle scene rather than
loaded from a campaign or encounter database. When changing battle behavior,
run the project in Godot and exercise a normal round, targeted casting, a
status interaction, a deadlock choice, and both the victory and defeat paths.

There is no automated build or release pipeline in the repository. Automated
tests are also still pending.
