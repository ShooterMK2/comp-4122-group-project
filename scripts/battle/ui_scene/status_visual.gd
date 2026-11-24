class_name StatusVisuals
extends RefCounted
# Hook for status effects on the actor's art. Empty on purpose.
# Add rows to tint a sprite while a status is active, e.g.
#   StatusTypes.Status.FREEZE: Color(0.7, 0.85, 1.0),
# Later you can extend tint_for() with shaders or overlay scenes.

const TINTS := {
}

static func tint_for(statuses: Dictionary) -> Color:
	var tint := Color.WHITE
	for s in statuses.keys():
		if int(statuses[s]) > 0 and TINTS.has(s):
			tint *= TINTS[s]
	return tint