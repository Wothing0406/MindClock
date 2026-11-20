"""Verify the shipped companion assets, without generating or modifying images."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/companions'
manifest = json.loads((ART / 'manifest.json').read_text(encoding='utf-8'))
items = manifest['ai'] + manifest['petStages'] + manifest['petReactions']
assert len(items) == 19
for item in items:
    path = ART / item['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['sha256'], path
    app = ROOT / 'app' / item['appFile']
    assert app.read_bytes() == path.read_bytes(), app
    with Image.open(path) as image:
        assert image.size == (256, 256), path
        assert image.mode == 'RGBA', path
        assert image.getchannel('A').getextrema() == (0, 255), path
        box = image.getchannel('A').getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < 256 and box[3] < 256, path
assert len({item['sha256'] for item in manifest['ai']}) == 9
for source in manifest['sources']:
    assert hashlib.sha256((ART / source['file']).read_bytes()).hexdigest() == source['sha256']
for filename, count in [('speaking-preview.webp', 6), ('blink-preview.webp', 3)]:
    with Image.open(ART / 'review' / filename) as image:
        assert image.n_frames == count, (filename, image.n_frames)
assert all(status == 'pass' for status in manifest['pipelineQa'].values())
print('PASS: 19 shipped 256px RGBA tiles, hashes, alpha borders, preview frame counts and app copies')
print(f'Raw source findings retained: {len(manifest["rawSourceWarnings"])} (including rejected v1); see assets/companions/qa-report.md')
