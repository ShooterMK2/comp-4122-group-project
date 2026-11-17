class_name EnemySpellLibrary
extends RefCounted
# Deprecated: enemy actions use EnemySkillLibrary / SkillDefinition.
# Kept so old references do not break project load; do not use for new content.

const K := SpellEffect.Kind

static func mend(amount: int) -> SpellDefinition:
	var s := SpellDefinition.make(&"mend", "Mend", SpellPattern.make([]), [], 0,
		[SpellEffect.make(K.HEAL, amount)])
	s.target_kind = SpellDefinition.TargetKind.SELF
	return s
