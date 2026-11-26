class_name _EnemyActor
extends Control
signal clicked
signal spell_dropped(definition: SpellDefinition)

@onready var _hitbox: ActorHitbox = $ActorHitbox
@onready var _slot: SpriteSlot = $SpriteWarpper/SpriteSlot
@onready var _placeholder: ColorRect = $Placeholder

func _ready() -> void:
	_hitbox.clicked.connect(func(): clicked.emit())
	_hitbox.spell_dropped.connect(func(d: SpellDefinition): spell_dropped.emit(d))

func setup(def: EnemyDefinition) -> void:
	%NameLabel.text = def.display_name
	%HpBar.max_value = def.max_hp
	%HpBar.value = def.max_hp
	%HpLabel.text = "%d/%d" % [def.max_hp, def.max_hp]

	var tex := AssetLookup.character(def.art_name)
	_slot.visible = tex != null
	_placeholder.visible = tex == null
	if tex == null:
		_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_placeholder.color = def.placeholder_color
		$Placeholder/Label.text = def.display_name
		return

	var frames := SpriteFrames.new()
	if not frames.has_animation(&"default"):
		frames.add_animation(&"default")
	frames.add_frame(&"default", tex)
	%Sprite.sprite_frames = frames
	%Sprite.play(&"default")
	_slot.refit.call_deferred()

func set_drop_enabled(on: bool) -> void:
	_hitbox.drop_enabled = on


func set_alive(alive: bool) -> void:
	_hitbox.enabled = alive
	modulate = Color.WHITE if alive else Color(0.45, 0.45, 0.45)

func set_selected(on: bool) -> void:
	_hitbox.selected = on
