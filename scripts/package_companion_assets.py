"""Package image_gen illustrations already sliced by the sprite skill.

No drawing/regeneration: resize/export approved UI tiles, preserve alpha,
write provenance/QC, and make review contact sheets and mouth/blink previews.
Run the processing commands in assets/companions/README.md first.
"""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/companions'
APP = ROOT / 'app/assets/companions'
REVIEW = ART / 'review'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def scaled(image, size):
    # Premultiplied resampling avoids black/white fringes from alpha-zero RGB.
    return image.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')


def export(source, name, group):
    image = Image.open(source).convert('RGBA')
    assert image.size == (512, 512), (source, image.size)
    alpha = image.getchannel('A')
    assert alpha.getextrema() == (0, 255), f'Not real alpha: {source}'
    box = alpha.getbbox()
    assert box and box[0] > 0 and box[1] > 0 and box[2] < 512 and box[3] < 512, f'Clipped: {source}'
    dest = ART / group / 'runtime' / f'{name}.webp'
    dest.parent.mkdir(parents=True, exist_ok=True)
    runtime = scaled(image, (256, 256))
    runtime.save(dest, lossless=True, method=6)
    app = APP / group / dest.name
    app.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(dest, app)
    return {'id': name, 'file': dest.relative_to(ART).as_posix(),
        'appFile': app.relative_to(ROOT / 'app').as_posix(),
        'sha256': sha(dest), 'bytes': dest.stat().st_size,
        'canvas': [256, 256], 'alpha': True,
        'normalizedSourceBbox': list(box), 'kind': 'static_ui_illustration'}


