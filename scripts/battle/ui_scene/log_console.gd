class_name LogConsole
extends CanvasLayer
# Pop-up battle log. Toggle with the backtick key. Display only.

const TOGGLE_KEY := KEY_QUOTELEFT    # TUNABLE: backtick; matched on the physical key
const COLORS := {                    # TUNABLE: colour per log kind
	"round": "#9aa3b2",
	"player": "#e6e9f0",
	"enemy": "#ffb066",
	"status": "#c792ea",
	"weak": "#ffd866",
	"system": "#6fd3ff",
}

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == TOGGLE_KEY:
		%Root.visible = not %Root.visible
		get_viewport().set_input_as_handled()

func add_entry(kind: String, text: String) -> void:
	var col: String = COLORS.get(kind, "#e6e9f0")
	%Log.append_text("[color=%s]%s[/color]\n" % [col, text.replace("[", "[lb]")])

func add_lines(lines: Array, kind: String = "system") -> void:
	for l in lines:
		add_entry(kind, str(l))