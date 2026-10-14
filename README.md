# COMP4122 Group Project

A Godot 4 project focused on a turn-based elemental battle prototype. The current codebase is a foundation for a spell-casting board game where fragments are placed on a grid, matched against spell patterns, and resolved through elemental rules.

## Current status

This repo is in an early prototype stage. The core battle flow is in place, but the project does not yet include a full game loop, narrative progression, exploration systems, or polished production content.

The present implementation is centered on:

- a 10x10 battle board
- fragment placement and rotation
- drag-and-drop or click-to-place input
- elemental matching rules
- demo spell definitions and a simple hand system
- modular battle logic organized around data, models, and systems

## Gameplay overview

The prototype uses a board-based spellcasting loop inspired by matching puzzle combat. Players manage a hand of fragments, place them onto the board, and trigger spell patterns when the matched tiles satisfy the required elemental conditions.

Key mechanics already present include:

- elemental tile types: Fire, Ice, Earth, Wind, Lightning, Dark, Universal, and Empty
- rotation of fragment shapes for placement flexibility
- spell pattern detection using board anchors and tile data
- requirement checks based on minimum element counts and wildcard support
- a demo combat scene with a simple UI for testing mechanics

## Project structure

```text
.
├── addons/
│   └── godot_mcp/            # Godot MCP tooling and editor integration
├── assets/                   # Placeholder art, UI, and audio assets
├── battle/
│   ├── battle_controller.gd  # Main battle interaction and demo UI logic
│   ├── battle_scene.tscn    # Primary battle scene
│   ├── data/                # Resource definitions such as fragments/spells
│   ├── models/              # Board and mutable battle state models
│   └── systems/             # Matching, resolution, and combat rules
├── shared/
│   └── battle_types.gd      # Shared elemental definitions and tile metadata
├── content/                 # Planned content folder for spells, enemies, encounters
├── project.godot            # Godot project configuration
├── icon.svg                 # Default project icon
├── README.md                # Project overview and setup guide
└── .godot/                  # Generated Godot project metadata
```

## Getting started

### Requirements

- Godot 4.x (the project is configured for Godot 4.7 in `project.godot`)
- A local clone of this repository

### Run the project

1. Open Godot.
2. Select `Import` and choose this repository root.
3. Open `project.godot`.
4. Press `F5` or run the main scene.

The project entry point is configured to launch the battle prototype through `res://battle/battle_scene.tscn`.

## Controls

The current demo scene supports the following actions:

- drag a fragment onto the board, or click a fragment then a board cell
- press `R` to rotate the selected fragment
- use the `New hand` button to generate a fresh set of fragments
- use `Reset` to clear the board and restore the demo state

## File overview

Some of the most relevant scripts in the current prototype are:

- `battle/battle_controller.gd` – UI and battle interaction loop
- `battle/models/casting_board_model.gd` – board state and placement validation
- `battle/systems/spell_matcher.gd` – pattern matching logic
- `shared/battle_types.gd` – elemental enums, colors, and tile metadata
- `battle/data/spell_definition.gd` – spell resource definitions
- `battle/data/fragment_data.gd` – fragment shape and rotation logic

## Roadmap

The project is designed to grow beyond the prototype stage. Planned directions include:

- enemy turn logic and AI decisions
- full combat resolution and damage calculations
- richer spell and enemy content data
- progression and encounter systems
- exploration and UI polish
- save system and final game loop

## Notes

This README reflects the current state of the repository: a working battle-system foundation rather than a complete production game. The codebase is structured to support future expansion into a larger game, but much of the broader content and systems remain planned or placeholder-level work.
