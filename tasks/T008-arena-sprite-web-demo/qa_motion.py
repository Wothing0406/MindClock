from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / "demo/assets/arena/motion/frames"
names = [
    "ha-nhan-basic", "ha-nhan-skill1", "ha-nhan-skill2",
    "han-boi-phap-basic", "han-boi-phap-skill1", "han-boi-phap-skill2",
    "tuyet-dinh-basic", "tuyet-dinh-skill1", "tuyet-dinh-skill2",
    "ha-nhan-hurt", "han-boi-phap-stun", "tuyet-dinh-heal",
    "fx-healing", "fx-tower", "fx-ink", "fx-stun", "fx-impact",
]
width, height = 256, 290
out = Image.new("RGB", (4 * width, 5 * height), "#203036")
draw = ImageDraw.Draw(out)
for i, name in enumerate(names):
    frame = Image.open(root / name / "f03.webp").convert("RGBA")
    frame.thumbnail((width, 255))
    tile = Image.new("RGBA", (width, 255), "#203036")
    tile.alpha_composite(frame, ((width - frame.width) // 2, (255 - frame.height) // 2))
    x, y = i % 4 * width, i // 4 * height
    out.paste(tile.convert("RGB"), (x, y))
    draw.text((x + 8, y + 263), name, fill="white")
out.save(Path(__file__).with_name("qc-motion-contact.jpg"), quality=88)
