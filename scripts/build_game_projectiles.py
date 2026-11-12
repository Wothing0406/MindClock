"""Create nine original, transparent, character-specific combat FX vectors."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "demo/assets/game/characters"
FX = {
    "ha-nhan": {
        "basic": ("#e8d6ad", '<path d="M14 78 Q58 17 116 34 Q66 44 26 105" fill="none" stroke="currentColor" stroke-width="12" stroke-linecap="round"/><path d="M23 95 L40 100 L35 113" fill="none" stroke="currentColor" stroke-width="5"/>'),
        "skill1": ("#b9dfc6", '<path d="M22 101 L95 25 L107 44 L42 110 Z" fill="currentColor" opacity=".8"/><path d="M22 101 L58 85 L42 110 Z M95 25 L79 58 L107 44 Z" fill="#f4e4b5"/><path d="M10 112 Q63 8 115 16" fill="none" stroke="#f6ead2" stroke-width="5"/>'),
        "skill2": ("#9dd8cf", '<circle cx="64" cy="64" r="35" fill="none" stroke="currentColor" stroke-width="8" stroke-dasharray="95 22 48 22"/><circle cx="64" cy="64" r="20" fill="none" stroke="#f7ebca" stroke-width="5"/><path d="M28 93 Q60 105 98 86" fill="none" stroke="#f7ebca" stroke-width="7"/>'),
    },
    "han-boi-phap": {
        "basic": ("#e3c77f", '<path d="M64 8 L105 43 L94 94 L64 118 L34 94 L23 43 Z" fill="none" stroke="currentColor" stroke-width="8"/><path d="M64 28 L85 51 L77 82 L64 96 L51 82 L43 51 Z" fill="#799ac4" opacity=".8"/>'),
        "skill1": ("#d9c17b", '<path d="M28 102 L28 72 L42 72 L42 50 L54 50 L54 30 L74 30 L74 50 L86 50 L86 72 L100 72 L100 102 Z" fill="currentColor" opacity=".86"/><path d="M22 105 H106 M37 72 H91 M49 51 H79" stroke="#f7efd2" stroke-width="6"/><path d="M64 7 L72 23 L64 30 L56 23 Z" fill="#f7efd2"/>'),
        "skill2": ("#9db9de", '<path d="M64 7 L104 28 L108 79 L64 118 L20 79 L24 28 Z" fill="none" stroke="currentColor" stroke-width="9"/><path d="M64 26 L87 39 L91 71 L64 96 L37 71 L41 39 Z" fill="none" stroke="#f4d894" stroke-width="7"/><path d="M64 44 L77 64 L64 83 L51 64 Z" fill="#f4d894"/>'),
    },
    "tuyet-dinh": {
        "basic": ("#e78d74", '<path d="M13 99 Q68 4 119 22 Q83 36 31 112" fill="none" stroke="currentColor" stroke-width="11" stroke-linecap="round"/><path d="M21 104 L39 110 L33 120" fill="none" stroke="#fff0d6" stroke-width="5"/>'),
        "skill1": ("#e7a177", '<path d="M12 110 Q71 12 117 17" fill="none" stroke="currentColor" stroke-width="17" stroke-linecap="round"/><path d="M22 111 Q77 21 111 22" fill="none" stroke="#291f25" stroke-width="7"/><path d="M65 21 L84 8 M95 31 L119 40" stroke="#f5ddbd" stroke-width="5"/>'),
        "skill2": ("#e87970", '<path d="M10 13 L115 117 M18 115 L111 9" stroke="currentColor" stroke-width="15" stroke-linecap="round"/><path d="M15 17 L112 115 M20 111 L107 11" stroke="#f7e8d4" stroke-width="5" stroke-linecap="round"/><circle cx="64" cy="64" r="17" fill="#e87970" opacity=".5"/>'),
    },
}
for slug, actions in FX.items():
    folder = ROOT / slug / "fx"
    folder.mkdir(parents=True, exist_ok=True)
    for action, (color, shapes) in actions.items():
        svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" fill="none" color="{color}">{shapes}</svg>'
        (folder / f"{action}.svg").write_text(svg, encoding="utf-8")
COMMON = {
    "impact": '<path d="M64 8 L72 43 L111 20 L83 54 L120 64 L83 72 L107 109 L72 84 L64 121 L55 83 L17 108 L44 72 L8 64 L44 55 L20 18 L55 44 Z" fill="#f2d3a6" opacity=".82"/><circle cx="64" cy="64" r="25" fill="none" stroke="#db8c76" stroke-width="5"/>',
    "healing": '<circle cx="64" cy="64" r="49" fill="none" stroke="#a9d5b3" stroke-width="6"/><circle cx="64" cy="64" r="31" fill="none" stroke="#e4dfb3" stroke-width="5"/><path d="M64 37 V91 M38 64 H90" stroke="#f2e9cd" stroke-width="7" stroke-linecap="round"/>',
    "stun": '<ellipse cx="64" cy="67" rx="50" ry="23" fill="none" stroke="#edca85" stroke-width="8" stroke-dasharray="14 9"/><path d="M40 22 L51 38 L32 44 M91 23 L81 39 L100 44" fill="none" stroke="#f7e6b6" stroke-width="6" stroke-linecap="round"/>',
}
common_dir = ROOT.parent / "effects" / "runtime"
common_dir.mkdir(parents=True, exist_ok=True)
for name, shapes in COMMON.items():
    (common_dir / f"{name}.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">{shapes}</svg>',
        encoding="utf-8",
    )
print("Built 9 distinct projectiles and 3 common transparent status FX")
