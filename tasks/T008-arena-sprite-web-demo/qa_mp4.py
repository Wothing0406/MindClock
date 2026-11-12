from pathlib import Path
import cv2
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[2] / "demo/assets/arena/motion/clips"
names = ("ha-nhan-skill2", "han-boi-phap-skill2", "tuyet-dinh-skill2")
out = Image.new("RGB", (3 * 256, 3 * 286), "#203036")
draw = ImageDraw.Draw(out)
for row, name in enumerate(names):
    capture = cv2.VideoCapture(str(root / f"{name}.mp4"))
    for col, index in enumerate((0, 8, 16)):
        capture.set(cv2.CAP_PROP_POS_FRAMES, index)
        ok, frame = capture.read()
        assert ok, (name, index)
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(rgb).resize((256, 256))
        out.paste(image, (col * 256, row * 286))
        draw.text((col * 256 + 8, row * 286 + 261), f"{name} · {index}", fill="white")
    capture.release()
out.save(Path(__file__).with_name("qc-mp4-contact.jpg"), quality=88)
