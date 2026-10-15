# COMP4122 Group Project

## Pending work

- [ ] Expand the spell, fragment, and enemy content beyond the current demo
- [ ] Add more encounters and a progression system
- [ ] Add a complete game loop outside the battle prototype
- [ ] Replace placeholder combat presentation with polished art and effects
- [ ] Improve accessibility, feedback, and UI polish
- [ ] Add automated tests for placement, matching, status effects, and combat
- [ ] Add a documented build/release workflow

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
res://battle/battle_scene.tscn
```

## How to play

Each player turn follows this sequence:

1. Draw a hand of elemental fragments.
2. Place fragments on the 10 x 10 casting board.
3. Rotate fragments to fit the board and satisfy spell patterns.
4. Select an enemy target.
5. Review matched spells and reorder the spell queue if needed.
6. Press **Cast** to resolve spells and the basic attack from the filled board.
7. Survive the enemy turn and continue until either side is defeated.

The current prototype includes demo spells, multiple enemies, targeting,
enemy intents, shields, damage calculation, and status interactions.

### Elements

The available tile elements are Fire, Ice, Earth, Wind, Lightning, Dark,
Universal, and Empty. Universal tiles can satisfy elemental requirements
according to the matching rules.

### Status effects

The battle systems currently model Burn, Chill, Freeze, Fortify, Tailwind,
Decay, Conductive, and Corruption. Some effects convert into others at
thresholds, some modify damage, and some affect the end of a turn or an
adjacent enemy.

## Controls

- **Left-click a fragment**: select or deselect it.
- **Drag a fragment onto the board**: preview and place it.
- **Left-click a board cell**: place the selected fragment with that cell as
  its anchor.
- **R**: rotate the selected fragment clockwise.
- **Right-click a fragment**: rotate it clockwise.
- **Left-click an enemy**: select the enemy as the current target.
- **Cast**: resolve the current spell queue and board attack.
- **Reset**: restore the current turn, or reload the encounter after victory or
  defeat.
- **Reroll hand**: draw a replacement hand in the debug panel.

The debug panel also provides tools for testing individual elemental values.

## Project layout

```text
.
├── addons/
│   └── godot_mcp/             # Godot MCP editor integration
├── assets/
│   ├── enemies/               # Enemy artwork
│   └── textures/tiles/        # Elemental tile artwork
├── battle/
│   ├── battle_scene.tscn      # Playable battle scene
│   ├── battle_controller.gd  # Scene setup and battle interaction flow
│   ├── data/                  # Definitions, effects, statuses, and config
│   ├── models/                # Mutable board, combatant, and battle state
│   ├── systems/               # Matching, resolution, damage, status, and turns
│   └── ui/                    # Board, hand, battlefield, queue, and log views
├── content/
│   ├── spells/                # Runtime demo spell library
│   └── enounters/             # Runtime test encounter definitions
├── shared/
│   ├── elements.gd            # Element metadata and tile texture lookup
│   ├── assset_lookup.gd       # Character-art texture lookup
│   └── battle_types.gd        # Shared elemental definitions and tile metadata
├── project.godot              # Godot project configuration
├── project.godot.bak          # Backup project configuration
├── icon.svg                   # Project icon
└── README.md
```

Generated Godot editor data in `.godot/` is not required to understand or run
the project and should not be treated as source code.

## Asset access and texture loading

Godot assets are addressed with project-relative `res://` paths. The code
centralizes texture lookup instead of hard-coding texture assignments in every
UI control.

### Element tile textures

`shared/elements.gd` owns the element-to-texture mapping. Its `TILE_DIRS`
points to `res://assets/textures/tiles/`, and `TILE_ALIASES` maps element enum
values to filenames such as `tile_fire.png`, `tile_ice.png`, and
`tile_universal.png`. `Elements.texture_of(element)` validates the element,
searches the configured tile directories and extensions, and returns a
`Texture2D` loaded with Godot's `load(path)`.

The tile UI calls this helper whenever it displays a tile:

```gdscript
var tex: Texture2D = Elements.texture_of(element)
```

