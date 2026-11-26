class_name EventDatabase
extends RefCounted

const EVENTS = {
	# Wood (None) / Snow
	"ABANDONED_CAMPFIRE": {
		"id": 0,
		"title": "Abandoned Campfire",
		"description": "You find a recently extinguished campfire. A scattered backpack lies nearby.",
		"terrains": ["None", "Snow"],
		"choices": [
			{"text": "Search the backpack (+30 Gold, -1 Morality)", "effects": [{"type": "gold", "value": 30}], "morality": -1},
			{"text": "Rest here (+20 HP)", "effects": [{"type": "hp", "value": 20}], "morality": 0},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},
	"LOST_TRAVELER": {
		"id": 1,
		"title": "Lost Traveler",
		"description": "A traveler is trapped in the snow. He begs for help.",
		"terrains": ["None", "Snow"],
		"choices": [
			{"text": "Help him (+30 XP, -15 HP, +1 Morality)", "effects": [{"type": "hp", "value": -15}, {"type": "xp", "value": 30}], "morality": 1},
			{"text": "Rob him (+50 Gold, -1 Morality)", "effects": [{"type": "gold", "value": 50}], "morality": -1},
			{"text": "Ignore him", "effects": [], "morality": 0}
		]
	},
	"FROZEN_MERCHANT": {
		"id": 2,
		"title": "Frozen Merchant",
		"description": "A merchant lies dead in the snow, clutching a locked chest.",
		"terrains": ["None", "Snow"],
		"choices": [
			{"text": "Bury him (+10 XP, +1 Morality)", "effects": [{"type": "xp", "value": 10}], "morality": 1},
			{"text": "Break the chest (+30 Gold, -1 Morality)", "effects": [{"type": "gold", "value": 30}], "morality": -1},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},

	# Forest
	"ANCIENT_ALTAR": {
		"id": 3,
		"title": "Ancient Elemental Altar",
		"description": "An altar of vines and stone holds three glowing orbs: red, blue, and green.",
		"terrains": ["Forest"],
		"choices": [
			{"text": "Touch the Red Orb (+Fire Spell, -15 HP)", "effects": [{"type": "hp", "value": -15}, {"type": "spell", "value": "fire"}], "morality": 0},
			{"text": "Touch the Blue Orb (+Ice Spell, -15 HP)", "effects": [{"type": "hp", "value": -15}, {"type": "spell", "value": "ice"}], "morality": 0},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},
	"MYSTIC_SPRING": {
		"id": 4,
		"title": "Mystic Spring",
		"description": "You discover a spring glowing with soft light.",
		"terrains": ["Forest"],
		"choices": [
			{"text": "Drink (+30 HP)", "effects": [{"type": "hp", "value": 30}], "morality": 0},
			{"text": "Bathe (+Random Fragment)", "effects": [{"type": "fragment", "value": "random"}], "morality": 0},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},
	"LOST_FAIRY": {
		"id": 5,
		"title": "Lost Fairy",
		"description": "A small fairy is trapped in a spider web, glowing weakly.",
		"terrains": ["Forest"],
		"choices": [
			{"text": "Free it (+20 XP, +1 Morality)", "effects": [{"type": "xp", "value": 20}], "morality": 1},
			{"text": "Kill it (+Random Spell, -1 Morality)", "effects": [{"type": "spell", "value": "random"}], "morality": -1},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},

	# Desert
	"CARAVAN_WRECKAGE": {
		"id": 6,
		"title": "Desert Caravan Wreckage",
		"description": "A massive caravan wagon is buried under the sand, still loaded with supplies.",
		"terrains": ["Desert"],
		"choices": [
			{"text": "Dig (+100 Gold, -20 HP)", "effects": [{"type": "gold", "value": 100}, {"type": "hp", "value": -20}], "morality": 0},
			{"text": "Search for relics (+Random Fragment)", "effects": [{"type": "fragment", "value": "random"}], "morality": 0},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	},
	"GHOST_SANDSTORM": {
		"id": 7,
		"title": "Ghost in the Sandstorm",
		"description": "A translucent ghost appears before you, seemingly with unfinished business.",
		"terrains": ["Desert"],
		"choices": [
			{"text": "Listen (+20 XP)", "effects": [{"type": "xp", "value": 20}], "morality": 0},
			{"text": "Attack (Enter Battle, +Spell)", "effects": [{"type": "battle", "value": "elite"}], "morality": -1},
			{"text": "Give offerings (-20 Gold, +30 XP, +1 Morality)", "effects": [{"type": "gold", "value": -20}, {"type": "xp", "value": 30}], "morality": 1}
		]
	},
	"THIRSTY_REFUGEES": {
		"id": 8,
		"title": "Thirsty Refugees",
		"description": "A group of ragged refugees begs you for water.",
		"terrains": ["Desert"],
		"choices": [
			{"text": "Share water (-10 Gold, +1 Morality)", "effects": [{"type": "gold", "value": -10}], "morality": 1},
			{"text": "Rob them (+20 Gold, -1 Morality)", "effects": [{"type": "gold", "value": 20}], "morality": -1},
			{"text": "Ignore them", "effects": [], "morality": 0}
		]
	},

	# Volcano
	"LAVA_CHEST": {
		"id": 9,
		"title": "Chest in the Lava",
		"description": "A glittering chest floats in the middle of a lava pool.",
		"terrains": ["Volcano"],
		"choices": [
			{"text": "Use ice magic (-1 Ice Fragment, +100 Gold, +Random Spell)", "effects": [{"type": "gold", "value": 100}, {"type": "spell", "value": "random"}], "morality": 0},
			{"text": "Jump across (-50 HP, +100 Gold, +Random Spell)", "effects": [{"type": "hp", "value": -50}, {"type": "gold", "value": 100}, {"type": "spell", "value": "random"}], "morality": 0},
			{"text": "Leave", "effects": [], "morality": 0}
		]
	}
}

const SPEC_EVENTS = {
	"VILLAGER_VENGEANCE": {
		"id": 99,
		"title": "Villager Vengeance",
		"description": "A group of angry villagers ambushes you on the road. They remember what you did.",
		"is_special": true,
		"choices": [
			{"text": "Apologize (-50 Gold)", "effects": [{"type": "gold", "value": -50}], "morality": 0},
			{"text": "Fight (Enter Battle)", "effects": [{"type": "battle", "value": "normal"}], "morality": 0},
			{"text": "Run away (-20 HP)", "effects": [{"type": "hp", "value": -20}], "morality": 0}
		]
	}
}

static func get_random_event(terrain: String, seen_ids: Array[int] = []) -> Dictionary:
	var valid_keys: Array = []
	var unseen_keys: Array = []
	for key in EVENTS.keys():
		var event_terrains: Array = EVENTS[key]["terrains"]
		if terrain in event_terrains:
			valid_keys.append(key)
			if not EVENTS[key]["id"] in seen_ids:
				unseen_keys.append(key)
	if valid_keys.is_empty():
		return EVENTS["ABANDONED_CAMPFIRE"]
	# Try to select events not seen before
	var pool = unseen_keys if not unseen_keys.is_empty() else valid_keys
	var random_key = pool.pick_random()
	return EVENTS[random_key]

static func get_karma_event() -> Dictionary:
	return SPEC_EVENTS["VILLAGER_VENGEANCE"]
