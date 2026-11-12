"""Original vector rank emblems. These are separate from avatar border frames."""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "demo/assets/game/ui/rank/badges"
OUT.mkdir(parents=True, exist_ok=True)
BADGES = {
    "dong": ("#b97645", "#f2d0a4", '<circle cx="64" cy="64" r="38" fill="none" stroke="currentColor" stroke-width="8"/><path d="M43 79 V50 L64 38 L85 50 V79 L64 91 Z" fill="currentColor" opacity=".8"/><path d="M52 75 L64 55 L76 75" fill="none" stroke="#fff3dd" stroke-width="7"/>'),
    "bac": ("#a6bdc6", "#e3f0ed", '<path d="M64 10 L108 45 L96 99 L64 118 L32 99 L20 45 Z" fill="none" stroke="currentColor" stroke-width="8"/><path d="M42 79 L56 38 L70 79 M65 88 L79 47 L91 88" fill="none" stroke="#eaf5ef" stroke-width="8" stroke-linejoin="round"/>'),
    "vang": ("#e8b748", "#fff0b9", '<path d="M20 77 L29 37 L50 59 L64 23 L78 59 L99 37 L108 77 Z" fill="currentColor"/><path d="M20 84 H108 V97 Q64 114 20 97 Z" fill="#a26c29"/><circle cx="64" cy="74" r="9" fill="#fff0c1"/>'),
    "bach-kim": ("#d4e7e7", "#f8ffff", '<path d="M64 7 L77 44 L117 64 L77 84 L64 121 L51 84 L11 64 L51 44 Z" fill="none" stroke="currentColor" stroke-width="9"/><path d="M64 30 L75 64 L64 98 L53 64 Z" fill="#b5d3d9"/><circle cx="64" cy="64" r="10" fill="#fff"/>'),
    "kim-cuong": ("#81d5e1", "#ebffff", '<path d="M25 48 L43 22 H85 L103 48 L64 111 Z" fill="#2b8b9d" stroke="currentColor" stroke-width="7"/><path d="M25 48 H103 M43 22 L52 48 L64 111 L76 48 L85 22" fill="none" stroke="#e6ffff" stroke-width="5"/><path d="M52 48 L64 31 L76 48" fill="#a8eef0"/>'),
    "tinh-anh": ("#caa8ef", "#f7eaff", '<path d="M64 6 L75 38 L105 25 L90 53 L122 64 L90 75 L105 103 L75 90 L64 122 L53 90 L23 103 L38 75 L6 64 L38 53 L23 25 L53 38 Z" fill="currentColor" opacity=".8"/><path d="M64 28 L74 54 L100 64 L74 74 L64 100 L54 74 L28 64 L54 54 Z" fill="#f8edff"/><circle cx="64" cy="64" r="9" fill="#6d518d"/>'),
}
for name, (color, light, shape) in BADGES.items():
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" color="{color}"><title>Huy hiệu hạng {name}</title><circle cx="64" cy="64" r="60" fill="{light}" opacity=".08"/>{shape}</svg>'
    (OUT / f"{name}.svg").write_text(svg, encoding="utf-8")
print("Built 6 distinct rank badges")
