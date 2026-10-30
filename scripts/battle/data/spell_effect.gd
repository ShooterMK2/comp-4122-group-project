class_name SpellEffect
extends Resource

# amount  = main value, amount2 = secondary value (see describe()).
enum Kind {
	BURN,        # apply Burn to target
	SELF_BURN,   # apply Burn to the caster (Fire risk)
	DETONATE,    # consume all target Burn; damage = amount per stack
	CHILL,       # apply Chill to target
	FORTIFY,     # caster gains `amount` persistent Shield
	SMITE,       # spend `amount` Shield, deal `amount2` bonus damage per point
	TAILWIND,    # grant Tailwind stacks after resolving
	DECAY,       # apply Decay to target
	CONDUCTIVE,  # apply Conductive to target after resolving
	OVERLOAD,    # on queue: draw `amount` fragments, draw `amount2` fewer next turn
	HEAL		 # caster restores `amount` HP
}

@export var kind: Kind = Kind.BURN
@export var amount: int = 1
@export var amount2: int = 0

static func make(k: Kind, n: int = 1, n2: int = 0) -> SpellEffect:
	var e := SpellEffect.new()
	e.kind = k
	e.amount = n
	e.amount2 = n2
	return e

func describe() -> String:
	match kind:
		Kind.BURN: return "Burn +%d" % amount
		Kind.SELF_BURN: return "Self Burn +%d" % amount
		Kind.DETONATE: return "Detonate: %d dmg per Burn" % amount
		Kind.CHILL: return "Chill +%d" % amount
		Kind.FORTIFY: return "Fortify +%d Shield" % amount
		Kind.SMITE: return "Smite: spend %d Shield, +%d dmg each" % [amount, amount2]
		Kind.TAILWIND: return "Tailwind +%d" % amount
		Kind.DECAY: return "Decay +%d" % amount
		Kind.CONDUCTIVE: return "Conductive +%d" % amount
		Kind.OVERLOAD: return "Overload: draw %d, next turn -%d" % [amount, amount2]
		Kind.HEAL: return "Heal +%d HP" % amount
	return ""
