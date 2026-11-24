class_name ZoneConfig
extends RefCounted

## One exploration map with an exit = one zone.

const ZONE_1 := 1

static func current_zone_id() -> int:
	if Engine.get_main_loop() != null and Engine.get_main_loop().root != null:
		var run: Node= Engine.get_main_loop().root.get_node_or_null("RunState")
		if run != null:
			return int(run.zone_id)
	return ZONE_1

static func zone_1_level_min() -> int:
	return 1

static func zone_1_level_max() -> int:
	return 20
