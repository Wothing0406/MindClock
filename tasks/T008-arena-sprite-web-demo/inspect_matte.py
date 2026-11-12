from pathlib import Path
import cv2
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[2] / "demo/assets/arena/motion/source"
for name in ("ha-nhan-basic", "han-boi-phap-states", "tuyet-dinh-skill2"):
    im = np.array(Image.open(root / f"{name}.png").convert("RGB").crop((0, 512, 512, 1024)))
    border = np.concatenate((im[:8].reshape(-1, 3), im[-8:].reshape(-1, 3),
                             im[:, :8].reshape(-1, 3), im[:, -8:].reshape(-1, 3)))
    bg = np.median(border, axis=0)
    diff = np.max(np.abs(im.astype("int16") - bg.astype("int16")), axis=2)
    _, labels, stats, _ = cv2.connectedComponentsWithStats((diff < 29).astype("uint8"), 8)
    indices = np.argsort(stats[1:, 4])[::-1][:8] + 1
    print(name, bg, [
        (int(i), int(stats[i, 4]), tuple(map(int, stats[i, :4])),
         np.mean(im[labels == i], axis=0).astype(int).tolist())
        for i in indices
    ])
