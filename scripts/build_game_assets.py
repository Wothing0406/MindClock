"""Build the local portrait arena asset pack from approved prototype sources.

Registration is locked per action to its first frame, then placed on one
512x512 canvas. This script does not prove artistic continuity or IP rights.
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "demo" / "assets" / "game"
SLUGS = ("ha-nhan", "han-boi-phap", "tuyet-dinh")
ACTIONS = ("basic", "skill1", "skill2", "victory")
STATES = ("hurt", "stun", "heal")
POSES = ("idle", "basic", "skill1", "skill2", "hurt", "stun")
AVATARS = ("cao-giay", "cu-meo", "rua-xanh", "tho-so", "may-nho", "ca-chep")
RANKS = ("dong", "bac", "vang", "bach-kim", "kim-cuong", "tinh-anh")


def alpha_box(image: Image.Image) -> tuple[int, int, int, int]:
    box = image.getchannel("A").point(lambda a: 255 if a > 12 else 0).getbbox()
    if box is None:
        raise ValueError("Empty alpha frame")
    return box


def matte(tile: Image.Image) -> Image.Image:
    rgb = np.array(tile.convert("RGB"))
    if tile.getchannel("A").getextrema()[0] < 250:
        return tile
    border = np.concatenate([
        rgb[:8].reshape(-1, 3), rgb[-8:].reshape(-1, 3),
        rgb[:, :8].reshape(-1, 3), rgb[:, -8:].reshape(-1, 3),
    ])
    bg = np.median(border, axis=0)
    candidate = (
        np.max(np.abs(rgb.astype(np.int16) - bg.astype(np.int16)), axis=2) < 29
    ).astype(np.uint8)
    _, labels, stats, _ = cv2.connectedComponentsWithStats(candidate, 8)
    edges = np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1]))
    large_neutral = [
        label for label in np.flatnonzero(stats[:, cv2.CC_STAT_AREA] > 5000)
        if label and np.max(np.abs(np.mean(rgb[labels == label], axis=0) - bg)) <= 8
    ]
    background = np.isin(labels, np.union1d(np.unique(edges[edges != 0]), large_neutral))
    alpha = cv2.GaussianBlur(
        np.where(background, 0, 255).astype(np.uint8), (3, 3), 0.45
    )
    return Image.fromarray(np.dstack((rgb, alpha)), "RGBA")


def tiles(sheet: Image.Image) -> list[Image.Image]:
    if sheet.size != (1536, 1024):
        raise ValueError(f"Expected 1536x1024, got {sheet.size}")
    return [
        sheet.crop((index % 3 * 512, index // 3 * 512,
                    (index % 3 + 1) * 512, (index // 3 + 1) * 512))
        for index in range(6)
    ]


def register(frames: list[Image.Image], target_height: int = 400) -> list[Image.Image]:
    base = alpha_box(frames[0])
    height, width = base[3] - base[1], base[2] - base[0]
    scale = min(target_height / height, 450 / width)
    anchor_x = (base[0] + base[2]) / 2
    anchor_y = base[3]
    output = []
    for frame in frames:
        new_size = (round(frame.width * scale), round(frame.height * scale))
        scaled = frame.resize(new_size, Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (512, 512))
        x, y = round(256 - anchor_x * scale), round(478 - anchor_y * scale)
        canvas.paste(scaled, (x, y))
        output.append(canvas)
    return output


def save_animation(directory: Path, action: str, frames: list[Image.Image], durations: list[int]) -> dict:
    directory.mkdir(parents=True, exist_ok=True)
    frame_dir = directory / "frames" / action
    frame_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(frames):
        frame.save(frame_dir / f"f{index:02d}.webp", "WEBP", quality=84, method=3)
    frames[0].save(
        directory / f"{action}.webp", "WEBP", save_all=True,
        append_images=frames[1:], duration=durations, loop=1,
        quality=82, method=3, disposal=2, blend=0,
    )
    return {
        "clip": f"{action}.webp",
        "frames": [f"frames/{action}/f{i:02d}.webp" for i in range(len(frames))],
        "durations_ms": durations,
        "root_px": [256, 478],
        "canvas_px": [512, 512],
    }


def build_character(slug: str) -> dict:
    folder = ROOT / "characters" / slug
    source = folder / "source"
    runtime = folder / "runtime"
    runtime.mkdir(parents=True, exist_ok=True)
    master = Image.open(source / "master.png").convert("RGBA")
    idle = register([master])[0]
    idle.save(runtime / "idle.webp", "WEBP", quality=86, method=3)
    result = {"idle": "idle.webp", "actions": {}, "native_facing": "right" if slug == "ha-nhan" else "left", "display_height_px": 400}
    for action in ACTIONS:
        frames = register([matte(t) for t in tiles(Image.open(source / f"{action}.png").convert("RGBA"))])
        result["actions"][action] = save_animation(
            runtime, action, frames, [125, 95, 95, 145, 115, 165]
        )
    state_tiles = [matte(t) for t in tiles(Image.open(source / "states.png").convert("RGBA"))]
    for index, state in enumerate(STATES):
        pair = register([state_tiles[index], state_tiles[index + 3]])
        result["actions"][state] = save_animation(
            runtime, state, [pair[0], pair[1], pair[0], pair[1]], [140] * 4
        )
    pose_dir = folder / "poses"
    pose_dir.mkdir(exist_ok=True)
    for pose, tile in zip(POSES, tiles(Image.open(source / "poses.png").convert("RGBA"))):
        tile.thumbnail((384, 384), Image.Resampling.LANCZOS)
        tile.save(pose_dir / f"{pose}.webp", "WEBP", quality=80, method=3)
    return result


def build_ui() -> None:
    map_source = ROOT / "maps" / "source" / "study-courtyard.png"
    map_image = Image.open(map_source).convert("RGB")
    map_image.thumbnail((900, 1600), Image.Resampling.LANCZOS)
    map_image.save(ROOT / "maps" / "study-courtyard.webp", "WEBP", quality=79, method=4)
    avatar_sheet = Image.open(ROOT / "ui/avatars/source/default-avatars.png").convert("RGBA")
    for name, tile in zip(AVATARS, tiles(avatar_sheet)):
        tile = tile.resize((256, 256), Image.Resampling.LANCZOS)
        mask = Image.new("L", (256, 256))
        ImageDraw.Draw(mask).ellipse((3, 3, 253, 253), fill=255)
        tile.putalpha(mask)
        tile.save(ROOT / "ui/avatars" / f"{name}.webp", "WEBP", quality=83, method=3)


def main() -> None:
    characters = {slug: build_character(slug) for slug in SLUGS}
    effects = {name: f"effects/runtime/{name}.svg" for name in ("impact", "healing", "stun")}
    build_ui()
    manifest = {
        "schema": "mindclock.game-assets.v1",
        "status": "research_demo_only",
        "art_source": "host_image",
        "reference_rights": "owner confirmed public GitHub publication on 2026-11-12; commercial rights not assessed; originals absent",
        "logical_stage_px": [360, 380],
        "actor_root_px": {"left": [92, 350], "right": [268, 350]},
        "display_actor_size_px": [240, 240],
        "map": "maps/study-courtyard.webp",
        "characters": characters,
        "effects": effects,
        "avatars": [f"ui/avatars/{name}.webp" for name in AVATARS],
        "rank_frames": [f"ui/rank/{name}.svg" for name in RANKS],
        "rank_badges": [f"ui/rank/badges/{name}.svg" for name in RANKS],
    }
    (ROOT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("Built game sprites for 3 characters and 6 avatars; run build_game_projectiles.py for FX")


if __name__ == "__main__":
    main()
