class_name FragmentDeckDraw
extends RefCounted

var draw_pile: Array[FragmentData] = []
var discard_pile: Array[FragmentData] = []

func setup_from_definitions(defs: Array) -> void:
	draw_pile.clear()
	discard_pile.clear()
	for d in defs:
		var fd: FragmentDefinition = d as FragmentDefinition
		if fd != null:
			draw_pile.append(fd.make_fragment())
	_shuffle(draw_pile)

func draw(count: int) -> Array[FragmentData]:
	var out: Array[FragmentData] = []
	for i in count:
		var f := _draw_one()
		if f == null:
			break
		out.append(f)
	return out

func discard(fragment: FragmentData) -> void:
	if fragment != null:
		discard_pile.append(fragment)

func discard_many(fragments: Array[FragmentData]) -> void:
	for f in fragments:
		discard(f)

func _draw_one() -> FragmentData:
	if draw_pile.is_empty():
		_reshuffle_discard()
	if draw_pile.is_empty():
		return null
	return draw_pile.pop_back()

func _reshuffle_discard() -> void:
	if discard_pile.is_empty():
		return
	for f in discard_pile:
		draw_pile.append(f)
	discard_pile.clear()
	_shuffle(draw_pile)

static func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
