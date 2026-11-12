"""Mechanical QA for T009. Human animation review remains required."""
from __future__ import annotations

import hashlib
import json
import re
import struct
import wave
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "demo/assets/game"
manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
assert manifest["logical_stage_px"] == [360, 380]
assert manifest["display_actor_size_px"] == [240, 240]
assert manifest["actor_root_px"] == {"left": [92, 350], "right": [268, 350]}
for slug, facing in (("ha-nhan", "right"), ("han-boi-phap", "right"), ("tuyet-dinh", "left")):
    folder = ROOT / "characters" / slug
    assert manifest["characters"][slug]["native_facing"] == facing
    idle = Image.open(folder / "runtime/idle.webp").convert("RGBA")
    assert idle.size == (512, 512)
    box = idle.getchannel("A").getbbox()
    assert box and 350 <= box[3] - box[1] <= 430 and 450 <= box[3] <= 495, (slug, box)
    for action, count in (("basic",6),("skill1",6),("skill2",6),("victory",6),("hurt",4),("stun",4),("heal",4)):
        data = manifest["characters"][slug]["actions"][action]
        assert len(data["frames"]) == count
        assert data["root_px"] == [256, 478]
        assert (folder / "runtime" / data["clip"]).exists()
        for frame_name in data["frames"]:
            frame = Image.open(folder / "runtime" / frame_name).convert("RGBA")
            assert frame.size == (512, 512)
            b = frame.getchannel("A").getbbox()
            assert b and b[0] > 5 and b[2] < 505 and b[3] < 505, (slug, action, frame_name, b)
    hashes = []
    for action in ("basic", "skill1", "skill2"):
        path = folder / "fx" / f"{action}.svg"
        content = path.read_text(encoding="utf-8")
        assert "<svg" in content and "<rect" not in content
        hashes.append(hashlib.sha256(path.read_bytes()).hexdigest())
    assert len(set(hashes)) == 3
    assert (folder / "fx/passive.svg").exists()
    for cue in ("basic", "skill1", "skill2", "stun", "victory"):
        path = folder / "audio" / f"{cue}.wav"
        with wave.open(str(path)) as wav:
            assert wav.getnchannels() == 1 and wav.getsampwidth() == 2 and wav.getframerate() == 22050
            raw = wav.readframes(wav.getnframes())
            samples = struct.unpack(f"<{len(raw)//2}h", raw)
            assert max(abs(v) for v in samples) <= 12000
            assert 0.08 <= wav.getnframes() / wav.getframerate() <= 2.0
for name in ("impact", "healing", "stun"):
    assert (ROOT / "effects/runtime" / f"{name}.svg").exists()
for name in ("impact", "heal"):
    assert (ROOT / "audio" / f"{name}.wav").exists()
for name in ("thuong", "dong", "bac", "vang", "bach-kim", "kim-cuong", "tinh-anh"):
    assert (ROOT / "ui/rank" / f"{name}.svg").exists()
badge_hashes = []
for name in ("dong", "bac", "vang", "bach-kim", "kim-cuong", "tinh-anh"):
    path = ROOT / "ui/rank/badges" / f"{name}.svg"
    assert path.exists() and path.read_text(encoding="utf-8").startswith("<svg")
    assert ET.parse(path).getroot().tag.endswith("svg")
    badge_hashes.append(hashlib.sha256(path.read_bytes()).hexdigest())
assert len(set(badge_hashes)) == 6
for item in manifest["avatars"]:
    avatar = Image.open(ROOT / item).convert("RGBA")
    assert avatar.size == (256, 256) and avatar.getpixel((0, 0))[3] == 0
assert Image.open(ROOT / manifest["map"]).height > Image.open(ROOT / manifest["map"]).width
html = (ROOT.parents[1] / "arena.html").read_text(encoding="utf-8")
js = (ROOT.parents[1] / "arena.js").read_text(encoding="utf-8")
used_ids = set(re.findall(r'\$\("([^"]+)"\)', js))
dom_ids = set(re.findall(r'id="([^"]+)"', html))
assert len(dom_ids) == len(re.findall(r'id="([^"]+)"', html)), "Duplicate HTML id"
assert not (used_ids - dom_ids), f"Missing DOM ids: {used_ids - dom_ids}"
for url in ("arena-rules.js", "profile-rules.js", "arena-renderer.js", "arena.js"):
    assert f'src="./{url}"' in html
for local in re.findall(r'(?:src|href)="(\./assets/game/[^"]+)"', html):
    assert (ROOT.parents[1] / local).exists(), f"Missing HTML asset: {local}"
print("PASS 3 characters, 21 clips, 9 projectile FX, 17 cues, map, 6 avatars, 7 frames, 6 badges")
