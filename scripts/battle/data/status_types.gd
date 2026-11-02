class_name StatusTypes
extends RefCounted

enum Status { BURN, CHILL, FREEZE, DECAY, CORRUPTION, TAILWIND, CONDUCTIVE, BREAK }

static func status_name(s: int) -> String:
	return Status.keys()[s].capitalize()