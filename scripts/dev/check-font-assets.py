#!/usr/bin/env python3
"""Verify bundled Inter files and packaged notices using the Python stdlib."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'source_files/qt_frontend/assets/fonts'
NOTICES = ROOT / 'docs/artwork/fonts'
FILES = {
    'Inter-Regular.ttf': 400,
    'Inter-Medium.ttf': 500,
    'Inter-SemiBold.ttf': 600,
    'InterDisplay-SemiBold.ttf': 600,
}
SOURCE = 'https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip'
ARCHIVE_SHA256 = '9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e'
OFL_SHA256 = '262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def checked_file(directory, name):
    path = directory / name
    require(path.name == name and not path.is_symlink()
            and path.resolve().parent == directory.resolve(), 'Unsafe font asset path: ' + name)
    return path.read_bytes()


def verify():
    raw_manifest = checked_file(ASSETS, 'manifest.json')
    manifest = json.loads(raw_manifest)
    require(manifest['format'] == 1 and manifest['project'] == 'Inter'
            and manifest['version'] == '4.1' and manifest['source'] == SOURCE
            and manifest['archive_sha256'] == ARCHIVE_SHA256, 'Unexpected Inter source identity')
    require(manifest['license'] == 'SIL Open Font License 1.1'
            and manifest['license_sha256'] == OFL_SHA256, 'Unexpected Inter license identity')
    fonts = manifest['fonts']
    require(len(fonts) == len(FILES) and {font['file'] for font in fonts} == set(FILES),
            'Expected exactly the four approved static Inter faces')
    require({path.name for path in ASSETS.iterdir()} == set(FILES) | {'manifest.json', 'OFL.txt'},
            'Uncatalogued font asset file')
    for font in fonts:
        name = font['file']
        require(font['upstream_path'] == 'extras/ttf/' + name
                and font['weight'] == FILES[name] and font['variable'] is False
                and font['cyrillic_ru'] is True, 'Unexpected font metadata: ' + name)
        data = checked_file(ASSETS, name)
        require(len(data) == font['bytes'], 'Font size mismatch: ' + name)
        require(hashlib.sha256(data).hexdigest() == font['sha256'], 'Font checksum mismatch: ' + name)
    license_data = checked_file(ASSETS, 'OFL.txt')
    require(hashlib.sha256(license_data).hexdigest() == OFL_SHA256, 'OFL checksum mismatch')
    require(checked_file(NOTICES, 'INTER-OFL.txt') == license_data,
            'Packaged Inter OFL differs from the source notice')
    require(checked_file(NOTICES, 'inter-manifest.json') == raw_manifest,
            'Packaged Inter manifest differs from the source manifest')
    print('4 Inter faces: source identity, file sizes, SHA-256 and packaged OFL/manifest verified.')


if __name__ == '__main__':
    verify()