This is used by `battle/ui/tile_cell.gd` for board cells and by
`battle/ui/fragment_preview.gd` for fragment cards and drag previews. Adding a
new elemental texture therefore requires updating the element metadata and
placing the corresponding file in the configured asset directory; callers do
not need separate path logic.

### Character and enemy artwork

`shared/assset_lookup.gd` (the filename is intentionally spelled
`assset_lookup.gd`) provides `AssetLookup.character(art_name)`. It searches
the directories listed in `CHARACTER_DIRS`, tries the extensions in
`EXTENSIONS` (`png` and `webp`), and returns the first matching texture.
`battle/ui/combatant_view.gd` uses this helper when it receives an enemy or
player art name. If no file is found, the view uses its configured
placeholder color and label instead of failing to construct the combatant UI.

The art name comes from data definitions. For example,
`battle/data/battle_config.gd` contains the current player and wooden-dummy
art identifiers. Keep those identifiers consistent with the filename in an
asset directory searched by `AssetLookup`.

### Adding a new asset

1. Put the image in the appropriate `assets/` subdirectory.
2. Update `shared/elements.gd` for a new tile element, or update
   `AssetLookup.CHARACTER_DIRS` when adding a new character-art directory.
3. Update the relevant data definition with the asset identifier.
4. Let Godot import the file, then run the battle scene and verify the UI.

## Battle architecture

The battle code is separated into data resources, mutable models, systems,
and UI views. `battle/battle_controller.gd` creates the runtime objects,
connects signals, and coordinates these layers. Rules should generally stay
in models or systems; UI scripts should present state and emit input events.

### Implemented gameplay systems

#### `battle/systems/damage_calculator.gd`

Calculates final attack damage. It applies attacker modifiers such as Chill,
enforces the minimum damage fraction, and calculates basic board attacks from
the number of filled cells.

#### `battle/systems/enemy_intent_system.gd`

Selects the current action an enemy intends to perform for a given turn.
The battlefield UI displays this intent, while `TurnSystem` uses its damage
and action name when the enemy turn runs.

#### `battle/systems/fragment_generator.gd`

Creates random fragments from the configured shape and element pools and
draws a requested number for the player's hand. It also provides helpers for
creating a fragment containing a specific element, which is useful to the
debug panel and deterministic demo content.

#### `battle/systems/spell_matcher.gd`

Scans the casting board for spell patterns. It tests possible anchors,
compares occupied cells and element requirements, accounts for Universal
tiles, and returns matched spell information for the spell queue.

#### `battle/systems/spell_resolver.gd`

Resolves queued spells in order and resolves the filled-board basic attack.
It handles base damage, Tailwind, Shatter, Conductive, Detonate, Smite,
status application, Conductive splash, shields, and combat logging. Its
preview function duplicates the battle state so the UI can show projected
results without mutating the real encounter.

#### `battle/systems/status_system.gd`

Provides shared status operations: describing a combatant's statuses,
dealing direct damage that can bypass shields when configured, applying
stacks, and processing threshold conversions such as Chill to Freeze and
Decay to Corruption.

#### `battle/systems/turn_system.gd`

Advances player turns, applies end-of-turn Burn, Decay, and Chill behavior,
and runs every living enemy's turn. Frozen enemies skip their action;
otherwise enemy intents, Corruption triggers, attacks, life steal, and
end-of-turn effects are processed here.

### Implemented state models

- `battle/models/battle_state.gd` stores the player, enemy definitions,
  enemy combatant states, current target, turn number, and game-over state.
  It also repairs invalid targets, finds adjacent enemies, and duplicates the
  state for previews.
- `battle/models/combatant_state.gd` stores HP, maximum HP, shield, and status
  stacks. It owns damage, healing, status-stack, death, and duplication
  operations.
- `battle/models/casting_board_model.gd` stores the 10 x 10 element grid,
  checks bounds and collisions, places fragments, counts filled cells, and
  clears cells after resolution.
- `battle/models/queued_spell.gd` stores a matched spell definition and the
  elements used to satisfy that match.

## Data and configuration scripts

