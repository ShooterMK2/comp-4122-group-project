"""Convert Cursor-generated JPGs into assets/icons/items/*.png and write .import sidecars."""
from __future__ import annotations

import hashlib
import os
from PIL import Image

SRC = os.path.abspath(
	os.path.join(
		os.path.expanduser("~"),
		".cursor",
		"projects",
		"c-Users-123-Documents-GitHub-comp-4122-group-project",
		"assets",
	)
)
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "icons", "items"))
SIZE = 256
ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789"

NAMES = [
	# existing equipment / consumables / importants / ultimates
	"starter_rod", "starter_robe", "starter_shoes", "starter_necklace",
	"healing_potion", "protective_ring", "fire_booster",
	"pieces_of_hp", "pieces_of_atk", "sealed_letter", "shield_of_hero",
	"ult_powerful_charge", "ult_emergency_aid", "ult_fighting_spirit", "ult_crowd_control",
	# new equipment
	"iron_rod", "duo_staff", "nature_staff", "shock_point", "blood_stick",
	"iron_plate", "stable_chestcover", "heavy_armour", "fittest_top", "speed_shirt",
	"iron_gauntlet", "adventurers_helmet", "bandits_leggings", "knights_shields",
	"hunters_gloves", "merchants_glasses", "dancers_mask", "pupils_note", "priests_necklace",
	# new consumables
	"greater_healing_potion", "barrier_charm",
	"ice_booster", "earth_booster", "wind_booster", "lightning_booster", "dark_booster",
	"strength_tonic", "iron_skin_elixir", "swift_draft", "vitality_draft",
	"pieces_of_def", "pieces_of_spd", "gold_dust",
]

IMPORT_TMPL = """[remap]

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


def uid_for(digest: str) -> str:
	return "b" + "".join(ALPHABET[int(ch, 16) % len(ALPHABET)] for ch in digest[:12])


def convert_one(name: str) -> None:
	src = os.path.join(SRC, name + ".jpg")
	if not os.path.isfile(src):
		# try png source just in case
		src = os.path.join(SRC, name + ".png")
	if not os.path.isfile(src):
		raise FileNotFoundError(src)
	img = Image.open(src).convert("RGBA")
	img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
	os.makedirs(OUT, exist_ok=True)
	out_path = os.path.join(OUT, name + ".png")
	img.save(out_path, "PNG")
	raw = open(out_path, "rb").read()
	digest = hashlib.md5(raw).hexdigest()
	with open(out_path + ".import", "w", newline="\n") as f:
		f.write(IMPORT_TMPL.format(uid=uid_for(digest), name=name, hash=digest))
	print("ok", name)


def main() -> None:
	missing = []
	for name in NAMES:
		try:
			convert_one(name)
		except FileNotFoundError:
			missing.append(name)
	if missing:
		print("MISSING:", ", ".join(missing))
		raise SystemExit(1)
	print("installed", len(NAMES), "icons into", OUT)


if __name__ == "__main__":
	main()
