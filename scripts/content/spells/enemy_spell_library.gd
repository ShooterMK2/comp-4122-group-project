class_name EnemySpellLibrary
extends RefCounted
# Spells cast by enemies. No board, so no pattern or requirements.
# To give a spell an element (Tailwind, Shatter checks), add one ElementRequirement as a tag.

const K := SpellEffect.Kind

static func mend(amount: int) -> SpellDefinition:
	var s := SpellDefinition.make(&"mend", "Mend", SpellPattern.make([]), [], 0,
		[SpellEffect.make(K.HEAL, amount)])
	s.target_kind = SpellDefinition.TargetKind.SELF
	return s

static func flail(damage: int) -> SpellDefinition:
	return SpellDefinition.make(&"flail", "Flail", SpellPattern.make([]), [], damage, [])