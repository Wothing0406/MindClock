"""Synthesize quiet, original PCM cues for the local demo; no licensed samples."""
import json
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1] / "demo/assets/game"
RATE = 22050
RNG = np.random.default_rng(20261112)
CHARACTERS = {"ha-nhan": 250, "han-boi-phap": 315, "tuyet-dinh": 390}
ACTIONS = ("basic", "skill1", "skill2", "stun", "victory")


def cue(action: str, fundamental: float) -> np.ndarray:
    length = {"basic": .22, "skill1": .42, "skill2": .58, "stun": .50,
              "victory": .78, "impact": .18, "heal": .46}[action]
    t = np.arange(round(RATE * length)) / RATE
    envelope = np.sin(np.pi * np.clip(t / length, 0, 1)) ** .8
    noise = RNG.normal(0, 1, len(t))
    if action in ("basic", "impact"):
        tone = np.sin(2 * np.pi * (fundamental * t + 75 * t * t))
        signal = tone * np.exp(-18 * t) + .23 * noise * np.exp(-27 * t)
    elif action == "skill1":
        tone = np.sin(2 * np.pi * (fundamental * t + 260 * t * t))
        signal = .75 * tone + .18 * noise
    elif action == "skill2":
        tone = np.sin(2 * np.pi * (fundamental * t + 420 * t * t))
        signal = .5 * tone + .3 * np.sin(2 * np.pi * fundamental * 1.5 * t) + .1 * noise
    elif action == "stun":
        phase = fundamental * t + 18 * np.sin(2 * np.pi * 5 * t)
        signal = np.sin(2 * np.pi * phase) + .2 * np.sin(2 * np.pi * 2 * fundamental * t)
    else:
        notes = (1.0, 1.25, 1.5)
        note_index = np.minimum((t / (length / 3)).astype(int), 2)
        signal = np.sin(2 * np.pi * fundamental * np.array(notes)[note_index] * t)
    signal *= envelope
    signal *= .23 / max(np.max(np.abs(signal)), .001)
    return np.int16(np.clip(signal, -1, 1) * 32767)


def save(path: Path, samples: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(samples.tobytes())


def main() -> None:
    paths = {}
    for slug, fundamental in CHARACTERS.items():
        paths[slug] = {}
        for action in ACTIONS:
            path = ROOT / "characters" / slug / "audio" / f"{action}.wav"
            save(path, cue(action, fundamental))
            paths[slug][action] = path.relative_to(ROOT).as_posix()
    for action, fundamental in (("impact", 190), ("heal", 440)):
        save(ROOT / "audio" / f"{action}.wav", cue(action, fundamental))
    (ROOT / "audio" / "manifest.json").write_text(
        json.dumps({"source": "procedural original", "rate_hz": RATE,
                    "peak_target_dbfs": -12, "characters": paths,
                    "common": {"impact": "audio/impact.wav", "heal": "audio/heal.wav"}},
                   ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("Built 17 original audio cues")


if __name__ == "__main__":
    main()
