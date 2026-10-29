"""Extract generated atlas cells, align feet, and export a documented sprite pack.

Artwork is created/edited with image_gen; this script only slices, uniformly
scales, aligns, and packages the finished art. Originals remain untouched.
"""
from pathlib import Path
from PIL import Image
import base64
import json
import zipfile
import numpy as np
from scipy import ndimage

ROOT = Path(__file__).parent
SIZE = 128
STATES = ['idle', 'windup', 'release', 'recovery', 'walk_a', 'walk_b', 'hurt', 'defeated']
FRAME_COUNT = len(STATES)
ROSTER = [
    ('warrior', 'The Warrior'), ('itchy_finger', 'The Itchy Finger'),
    ('repentant', 'The Repentant'), ('cohabitants', 'The Cohabitants'),
    ('cogitator', 'The Cogitator'), ('embedded', 'The Embedded'),
    ('shade', 'The Shade'), ('shieldbearer', 'The Shieldbearer'),
    ('spendthrift', 'The Spendthrift'), ('juggler', 'The Juggler'),
    ('empty_nester', 'The Empty Nester'), ('flagellant', 'The Flagellant'),
    ('makeshift_sisyphus', 'The Makeshift Sisyphus'), ('physicist', 'The Physicist'),
    ('tactician', 'The Tactician'), ('radical', 'The Radical'),
    ('falconer', 'The Falconer'), ('carouser', 'The Carouser'),
    ('tunneller', 'The Tunneller'), ('tiptoer', 'The Tiptoer'),
    ('hoary_hoarder', 'The Hoary Hoarder'), ('ballbearer', 'The Ballbearer'),
    ('false_messiah', 'The False Messiah'),
]


