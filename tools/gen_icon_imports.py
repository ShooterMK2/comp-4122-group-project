import os
import hashlib

base = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "icons", "items"))
names = [
	"starter_rod", "starter_robe", "starter_shoes", "starter_necklace",
	"healing_potion", "protective_ring", "fire_booster", "pieces_of_hp",
	"pieces_of_atk", "shield_of_hero", "ult_powerful_charge", "ult_emergency_aid",
	"ult_fighting_spirit", "ult_crowd_control",
]
alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
tmpl = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{name}.png-{hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/icons/items/{name}.png"
dest_files=["res://.godot/imported/{name}.png-{hash}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""
for name in names:
	path = os.path.join(base, name + ".png")
	h = hashlib.md5(open(path, "rb").read()).hexdigest()
	uid = "b" + "".join(alphabet[int(x, 16) % len(alphabet)] for x in h[:12])
	with open(path + ".import", "w", newline="\n") as f:
		f.write(tmpl.format(uid=uid, name=name, hash=h))
	print("import", name)
print("ok")
