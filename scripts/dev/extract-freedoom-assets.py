#!/usr/bin/env python3
"""Extract unscaled transparent pickup sprites from verified Freedoom 0.13.0.

The WAD directory, Doom patch columns and PLAYPAL are decoded with the standard
library. PNG files contain original indexed colors expanded to RGBA; there is
no resizing, retouching, recoloring or invented artwork. --verify needs no IWAD
and no image-library dependencies.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'source_files/qt_frontend/assets/freedoom'
SOURCE_SHA256 = '92e73a81f75a03e29984e293da040928ddafd1cbad26a629489073a46e475347'
PALETTE_SHA256 = 'fd895921b5d0a394612bb29852ed003d44d69f76dec31c0dc6b5d5fc7d63f7bb'
# Stable frontend IDs, exact source lump, category, localized caption and option.
SPRITES = [
    ('clip', 'CLIPA0', 'ammo', 'Патроны', 'ammo'),
    ('ammo_box', 'AMMOA0', 'ammo', 'Ящик патронов', 'ammo'),
    ('shells', 'SHELA0', 'ammo', 'Патроны для дробовика', 'ammo'),
    ('shell_box', 'SBOXA0', 'ammo', 'Коробка патронов', 'ammo'),
    ('rocket', 'ROCKA0', 'ammo', 'Ракета', 'ammo'),
    ('rocket_box', 'BROKA0', 'ammo', 'Ящик ракет', 'ammo'),
    ('cell', 'CELLA0', 'ammo', 'Энергетическая ячейка', 'ammo'),
    ('cell_pack', 'CELPA0', 'ammo', 'Блок ячеек', 'ammo'),
    ('stimpack', 'STIMA0', 'health', 'Малая аптечка', 'health'),
    ('medikit', 'MEDIA0', 'health', 'Большая аптечка', 'health'),
    ('health_bonus', 'BON1A0', 'health', 'Бонус здоровья', 'health'),
    ('green_armor', 'ARM1A0', 'armor', 'Лёгкая броня', 'items'),
    ('blue_armor', 'ARM2A0', 'armor', 'Усиленная броня', 'items'),
    ('armor_bonus', 'BON2A0', 'armor', 'Бонус брони', 'items'),
    ('shotgun', 'SHOTA0', 'weapons', 'Дробовик', 'weapons'),
    ('super_shotgun', 'SGN2A0', 'weapons', 'Двуствольный дробовик', 'weapons'),
    ('chaingun', 'MGUNA0', 'weapons', 'Пулемёт', 'weapons'),
    ('rocket_launcher', 'LAUNA0', 'weapons', 'Ракетное оружие', 'weapons'),
    ('plasma_rifle', 'PLASA0', 'weapons', 'Плазменное оружие', 'weapons'),
    ('bfg', 'BFUGA0', 'weapons', 'Тяжёлое энергооружие', 'weapons'),
    ('chainsaw', 'CSAWA0', 'weapons', 'Бензопила', 'weapons'),
    ('soul_bonus', 'SOULA0', 'bonuses', 'Особая награда', 'secrets_bonus'),
]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


class Wad:
    def __init__(self, data):
        require(len(data) >= 12 and data[:4] in (b'IWAD', b'PWAD'), 'Invalid WAD header')
        count, directory = struct.unpack_from('<II', data, 4)
        require(count <= 100000 and directory >= 12 and directory + count * 16 <= len(data), 'Invalid WAD directory bounds')
        self.data, self.lumps = data, {}
        for index in range(count):
            offset, size, raw = struct.unpack_from('<II8s', data, directory + index * 16)
            require(offset <= len(data) and size <= len(data) - offset, 'Invalid WAD lump bounds')
            name = raw.rstrip(b'\0').decode('ascii')
            self.lumps[name] = (offset, size)

    def lump(self, name):
        require(name in self.lumps, 'Required Freedoom lump is missing: ' + name)
        offset, size = self.lumps[name]
        return self.data[offset:offset + size]


def decode_patch(data, palette):
    require(len(data) >= 8 and len(palette) >= 768, 'Invalid patch header or palette')
    width, height, left, top = struct.unpack_from('<HHhh', data)
    require(0 < width <= 4096 and 0 < height <= 4096 and width * height <= 4_000_000, 'Invalid patch dimensions')
    header = 8 + width * 4
    require(header <= len(data), 'Truncated patch column table')
    rgba = bytearray(width * height * 4)
    for x in range(width):
        cursor = struct.unpack_from('<I', data, 8 + x * 4)[0]
        require(header <= cursor < len(data), 'Invalid patch column pointer')
        previous_top, terminated = -1, False
        while cursor < len(data):
            delta = data[cursor]
            if delta == 255:
                terminated = True
                break
            require(cursor + 4 <= len(data), 'Truncated patch post')
            length = data[cursor + 1]
            require(cursor + length + 4 <= len(data), 'Truncated patch pixel data')
            # Tall-patch extension: a nonincreasing delta is relative to the last post.
            y = delta + previous_top if delta <= previous_top else delta
            require(0 <= y <= height and length <= height - y, 'Patch post outside image bounds')
            previous_top = y
            for row, color in enumerate(data[cursor + 3:cursor + 3 + length]):
                output = ((y + row) * width + x) * 4
                rgba[output:output + 4] = palette[color * 3:color * 3 + 3] + b'\xff'
            cursor += length + 4
        require(terminated, 'Unterminated patch column')
    return width, height, left, top, bytes(rgba)


def chunk(kind, payload):
    return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)


def encode_png(width, height, rgba):
    stride = width * 4
    scanlines = b''.join(b'\0' + rgba[y * stride:(y + 1) * stride] for y in range(height))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(scanlines, 9)) + chunk(b'IEND', b''))


def read_generated_png(data):
    require(data[:8] == b'\x89PNG\r\n\x1a\n', 'Invalid PNG signature')
    cursor, dimensions, compressed, ended = 8, None, bytearray(), False
    while cursor < len(data):
        require(cursor + 12 <= len(data), 'Truncated PNG chunk')
        length = struct.unpack_from('>I', data, cursor)[0]
        require(length <= len(data) - cursor - 12, 'Invalid PNG chunk size')
        kind, payload = data[cursor + 4:cursor + 8], data[cursor + 8:cursor + 8 + length]
        checksum = struct.unpack_from('>I', data, cursor + 8 + length)[0]
        require(zlib.crc32(kind + payload) & 0xffffffff == checksum, 'Invalid PNG CRC')
        if kind == b'IHDR':
            require(length == 13, 'Invalid PNG IHDR')
            width, height, depth, color, compression, filtering, interlace = struct.unpack('>IIBBBBB', payload)
            require(0 < width <= 4096 and 0 < height <= 4096 and width * height <= 4_000_000, 'Invalid PNG dimensions')
            require((depth, color, compression, filtering, interlace) == (8, 6, 0, 0, 0), 'Expected generated RGBA8 PNG')
            dimensions = (width, height)
        elif kind == b'IDAT':
            compressed += payload
        elif kind == b'IEND':
            require(not payload, 'Invalid PNG IEND')
            ended = True
        cursor += length + 12
        if ended:
            break
    require(ended and cursor == len(data) and dimensions, 'Incomplete PNG')
    width, height = dimensions
    expected = height * (width * 4 + 1)
    decoder = zlib.decompressobj()
    raw = decoder.decompress(bytes(compressed), expected + 1)
    require(len(raw) == expected and decoder.eof and not decoder.unused_data, 'Invalid PNG pixel stream')
    stride = width * 4 + 1
    require(all(raw[y * stride] == 0 for y in range(height)), 'Expected unfiltered source PNG')
    rgba = b''.join(raw[y * stride + 1:(y + 1) * stride] for y in range(height))
    return width, height, rgba


def verify(directory):
    manifest = json.loads((directory / 'manifest.json').read_text())
    require(manifest['format'] == 1 and manifest['source']['sha256'] == SOURCE_SHA256, 'Unexpected source manifest')
    require(manifest['source']['version'] == '0.13.0' and manifest['source']['palette'] == 'PLAYPAL:0' and manifest['source']['palette_sha256'] == PALETTE_SHA256, 'Unexpected source palette/version')
    require([(a['id'], a['lump'], a['group'], a['caption'], a['option']) for a in manifest['assets']] == SPRITES, 'Unexpected pickup catalog')
    expected_files = {'manifest.json'}
    for asset in manifest['assets']:
        filename = asset['id'] + '.png'
        require(asset['file'] == filename, 'Invalid asset filename')
        expected_files.add(filename)
        data = (directory / filename).read_bytes()
        require(sha(data) == asset['png_sha256'], 'PNG checksum mismatch: ' + filename)
        width, height, rgba = read_generated_png(data)
        require([width, height] == asset['dimensions'], 'PNG dimensions mismatch: ' + filename)
        require(sha(rgba) == asset['rgba_sha256'], 'Pixel checksum mismatch: ' + filename)
        alpha = rgba[3::4]
        require(set(alpha) <= {0, 255} and 0 in alpha and 255 in alpha, 'Expected genuine transparent patch pixels')
        require(sum(a == 255 for a in alpha) == asset['opaque_pixels'], 'Opaque pixel mismatch')
    require({p.name for p in directory.iterdir() if p.is_file()} == expected_files, 'Uncatalogued asset file')
    print(f'{len(SPRITES)} Freedoom pickup PNGs: source identity, palette provenance, RGBA, transparency, CRC and SHA-256 verified.')


def extract(iwad, directory):
    data = iwad.read_bytes()
    require(sha(data) == SOURCE_SHA256, 'Expected exact Freedoom Phase 2 0.13.0 IWAD; refusing another game/version')
    wad = Wad(data)
    palette = wad.lump('PLAYPAL')[:768]
    directory.mkdir(parents=True, exist_ok=True)
    assets = []
    for id_, lump_name, group, caption, option in SPRITES:
        patch = wad.lump(lump_name)
        width, height, left, top, rgba = decode_patch(patch, palette)
        png = encode_png(width, height, rgba)
        filename = id_ + '.png'
        (directory / filename).write_bytes(png)
        assets.append({'id': id_, 'file': filename, 'lump': lump_name, 'group': group, 'caption': caption,
                       'option': option, 'dimensions': [width, height], 'patch_offsets': [left, top],
                       'lump_sha256': sha(patch), 'rgba_sha256': sha(rgba), 'png_sha256': sha(png),
                       'opaque_pixels': sum(a == 255 for a in rgba[3::4])})
    manifest = {'format': 1, 'source': {'project': 'Freedoom', 'edition': 'Phase 2', 'version': '0.13.0',
                'filename': 'freedoom2.wad', 'sha256': sha(data), 'palette': 'PLAYPAL:0',
                'palette_sha256': sha(palette), 'url': 'https://github.com/freedoom/freedoom/releases/tag/v0.13.0',
                'copyright': '2001–2024 Contributors to the Freedoom project'},
                'processing': 'Original patch canvas and first PLAYPAL palette; RGBA8 with column transparency; no resizing, recoloring or retouching.',
                'assets': assets}
    (directory / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    verify(directory)


def self_check():
    # Invalid pointers/posts and short palette must fail before indexing pixel data.
    invalid = [b'', struct.pack('<HHhhI', 1, 1, 0, 0, 100),
               struct.pack('<HHhhI', 1, 1, 0, 0, 12) + bytes([0, 2, 0, 1, 1, 0, 255])]
    for data in invalid:
        try:
            decode_patch(data, bytes(range(256)) * 3)
        except (ValueError, struct.error):
            continue
        raise ValueError('Malformed patch was accepted')
    # A minimal true patch retains source color and transparent background.
    patch = struct.pack('<HHhhI', 1, 2, 0, 0, 12) + bytes([0, 1, 0, 3, 0, 255])
    result = decode_patch(patch, bytes(range(256)) * 3)
    require(result[4] == bytes([9, 10, 11, 255, 0, 0, 0, 0]), 'Patch palette/transparency self-check failed')
    require(read_generated_png(encode_png(1, 2, result[4]))[2] == result[4], 'PNG round-trip failed')
    tall = struct.pack('<HHhhI', 1, 300, 0, 0, 12) + bytes([250, 1, 0, 3, 0, 10, 1, 0, 4, 0, 255])
    tall_rgba = decode_patch(tall, bytes(range(256)) * 3)[4]
    require(tall_rgba[250 * 4:250 * 4 + 4] == bytes([9, 10, 11, 255]), 'Tall-patch absolute post failed')
    require(tall_rgba[260 * 4:260 * 4 + 4] == bytes([12, 13, 14, 255]), 'Tall-patch relative post failed')



def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--iwad', type=Path)
    parser.add_argument('--output', type=Path, default=ASSETS)
    parser.add_argument('--verify', action='store_true', help='Verify existing committed files without the IWAD or Pillow')
    args = parser.parse_args()
    self_check()
    if args.verify:
        verify(args.output)
    elif args.iwad:
        extract(args.iwad, args.output)
    else:
        parser.error('Pass --iwad for extraction, or --verify for existing assets')


if __name__ == '__main__':
    main()
