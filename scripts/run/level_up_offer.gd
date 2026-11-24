class_name LevelUpOffer
extends RefCounted

enum Kind { GOLD, HEAL, CONSUMABLE, FRAGMENT, SPELL }

var kind: int = Kind.GOLD
var label: String = ""
var description: String = ""
var amount: int = 0
var item_id: StringName = &""

static func gold(amount: int) -> LevelUpOffer:
	var o := LevelUpOffer.new()
	o.kind = Kind.GOLD
	o.amount = amount
	o.label = "+%d Gold" % amount
	o.description = "Add gold to this run."
	return o

static func heal(amount: int) -> LevelUpOffer:
	var o := LevelUpOffer.new()
	o.kind = Kind.HEAL
	o.amount = amount
	o.label = "Heal %d HP" % amount
	o.description = "Restore run HP now."
	return o

static func consumable(id: StringName, display: String) -> LevelUpOffer:
	var o := LevelUpOffer.new()
	o.kind = Kind.CONSUMABLE
	o.item_id = id
	o.amount = 1
	o.label = display
	o.description = "Add 1 to inventory."
	return o

static func fragment(id: StringName, display: String) -> LevelUpOffer:
	var o := LevelUpOffer.new()
	o.kind = Kind.FRAGMENT
	o.item_id = id
	o.label = display
	o.description = "Unlock fragment (add to deck in Inventory)."
	return o

static func spell(id: StringName, display: String) -> LevelUpOffer:
	var o := LevelUpOffer.new()
	o.kind = Kind.SPELL
	o.item_id = id
	o.label = display
	o.description = "Unlock spell (add to deck in Inventory)."
	return o
