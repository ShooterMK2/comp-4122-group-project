class_name SkillEffect
extends Resource

enum Kind {
	STAT_BUFF,       # amount = stat 0=ATK/1=DEF/2=SPD, amount2 = turns
	STAT_DEBUFF,     # same
	APPLY_AILMENT,   # amount = AilmentTypes.Ailment, amount2 = duration turns
}

@export var kind: Kind = Kind.APPLY_AILMENT
@export var amount: int = 0
@export var amount2: int = 0

static func make(k: Kind, n: int = 0, n2: int = 0) -> SkillEffect:
	var e := SkillEffect.new()
	e.kind = k
	e.amount = n
	e.amount2 = n2
	return e

static func stat_buff(stat: int, turns: int) -> SkillEffect:
	return make(Kind.STAT_BUFF, stat, turns)

static func stat_debuff(stat: int, turns: int) -> SkillEffect:
	return make(Kind.STAT_DEBUFF, stat, turns)

static func apply_ailment(ailment: int, duration: int) -> SkillEffect:
	return make(Kind.APPLY_AILMENT, ailment, duration)

func describe() -> String:
	match kind:
		Kind.STAT_BUFF:
			return "+%s %d turns" % [_stat_name(amount), amount2]
		Kind.STAT_DEBUFF:
			return "-%s %d turns" % [_stat_name(amount), amount2]
		Kind.APPLY_AILMENT:
			return "%s %d turns" % [AilmentTypes.ailment_name(amount), amount2]
	return ""

func _stat_name(stat: int) -> String:
	if stat >= 0 and stat < 3:
		return ["ATK", "DEF", "SPD"][stat]
	return "?"
