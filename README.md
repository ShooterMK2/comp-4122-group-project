## TEMP project structure

res://
├── project.godot
│
├── assets/
│   ├── textures/
│   │   ├── tiles/
│   │   ├── ui/
│   │   ├── characters/
│   │   └── environments/
│   ├── fonts/
│   └── audio/
│
├── shared/
│   ├── battle_types.gd
│   └── ui_theme.tres
│
├── battle/
│   ├── battle_scene.tscn
│   ├── battle_controller.gd
│   │
│   ├── data/                         # Resource class definitions
│   │   ├── battle_config.gd
│   │   ├── fragment_data.gd
│   │   ├── element_requirement.gd
│   │   ├── spell_pattern.gd
│   │   ├── spell_effect.gd
│   │   ├── spell_definition.gd
│   │   └── enemy_definition.gd
│   │
│   ├── models/                       # Mutable battle state
│   │   ├── battle_state.gd
│   │   ├── combatant_state.gd
│   │   ├── casting_board_model.gd
│   │   ├── fragment_hand.gd
│   │   └── queued_spell.gd
│   │
│   ├── systems/                      # Rules and calculations
│   │   ├── fragment_generator.gd
│   │   ├── fragment_draw_system.gd
│   │   ├── spell_matcher.gd
│   │   ├── spell_resolver.gd
│   │   ├── damage_calculator.gd
│   │   ├── status_system.gd
│   │   ├── turn_system.gd
│   │   └── enemy_intent_system.gd
│   │
│   └── ui/
│       ├── battlefield_view.tscn
│       ├── fragment_card.tscn
│       ├── fragment_zone.tscn
│       ├── casting_board_view.tscn
│       ├── spell_entry.tscn
│       ├── spell_zone.tscn
│       ├── spell_queue_view.tscn
│       └── turn_indicator.tscn
│
├── content/                          # Actual game content
│   ├── spells/
│   │   ├── templates/
│   │   │   └── spell_template.tres
│   │   ├── fire/
│   │   ├── ice/
│   │   ├── earth/
│   │   ├── wind/
│   │   ├── lightning/
│   │   └── dark/
│   ├── fragments/
│   ├── enemies/
│   └── encounters/
│
├── exploration/                      # Later
├── progression/                      # Later
├── saves/                            # Save-system scripts, not save files
│
└── tests/
	├── board_model_test.gd
	├── spell_matcher_test.gd
	└── spell_resolver_test.gd