def source_cells(image, batch):
    """Isolate complete figures, retaining their original RGB and alpha.

    Main alpha components are separated at alpha=64, or 128/192 if needed,
    so faint adjacent glows do not join characters. Fainter pixels and detached sparks are assigned to
    the nearest main figure. No pixels are painted or anatomy synthesized.
    This avoids chopping off limbs when artwork exceeds its nominal cell.
    """
    alpha = np.asarray(image.getchannel('A'))
    expected = 12 if batch == 6 else 16
    for threshold in [64, 128, 192]:
        labels, _ = ndimage.label(alpha >= threshold)
        sizes = np.bincount(labels.ravel())
        sizes[0] = 0
        primary = np.flatnonzero(sizes > 2000)
        if len(primary) == expected:
            break
    if len(primary) != expected:
        raise ValueError(f'batch {batch}: expected {expected} complete figures, found {len(primary)}')
    primary_mask = np.isin(labels, primary)
    _, nearest = ndimage.distance_transform_edt(~primary_mask, return_indices=True)
    assignments = labels[tuple(nearest)]
    objects = ndimage.find_objects(labels)
    w, h = image.size
    result = {}
    for component in primary:
        y, x = objects[component-1]
        row = int(((y.start+y.stop)/2) // (h/4))
        col = int(((x.start+x.stop)/2) // (w/4))
        if (row, col) in result:
            raise ValueError(f'batch {batch}: multiple bodies in cell {row,col}')
        selected_alpha = np.where(assignments == component, alpha, 0).astype('uint8')
        separated = image.copy()
        separated.putalpha(Image.fromarray(selected_alpha))
        bounds = Image.fromarray(selected_alpha).point(lambda a: 255 if a >= 12 else 0).getbbox()
        if not bounds:
            raise ValueError(f'batch {batch}: empty frame')
        x0, y0, x1, y1 = bounds
        if x0 < 1 or y0 < 1 or x1 > w-1 or y1 > h-1:
            raise ValueError(f'batch {batch}/{row,col}: sprite reaches canvas edge')
        result[(row,col)] = (separated.crop(bounds), bounds)
    return result


def build():
    manifest = {'version': 2, 'art_style': 'Ronke-inspired cel-shaded gorillas',
                'frame_size': {'w': SIZE, 'h': SIZE},
                'anchor_px': {'x': 64, 'y': 120},
                'facing': 'three-quarter right',
                'animations': {'idle': {'frames': [0], 'loop': True},
                               'throw': {'frames': [1, 2, 3, 0], 'fps': 8, 'loop': False},
                               'walk': {'frames': [4, 5], 'fps': 6, 'loop': True},
                               'hurt': {'frames': [6, 0], 'fps': 5, 'loop': False},
                               'defeat': {'frames': [6, 7], 'fps': 5, 'loop': False, 'hold_last': True}},
                'release_event_frame': 2, 'characters': [],
                'limitations': ['One facing direction; walking uses two contact poses.',
                                'Concept-derived animation poses; review timing in the game.',
                                'Projectiles should be spawned separately on release.']}
    master = Image.new('RGBA', (SIZE * FRAME_COUNT, SIZE * len(ROSTER)))
    sources = {}
    for batch in range(1, 7):
        for prefix in ['batch', 'motion']:
            source_path = ROOT / 'source' / f'{prefix}_{batch:02}.png'
            with Image.open(source_path) as original:
                image = original.convert('RGBA')
            if image.getchannel('A').getextrema()[0] == 255:
                raise ValueError(f'{source_path}: background is opaque; repair with image_gen')
            sources[(prefix,batch)] = source_cells(image, batch)
    for index, (slug, name) in enumerate(ROSTER):
        batch, row = index // 4 + 1, index % 4
        frames = []
        source_rects = []
        for prefix in ['batch', 'motion']:
            cells = sources[(prefix,batch)]
            for col in range(4):
                frame, bounds = cells[(row,col)]
                frames.append(frame)
                source_rects.append({'file': f'source/{prefix}_{batch:02}.png', 'bounds': list(bounds), 'extraction': 'alpha-component isolation'})
        foot_centers = []
        for frame in frames:
            feet = frame.getchannel('A').crop((0, round(frame.height*.91), frame.width, frame.height))
            feet_box = feet.point(lambda a: 255 if a >= 128 else 0).getbbox()
            foot_centers.append((feet_box[0]+feet_box[2])/2 if feet_box else frame.width/2)
        scale = min(112 / max(f.height for f in frames),
                    56 / max(foot_centers),
                    56 / max(f.width-x for f,x in zip(frames,foot_centers)))
        strip = Image.new('RGBA', (FRAME_COUNT*SIZE, SIZE))
        outdir = ROOT / 'characters' / slug
        outdir.mkdir(parents=True, exist_ok=True)
        framedata = []
        for col, frame in enumerate(frames):
            frame = frame.resize((max(1, round(frame.width*scale)), max(1, round(frame.height*scale))), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', (SIZE, SIZE))
            canvas.alpha_composite(frame, (round(64-foot_centers[col]*scale), 120-frame.height))
            canvas.save(outdir / f'{STATES[col]}.png')
            strip.alpha_composite(canvas, (col*SIZE, 0))
            framedata.append({'name': STATES[col], 'frame': {'x': col*SIZE, 'y': 0, 'w': SIZE, 'h': SIZE}})
        strip.save(outdir / 'sprites.png')
        master.alpha_composite(strip, (0, index*SIZE))
        entry = {'id': slug, 'name': name, 'texture': f'characters/{slug}/sprites.png',
                 'master_row': index, 'frames': framedata,
                 'sources': [f'source/batch_{batch:02}.png', f'source/motion_{batch:02}.png'], 'source_rects': source_rects}
        (outdir / 'sprites.json').write_text(json.dumps({**manifest, 'characters': [entry]}, indent=2))
        manifest['characters'].append(entry)
    master.save(ROOT / 'roster-atlas.png')
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    # Embed the atlas so preview.html works directly from disk without fetch/CORS.
    template = (ROOT / 'preview-template.html').read_text()
    template = template.replace('__ATLAS_DATA__', base64.b64encode((ROOT / 'roster-atlas.png').read_bytes()).decode())
    template = template.replace('__ROSTER_JSON__', json.dumps([{'id': s, 'name': n} for s,n in ROSTER]))
    (ROOT / 'preview.html').write_text(template)
    # A compact static proof sheet is useful for manual final anatomy checks.
    proof = Image.new('RGB', (FRAME_COUNT*SIZE, len(ROSTER)*SIZE), '#28313e')
    proof.paste(master, mask=master.getchannel('A'))
    proof.save(ROOT / 'contact-sheet.png')
    validate(manifest)
    zip_path = ROOT.parent / 'gorilla-sprites.zip'
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(ROOT.rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts:
                archive.write(path, Path('gorilla-sprites') / path.relative_to(ROOT))
    print(json.dumps({'characters': len(ROSTER), 'frames': FRAME_COUNT*len(ROSTER), 'atlas': list(master.size), 'zip': str(zip_path)}, indent=2))


def validate(manifest):
    assert len(manifest['characters']) == 23
    assert len({c['id'] for c in manifest['characters']}) == 23
    assert manifest['version'] == 2
    for animation in manifest['animations'].values():
        assert all(0 <= frame < FRAME_COUNT for frame in animation['frames'])
    assert manifest['animations']['defeat']['hold_last'] is True
    for character in manifest['characters']:
        assert len(character['frames']) == FRAME_COUNT
        assert [f['name'] for f in character['frames']] == STATES
        with Image.open(ROOT / character['texture']) as strip:
            assert strip.size == (FRAME_COUNT*SIZE, SIZE)
    for slug, _ in ROSTER:
        for state in STATES:
            with Image.open(ROOT / 'characters' / slug / f'{state}.png') as im:
                assert im.size == (128, 128) and im.mode == 'RGBA'
                alpha = im.getchannel('A')
                assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] > 0
                box = alpha.getbbox()
                assert box and box[0] >= 0 and box[1] >= 0 and box[2] <= 128 and box[3] <= 121
        a = np.asarray(Image.open(ROOT / 'characters' / slug / 'walk_a.png'))
        b = np.asarray(Image.open(ROOT / 'characters' / slug / 'walk_b.png'))
        assert np.any(a != b), f'{slug}: walking poses must be distinct'
    print(f'PASS: 23 characters, {FRAME_COUNT*len(ROSTER)} nonempty transparent frames, valid sizes and anchors.')


if __name__ == '__main__':
    build()
