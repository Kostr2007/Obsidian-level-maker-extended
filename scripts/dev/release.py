#!/usr/bin/env python3
"""Prepare changelog notes and publish a tested, versioned GitHub release.

Authentication comes from gh's normal environment. No credentials are stored.
Published releases are immutable to this script; a matching draft can be resumed.
"""
import argparse
import json
import re
import subprocess
from pathlib import Path


def release_metadata(root):
    version = (root / 'VERSION').read_text(encoding='utf-8').strip()
    if not re.fullmatch(r'(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)', version):
        raise ValueError('VERSION must contain a stable semantic version, e.g. 0.2.0')
    changelog = (root / 'CHANGELOG.md').read_text(encoding='utf-8')
    heading = re.search(r'^## \[' + re.escape(version) + r'\] - \d{4}-\d{2}-\d{2}\s*$', changelog, re.M)
    if not heading:
        raise ValueError(f'CHANGELOG.md has no dated entry for {version}')
    rest = changelog[heading.end():]
    notes = re.split(r'^## ', rest, maxsplit=1, flags=re.M)[0].strip()
    if not notes:
        raise ValueError(f'CHANGELOG.md entry for {version} is empty')
    return version, notes + '\n'


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def github(path):
    result = subprocess.run(['gh', 'api', path], capture_output=True, text=True)
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        raise RuntimeError(result.stderr.strip() or 'Invalid response from GitHub')
    if result.returncode:
        if isinstance(data, dict) and str(data.get('status')) == '404':
            return None
        raise RuntimeError(result.stderr.strip() or str(data))
    return data


def find_release(api, tag):
    # GitHub's release-by-tag endpoint only returns published releases. Drafts
    # must be discovered through the authenticated release listing.
    release = github(f'{api}/releases/tags/{tag}')
    if release:
        return release
    page = 1
    while True:
        releases = github(f'{api}/releases?per_page=100&page={page}')
        if not isinstance(releases, list):
            raise RuntimeError('Unable to list existing release drafts')
        for release in releases:
            if release['tag_name'] == tag:
                return release
        if len(releases) < 100:
            return None
        page += 1


def publish(root, repository, assets):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Repository must have the form owner/name')
    version, notes = release_metadata(root)
    tag = 'v' + version
    sha = command('git', '-C', str(root), 'rev-parse', 'HEAD')
    api = f'repos/{repository}'
    existing = find_release(api, tag)
    if existing and not existing['draft']:
        print(f'Release {tag} already published; leaving it unchanged: {existing["html_url"]}')
        return
    for asset in assets:
        if not asset.is_file() or not asset.stat().st_size:
            raise ValueError(f'Missing or empty asset: {asset}')
    ref = github(f'{api}/git/ref/tags/{tag}')
    if existing and not ref and existing['target_commitish'] != sha:
        target = github(f'{api}/commits/{existing["target_commitish"]}')
        if not target or target['sha'] != sha:
            raise ValueError(f'Draft {tag} targets another commit; bump VERSION instead')
    if ref:
        obj = ref['object']
        while obj['type'] == 'tag':
            obj = github(f'{api}/git/tags/{obj["sha"]}')["object"]
        if obj['type'] != 'commit' or obj['sha'] != sha:
            raise ValueError(f'{tag} already points at another commit; bump VERSION instead')
    notes_file = root / 'build/release-notes.md'
    notes_file.parent.mkdir(parents=True, exist_ok=True)
    notes += f'\nИнструкция установки Ubuntu: https://github.com/{repository}/blob/{tag}/docs/material-you/UBUNTU.md\n'
    notes_file.write_text(notes, encoding='utf-8')
    if not existing:
        subprocess.run(['gh', 'release', 'create', tag, '--repo', repository,
                        '--target', sha, '--title', f'Obsidian Extended {version} — Material Workspace',
                        '--notes-file', str(notes_file), '--draft'], check=True)
    else:
        subprocess.run(['gh', 'release', 'edit', tag, '--repo', repository,
                        '--notes-file', str(notes_file)], check=True)
    subprocess.run(['gh', 'release', 'upload', tag, '--repo', repository,
                    '--clobber', *(str(path) for path in assets)], check=True)
    subprocess.run(['gh', 'release', 'edit', tag, '--repo', repository,
                    '--draft=false'], check=True)
    print(f'Published https://github.com/{repository}/releases/tag/{tag}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['prepare', 'publish'])
    parser.add_argument('--repo')
    parser.add_argument('--notes-file', type=Path)
    parser.add_argument('assets', nargs='*', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    if args.operation == 'prepare':
        version, notes = release_metadata(root)
        if args.notes_file:
            args.notes_file.parent.mkdir(parents=True, exist_ok=True)
            args.notes_file.write_text(notes, encoding='utf-8')
        print(version)
    else:
        if not args.repo or not args.assets:
            parser.error('publish requires --repo and release assets')
        publish(root, args.repo, args.assets)


if __name__ == '__main__':
    main()
