class_name BattleFlow
extends RefCounted
# The single source of truth for "what is the battle doing right now".
# The controller asks these predicates before accepting any input.

enum Phase { SETUP, ENEMY_TURN, CHANTING, CASTING, DEADLOCK, ENDED }

signal changed(phase: Phase)

var phase: Phase = Phase.SETUP


func enter(next: Phase) -> void:
	if next == phase:
		return
	phase = next
	changed.emit(next)


func can_place() -> bool:
	return phase == Phase.CHANTING

func can_start_casting() -> bool:
	return phase == Phase.CHANTING

func can_use_ultimate() -> bool:
	return phase == Phase.CHANTING

func can_cast_spell() -> bool:
	return phase == Phase.CASTING

func can_end_turn() -> bool:
	return phase == Phase.CASTING

func can_resolve_deadlock() -> bool:
	return phase == Phase.DEADLOCK

func can_select_target() -> bool:
	return phase != Phase.SETUP and phase != Phase.ENDED

func is_ended() -> bool:
	return phase == Phase.ENDED