The scripts in `battle/data/` define content and centralize tunable rules.
They are lightweight resources or enums so systems can consume consistent
data without embedding content-specific logic.

- `battle/data/battle_config.gd` is the main balance/configuration file. It
  defines board size, player HP, hand size, basic damage, shield behavior,
  damage-over-time values, status thresholds and decay rates, Shatter,
  Tailwind, Conductive, Corruption, and current art identifiers.
- `battle/data/element_requirement.gd` represents a minimum count of one
  element needed by a spell and provides a construction helper.
- `battle/data/enemy_definition.gd` describes enemy content, including name,
  HP, art identifier, and intent data. `wooden_dummy()` supplies the current
  demo enemy definition.
- `battle/data/fragment_data.gd` stores a fragment's relative cell positions
  and element values. It normalizes shapes, rotates them clockwise, and
  produces preview text.
- `battle/data/player_definition.gd` defines player-facing combat data used
  when constructing player state.
- `battle/data/spell_definition.gd` stores a spell ID, display name, pattern,
  element requirements, base damage, primary element, and effects.
- `battle/data/spell_effect.gd` defines effect kinds and their numeric
  parameters, including damage, Burn, Chill, Fortify, Tailwind, Decay,
  Conductive, Detonate, Smite, and related effects.
- `battle/data/spell_pattern.gd` stores the relative cells that make up a
  spell shape.
- `battle/data/status_types.gd` defines the status enum and converts status
  values to display names.
- `content/spells/demo_spell_library.gd` builds the current demo spell list
  in code. It defines spell IDs, names, shapes, element requirements, base
  damage, and effect parameters for Fire, Ice, Earth, Wind, Lightning, and
  Dark spells.
- `content/enounters/test_encounter.gd` builds the current test encounter by
  creating three wooden-dummy enemy definitions. The directory name is
  intentionally `enounters` in the current repository.

The shared scripts complement these data definitions:

- `shared/elements.gd` defines the element enum, names, letters, colors,
  aliases, validation, and tile texture loading.
- `shared/assset_lookup.gd` resolves character-art identifiers to textures.
- `shared/battle_types.gd` contains shared battle type declarations and tile
  metadata used across the project.

## UI scripts

The UI layer is created at runtime by `battle/battle_controller.gd`.

- `battle/ui/battlefield_view.gd` displays the player and enemies, enemy
  intent, HP/status information, and target selection.
- `battle/ui/casting_board_view.gd` displays the grid, placement previews,
  spell outlines, and drag-and-drop targets.
- `battle/ui/tile_cell.gd` renders one board cell and handles tile drop input.
- `battle/ui/fragment_zone.gd`, `fragment_card.gd`, and
  `fragment_preview.gd` display the hand, selection, rotation, and drag data.
- `battle/ui/spell_queue_view.gd` and `spell_entry.gd` display matched spells,
  previews, and queue reorder controls.
- `battle/ui/turn_indicator.gd` displays the turn and Cast/Reset actions.
- `battle/ui/battle_log_view.gd` displays combat-resolution messages.
- `battle/ui/combatant_view.gd` renders an individual player or enemy.
- `battle/ui/debug_panel.gd` exposes testing controls for rerolling and
  granting elemental fragments.

## Important files

- `battle/battle_controller.gd` — scene setup, signal wiring, turn flow, and
  battle interaction coordination.
- `battle/battle_scene.tscn` — the scene entry point; the controller builds
  the rest of the interface at runtime.
- `battle/systems/spell_matcher.gd` — board-pattern and requirement matching.
- `battle/systems/spell_resolver.gd` — spell and basic-attack resolution.
- `battle/data/battle_config.gd` — centralized balance and art configuration.
- `shared/elements.gd` — shared element metadata and tile texture access.
- `shared/assset_lookup.gd` — character-art texture access.

## Development notes

Most demo content is generated at runtime by the battle scene rather than
loaded from a campaign or encounter database. When changing battle behavior,
run the project in Godot and exercise a normal turn, a status interaction,
and both the victory and defeat paths.

There is no automated build or release pipeline in the repository. Automated
tests are also still pending.
