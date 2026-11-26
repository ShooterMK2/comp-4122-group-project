from PIL import Image, ImageDraw
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons", "items")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)
SIZE = 128
BG = (245, 242, 235, 255)


def new():
	img = Image.new("RGBA", (SIZE, SIZE), BG)
	return img, ImageDraw.Draw(img)


def save(img, name):
	path = os.path.join(OUT, name + ".png")
	img.save(path, "PNG")
	print("wrote", path)


img, d = new()
d.rectangle([58, 20, 70, 110], fill=(139, 90, 43, 255))
d.ellipse([48, 12, 80, 44], fill=(90, 160, 220, 255), outline=(40, 80, 120, 255))
d.polygon([(64, 18), (72, 8), (56, 8)], fill=(200, 220, 255, 255))
save(img, "starter_rod")

img, d = new()
d.polygon([(64, 18), (100, 50), (92, 110), (36, 110), (28, 50)], fill=(70, 100, 170, 255), outline=(30, 50, 90, 255))
d.rectangle([54, 18, 74, 36], fill=(90, 120, 190, 255))
d.ellipse([50, 8, 78, 30], fill=(210, 180, 140, 255))
save(img, "starter_robe")

img, d = new()
d.rounded_rectangle([28, 70, 70, 100], radius=10, fill=(80, 60, 40, 255))
d.rounded_rectangle([58, 62, 100, 100], radius=10, fill=(100, 75, 50, 255))
d.ellipse([30, 88, 55, 108], fill=(50, 40, 30, 255))
d.ellipse([70, 88, 98, 110], fill=(50, 40, 30, 255))
save(img, "starter_shoes")

img, d = new()
d.arc([24, 20, 104, 90], 20, 160, fill=(200, 170, 60, 255), width=6)
d.ellipse([52, 78, 76, 108], fill=(80, 160, 200, 255), outline=(40, 90, 130, 255), width=3)
d.ellipse([58, 84, 70, 96], fill=(180, 230, 255, 255))
save(img, "starter_necklace")

img, d = new()
d.rectangle([54, 18, 74, 36], fill=(180, 180, 180, 255))
d.polygon([(44, 40), (84, 40), (90, 105), (38, 105)], fill=(220, 70, 70, 255), outline=(120, 30, 30, 255))
d.ellipse([50, 55, 78, 85], fill=(255, 140, 140, 180))
save(img, "healing_potion")

img, d = new()
d.ellipse([28, 28, 100, 100], outline=(180, 150, 60, 255), width=12)
d.ellipse([48, 48, 80, 80], outline=(220, 190, 100, 255), width=4)
d.rectangle([56, 20, 72, 40], fill=(160, 200, 255, 255), outline=(60, 100, 160, 255))
save(img, "protective_ring")

img, d = new()
d.ellipse([30, 40, 98, 108], fill=(40, 40, 50, 255))
d.polygon([(64, 24), (82, 70), (64, 58), (46, 70)], fill=(255, 120, 40, 255))
d.polygon([(64, 40), (74, 72), (64, 64), (54, 72)], fill=(255, 220, 80, 255))
save(img, "fire_booster")

img, d = new()
d.polygon([(64, 100), (28, 55), (40, 30), (64, 48), (88, 30), (100, 55)], fill=(220, 50, 70, 255), outline=(140, 20, 40, 255))
d.line([(64, 48), (64, 100)], fill=(255, 180, 190, 255), width=3)
save(img, "pieces_of_hp")

img, d = new()
d.polygon([(70, 18), (78, 26), (50, 90), (40, 82)], fill=(200, 210, 230, 255), outline=(80, 90, 110, 255))
d.rectangle([36, 86, 58, 96], fill=(140, 100, 50, 255))
d.rectangle([48, 96, 56, 110], fill=(100, 70, 40, 255))
save(img, "pieces_of_atk")

img, d = new()
d.polygon([(64, 16), (104, 36), (96, 90), (64, 112), (32, 90), (24, 36)], fill=(70, 120, 200, 255), outline=(30, 60, 120, 255), width=3)
d.polygon([(64, 30), (88, 44), (82, 82), (64, 98), (46, 82), (40, 44)], fill=(240, 210, 80, 255))
d.line([(64, 40), (64, 88)], fill=(180, 140, 40, 255), width=4)
d.line([(48, 60), (80, 60)], fill=(180, 140, 40, 255), width=4)
save(img, "shield_of_hero")

img, d = new()
d.ellipse([24, 24, 104, 104], fill=(60, 40, 90, 255))
d.polygon([(64, 28), (86, 64), (64, 56), (42, 64)], fill=(255, 200, 60, 255))
d.arc([40, 70, 88, 100], 200, 340, fill=(255, 160, 40, 255), width=6)
save(img, "ult_powerful_charge")

img, d = new()
d.ellipse([24, 24, 104, 104], fill=(40, 90, 70, 255))
d.polygon([(64, 90), (36, 50), (48, 30), (64, 46), (80, 30), (92, 50)], fill=(120, 230, 160, 255))
d.rectangle([56, 34, 72, 52], fill=(200, 255, 220, 255))
save(img, "ult_emergency_aid")

img, d = new()
d.ellipse([24, 24, 104, 104], fill=(120, 50, 40, 255))
d.polygon([(64, 22), (78, 55), (112, 55), (84, 76), (96, 110), (64, 88), (32, 110), (44, 76), (16, 55), (50, 55)], fill=(255, 180, 60, 255), outline=(180, 100, 20, 255))
save(img, "ult_fighting_spirit")

img, d = new()
d.ellipse([24, 24, 104, 104], fill=(40, 50, 90, 255))
for cx in (44, 64, 84):
	d.ellipse([cx - 10, 48, cx + 10, 78], fill=(180, 200, 255, 255), outline=(80, 100, 160, 255))
d.arc([30, 70, 98, 110], 200, 340, fill=(120, 160, 255, 255), width=5)
save(img, "ult_crowd_control")

print("done")
