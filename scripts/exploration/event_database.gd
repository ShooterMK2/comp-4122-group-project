class_name EventDatabase
extends RefCounted

const EVENTS = {
	"ANCIENT_MONOLITH": {
		"title": "Ancient Monolith",
		"description": "You find a glowing monolith deep in the woods. It hums with ancient energy.",
		"choices": [
			{"text": "Touch it (+Gold, -HP)", "effect": "monolith_touch"},
			{"text": "Pray to it (+Heal)", "effect": "monolith_pray"},
			{"text": "Leave", "effect": "leave"}
		]
	},
	"HOT_SPRING": {
		"title": "Hot Spring",
		"description": "A natural hot spring bubbles before you. The steam smells of sulfur and magic.",
		"choices": [
			{"text": "Rest (+30 HP)", "effect": "spring_rest"},
			{"text": "Bottle the water (+Item)", "effect": "spring_bottle"},
			{"text": "Leave", "effect": "leave"}
		]
	},
	"LOST_MERCHANT": {
		"title": "Lost Merchant",
		"description": "A goblin merchant is trapped under his cart. He offers you a deal.",
		"choices": [
			{"text": "Help him (+Gold)", "effect": "merchant_help"},
			{"text": "Rob him (+Gold, -HP)", "effect": "merchant_rob"},
			{"text": "Ignore him", "effect": "leave"}
		]
	}
}

static func get_random_event() -> Dictionary:
	var keys = EVENTS.keys()
	var random_key = keys.pick_random()
	return EVENTS[random_key]