def contact(items, filename, columns):
    tile, caption = 256, 34
    rows = (len(items) + columns - 1) // columns
    sheet = Image.new('RGB', (columns * tile, rows * (tile + caption)), '#F7F7F2')
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 16)
    except OSError:
        font = ImageFont.load_default()
    for i, item in enumerate(items):
        x, y = (i % columns) * tile, (i // columns) * (tile + caption)
        color = '#101A30' if i % 2 else '#F7F7F2'
        draw.rectangle((x, y, x + tile, y + tile), fill=color)
        image = Image.open(ART / item['file']).convert('RGBA')
        sheet.paste(image, (x, y), image)
        draw.text((x + 8, y + tile + 5), item['id'], fill='#1B2741', font=font)
    sheet.save(REVIEW / filename)


def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    ai_names = ['neutral', 'blink', 'listening', 'thinking', 'encouraging',
        'focused', 'speaking-small', 'speaking-medium', 'speaking-wide']
    ai = [export(ART / f'mindclock-ai/processed/expressions/sheet-{i + 1}.png', name, 'mindclock-ai')
        for i, name in enumerate(ai_names)]
    stages = [export(ART / f'pet-mam/processed/stages/evolution-{i}.png', f'stage-{i}', 'pet-mam')
        for i in range(1, 5)]
    reactions = [export(ART / f'pet-mam/processed/reactions-v2/sheet-{i + 1}.png', name, 'pet-mam')
        for i, name in enumerate(['idle', 'happy', 'sleep', 'snack', 'reading', 'celebrate'])]
    background = Image.open(ART / 'environment/source/study-corner.png').convert('RGB')
    background.thumbnail((960, 640), Image.Resampling.LANCZOS)
    dest = ART / 'environment/runtime/study-corner.webp'
    dest.parent.mkdir(parents=True, exist_ok=True)
    background.save(dest, quality=90, method=6)
    APP.mkdir(parents=True, exist_ok=True)
    shutil.copy2(dest, APP / 'study-corner.webp')
    sources = [{ 'file': path.relative_to(ART).as_posix(), 'sha256': sha(path),
        'size': list(Image.open(path).size)}
        for path in ART.glob('*/source/*.png')]
    qa_warnings = []
    pipeline_reports = {}
    for group, directory in [('mindclock-ai', 'expressions'), ('pet-mam', 'stages'), ('pet-mam', 'reactions-v2')]:
        source = ART / group / 'processed' / directory / 'pipeline-meta.json'
        qa = ART / group / 'qa' / f'{directory}-pipeline.json'
        qa.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, qa)
        pipeline_reports[f'{group}/{directory}'] = json.loads(source.read_text(encoding='utf-8'))['qa']
    for report in sorted((ROOT / 'tasks/T070-pet-and-ai-avatar-assets/qa').glob('*/sheet-qc.json')):
        data = json.loads(report.read_text(encoding='utf-8'))
        for check in data.get('checks', []):
            if check.get('status') in ['warn', 'fail']:
                qa_warnings.append({'file': report.relative_to(ROOT).as_posix(), **check})
    manifest = {'schema': 'mindclock.companions.v1', 'artSource': 'host_image',
        'route': 'image_gen builtin', 'model': 'not exposed by tool', 'costUsd': None,
        'sourceReview': 'assistant visual selection; user feedback pending',
        'rights': 'original generated designs; no third-party character references',
        'sources': sources, 'ai': ai, 'petStages': stages, 'petReactions': reactions,
        'canvasConvention': '256x256; display whole canvas, bottom-center registration from sprite pipeline; no per-frame BoxFit.cover',
        'pipelineQa': {name: report['status'] for name, report in pipeline_reports.items()},
        'background': {'file': dest.relative_to(ART).as_posix(), 'sha256': sha(dest)},
        'aiStateMap': {'idle': ['neutral', 'blink'], 'listening': ['listening'],
            'thinking': ['thinking'], 'encouraging': ['encouraging'], 'focused': ['focused'],
            'speaking': ['speaking-small', 'speaking-medium', 'speaking-wide']},
        'motionLimits': ['UI expression switching only; no full-body animation video',
            'Speaking is gated by actual caller audio playback state, not chat history',
            'Generic mouth cadence is not phoneme-accurate lip sync',
            'Pet reaction tiles are static poses, not feed/walk animation cycles'],
        'rawSourceWarnings': qa_warnings}
    (ART / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    qa_lines = ['# Companion image QA', '',
        'Runtime structural QA passes for the selected tiles. Raw generation reports contain warnings; do not call all source checks clean.', '',
        'Rejected reactions-rejected-v1.png is not used by runtime; corrected reactions-v2.png is used.', '',
        '| Report | Check | Status | Value | Threshold |', '| --- | --- | --- | --- | --- |']
    for item in qa_warnings:
        qa_lines.append('| ' + ' | '.join([item['file'], item['id'], item['status'],
            json.dumps(item['value'], ensure_ascii=False), json.dumps(item['threshold'])]) + ' |')
    qa_lines += ['', 'Raw faint-speck alpha hygiene, cell resampling, registration and downscale are recorded in the pipeline metadata.',
        'Visual review: selected portraits and pet stages inspected on light/dark backgrounds; no missing limbs or clipped ears observed.',
        'UI expression switching is not full-body animation or phoneme-accurate speech. Character motion videos remain unavailable.', '']
    (ART / 'qa-report.md').write_text('\n'.join(qa_lines), encoding='utf-8')
    contact(ai, 'ai-expressions.png', 3)
    contact(stages + reactions, 'pet-collection.png', 4)
    clips = {'speaking-preview.webp': (['neutral', 'speaking-small', 'speaking-medium',
        'speaking-wide', 'speaking-medium', 'speaking-small'], [180, 140, 140, 140, 140, 140]),
        'blink-preview.webp': (['neutral', 'blink', 'neutral'], [1800, 120, 1800])}
    for name, (sequence, durations) in clips.items():
        frames = [Image.open(ART / f'mindclock-ai/runtime/{state}.webp').convert('RGBA') for state in sequence]
        frames[0].save(REVIEW / name, save_all=True, append_images=frames[1:], duration=durations,
            loop=0, lossless=True, method=6)
    archive_path = ROOT / 'dist/mindclock-companions-v1.zip'
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(ART.rglob('*')):
            if path.is_file() and 'processed' not in path.parts:
                archive.write(path, path.relative_to(ROOT))
    print(json.dumps({'runtimeTiles': len(ai) + len(stages) + len(reactions),
        'runtimeBytes': sum(item['bytes'] for item in ai + stages + reactions) + dest.stat().st_size,
        'manifest': str(ART / 'manifest.json'), 'archive': str(archive_path), 'rawWarnings': len(qa_warnings)}))


if __name__ == '__main__':
    main()
