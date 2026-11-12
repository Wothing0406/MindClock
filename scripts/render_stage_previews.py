"""Render static stage contact images for manual sprite size/facing review."""
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "demo/assets/game"
OUT = ROOT / "tasks/T009-arena-doc-va-asset"
source = Image.open(ART / "maps/study-courtyard.webp").convert("RGBA")
w, h = source.size
crop_h = round(w * 380 / 360)
top = round(h * .30)
background = ImageEnhance.Brightness(source.crop((0, top, w, top + crop_h)).resize((360, 380))).enhance(.65)

def sprite(slug: str, side: str) -> Image.Image:
    picture = Image.open(ART / "characters" / slug / "runtime/idle.webp").convert("RGBA")
    native = "right" if slug == "ha-nhan" else "left"
    wanted = "right" if side == "left" else "left"
    if native != wanted:
        picture = picture.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    return picture.resize((240, 240), Image.Resampling.LANCZOS)

for left, right in (("ha-nhan", "han-boi-phap"), ("han-boi-phap", "tuyet-dinh"), ("tuyet-dinh", "ha-nhan")):
    plate = background.copy()
    plate.alpha_composite(sprite(left, "left"), (-28, 126))
    plate.alpha_composite(sprite(right, "right"), (148, 126))
    plate.save(OUT / f"stage-{left}-vs-{right}.png")
print("Rendered 3 portrait stage previews")
