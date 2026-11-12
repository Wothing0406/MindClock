"""Create clean transparent SVG rank/avatar frames inspired by the approved atlas concept."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "demo/assets/game"
TARGET = ROOT / "ui/rank"
TARGET.mkdir(parents=True, exist_ok=True)

TIERS = {
    "thuong": ("#6E817F", "#C9D0C4", 0),
    "dong": ("#8E5D49", "#D8A887", 1),
    "bac": ("#8295A0", "#E1E5DF", 2),
    "vang": ("#A7782F", "#F1D68B", 3),
    "bach-kim": ("#8AABB4", "#F1F1E8", 4),
    "kim-cuong": ("#43739A", "#B4D9F0", 5),
    "tinh-anh": ("#375E56", "#D5D2A2", 6),
}
for name, (dark, light, level) in TIERS.items():
    emblem = {
        0: "",
        1: '<path d="M53 13 L64 7 L75 13 L70 21 L58 21 Z" />',
        2: '<path d="M49 20 L64 6 L79 20 L72 25 L64 16 L56 25 Z" />',
        3: '<path d="M44 20 L52 7 L64 15 L76 7 L84 20 L64 28 Z" />',
        4: '<path d="M43 20 L52 7 L64 13 L76 7 L85 20 L78 27 L64 19 L50 27 Z" />',
        5: '<path d="M45 22 L52 5 L64 16 L76 5 L83 22 L64 29 Z" />',
        6: '<path d="M39 25 L48 8 L56 15 L64 3 L72 15 L80 8 L89 25 L64 30 Z" />',
    }[level]
    facets = "" if level < 3 else (
        '<path d="M19 47 L8 54 L19 60 M109 47 L120 54 L109 60" fill="none" stroke-width="3" />'
    )
    bottom = "" if level == 0 else (
        f'<path d="M40 112 Q64 121 88 112 L82 120 Q64 127 46 120 Z" fill="url(#metal)" stroke="{dark}" stroke-width="2" />'
    )
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
<defs><linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{light}"/><stop offset=".5" stop-color="{dark}"/><stop offset="1" stop-color="{light}"/></linearGradient></defs>
<circle cx="64" cy="66" r="49" fill="none" stroke="{dark}" stroke-width="8"/>
<circle cx="64" cy="66" r="46" fill="none" stroke="url(#metal)" stroke-width="5"/>
<circle cx="64" cy="66" r="39" fill="none" stroke="{light}" stroke-opacity=".65" stroke-width="1"/>
<g fill="url(#metal)" stroke="{dark}" stroke-width="2">{emblem}</g>
<g stroke="{light}" stroke-linecap="round">{facets}</g>{bottom}
</svg>'''
    (TARGET / f"{name}.svg").write_text(svg, encoding="utf-8")

PASSIVES = {
    "ha-nhan": '<circle cx="48" cy="48" r="31" fill="none" stroke="#B6C49A" stroke-width="5"/><circle cx="48" cy="48" r="23" fill="none" stroke="#DFD5AC" stroke-width="2"/><path d="M20 20h14v8H20zM62 68h14v8H62z" fill="#DED3AB"/>',
    "han-boi-phap": '<path d="M28 68h40v10H28zM32 56h32v9H32zM36 44h24v9H36zM40 33h16v8H40z" fill="#D7BC78" stroke="#4D6472" stroke-width="2"/><circle cx="48" cy="48" r="37" fill="none" stroke="#9BB2B8" stroke-width="2"/>',
    "tuyet-dinh": '<path d="M18 60Q49 17 76 25 M28 70Q56 34 80 39 M36 80Q65 49 78 57" fill="none" stroke="#2D3032" stroke-width="8" stroke-linecap="round"/><path d="M62 22l14 3-6 12" fill="none" stroke="#B65A50" stroke-width="5"/>',
}
for slug, artwork in PASSIVES.items():
    folder = ROOT / "characters" / slug / "fx"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "passive.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">'
        + artwork + '</svg>', encoding="utf-8"
    )
print("Built 7 transparent rank/avatar frames and 3 passive marks")
