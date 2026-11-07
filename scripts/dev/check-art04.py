#!/usr/bin/env python3
"""Capture actual sidebar icon ART-04 QML A/B states, without touching historical captures.

Activate the local Qt toolchain first if required. Requires a freshly built
qt-core-tests (the runner builds it) and Xvfb. Artifacts default to a new unique
build/art04 directory. No app debug API or persistent preference is introduced.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
from xvfb_session import XvfbSession

ROOT = Path(__file__).resolve().parents[2]

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT).decode().strip()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--baseline-dir', type=Path, help='Accepted ART03 captures directory, for unchanged A sidebar pixel proof')
    args = parser.parse_args()
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    out = args.out or ROOT / 'build/art04' / f'{git("rev-parse", "--short", "HEAD")}-{stamp}'
    out = out.resolve()
    out.mkdir(parents=True, exist_ok=False)  # never replace prior evidence
    with (out / 'build.log').open('w') as log:
        subprocess.run(['cmake', '--build', 'build/qt', '-j2'], cwd=ROOT,
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    source_paths = ['source_files/qt_frontend/prototype/PreviewIcon.qml',
                    'source_files/qt_frontend/prototype/Preview.qml',
                    'source_files/qt_frontend/tests/test_core.cpp',
                    'scripts/dev/check-art04.py']
    manifest = dict(capturedAt=datetime.now(timezone.utc).isoformat(),
                    sourceCommit=git('rev-parse', 'HEAD'), sourceTree=git('rev-parse', 'HEAD^{tree}'),
                    gitStatus=git('status', '--porcelain'),
                    sourceSha256={p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in source_paths},
                    captureSource='QtTest actual Preview.qml, QQuickWindow.grabWindow; asserted states',
                    renderer='software', platform='Xvfb/xcb', runs=[])
    diff = subprocess.check_output(['git', 'diff', '--binary', 'HEAD'], cwd=ROOT)
    (out / 'working-tree.patch').write_bytes(diff)
    manifest['workingTreePatchSha256'] = hashlib.sha256(diff).hexdigest()
    test = ROOT / 'build/qt/source_files/qt_frontend/qt-core-tests'
    manifest['appBinarySha256'] = hashlib.sha256((ROOT / 'build/qt/source_files/qt_frontend/obsidian').read_bytes()).hexdigest()
    manifest['testBinarySha256'] = hashlib.sha256(test.read_bytes()).hexdigest()
    with XvfbSession(out / 'xvfb.log', '3200x2200x24') as display:
        for scale in (1, 1.5):
            for theme in ['light', 'dark']:
                name = f'{theme}-paired-dpr{scale}'
                dest = out / name
                dest.mkdir()
                env = display.env.copy()
                env.update(QT_QUICK_BACKEND='software', QT_QPA_PLATFORM='xcb',
                           QT_SCALE_FACTOR=str(scale),
                           OBSIDIAN_TEST_ENGINE=str(ROOT / 'build/qt/obsidian-engine'),
                           OBSIDIAN_TEST_DATA=str(ROOT), OBSIDIAN_CAPTURE_MODE=theme,
                           OBSIDIAN_CAPTURE_DIR=str(dest),
                           OBSIDIAN_ART04_CORE_ONLY='1' if scale != 1 else '0')
                if args.baseline_dir and scale == 1:
                    baseline = args.baseline_dir.resolve() / f'{theme}-paired-dpr1/normal-original.png'
                    env['OBSIDIAN_ART04_BASELINE_IMAGE'] = str(baseline)
                    manifest.setdefault('acceptedBaselineSha256', {})[str(baseline)] = hashlib.sha256(baseline.read_bytes()).hexdigest()
                with (dest / 'test.log').open('w') as log:
                    result = subprocess.run([str(test), 'previewArt04Capture'], cwd=ROOT,
                                            env=env, stdout=log, stderr=subprocess.STDOUT, timeout=120)
                if result.returncode:
                    raise RuntimeError((dest / 'test.log').read_text())
                states = json.loads((dest / 'states.json').read_text())
                for shot in states:
                    png = dest / shot['file']
                    assert hashlib.sha256(png.read_bytes()).hexdigest() == shot['sha256']
                manifest['runs'].append(dict(name=name, states=states))
                print(f'{name}: {len(states)} asserted screenshots', flush=True)
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(out)

if __name__ == '__main__':
    main()
