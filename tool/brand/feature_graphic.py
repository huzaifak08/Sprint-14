"""Adds the title and tagline to the Play Store feature graphic.

Run after render_brand_test.dart (needs Pillow):
    python tool/brand/feature_graphic.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "distribution", "store_listing", "feature_graphic_base.png")
OUT = os.path.join(ROOT, "distribution", "store_listing", "feature_graphic.png")
FONTS = os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts")


def font(name, size):
    try:
        return ImageFont.truetype(os.path.join(FONTS, name), size)
    except OSError:
        return ImageFont.load_default()


img = Image.open(SRC).convert("RGBA")
draw = ImageDraw.Draw(img)
x = 470
draw.text((x, 150), "Digital Munshi", font=font("segoeuib.ttf", 72), fill="white")
draw.text(
    (x, 250),
    "Your ledger, shared expenses\nand business books in one place",
    font=font("segoeui.ttf", 34),
    fill=(255, 255, 255, 225),
    spacing=10,
)
# Translucent pill: drawn on its own layer and blended (drawing a
# semi-transparent fill directly would overwrite the pixels).
pill_font = font("segoeuib.ttf", 24)
label = "Works offline  ·  Syncs to cloud"
left, top, right, bottom = draw.textbbox((0, 0), label, font=pill_font)
pad_x, pad_y = 22, 10
layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
ImageDraw.Draw(layer).rounded_rectangle(
    (x, 370, x + (right - left) + 2 * pad_x, 370 + (bottom - top) + 2 * pad_y + 4),
    radius=24,
    fill=(255, 255, 255, 48),
)
img.alpha_composite(layer)
ImageDraw.Draw(img).text((x + pad_x, 370 + pad_y - top + 2), label, font=pill_font, fill="white")
img.convert("RGB").save(OUT)
os.remove(SRC)
print("Wrote", OUT)
