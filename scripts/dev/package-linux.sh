#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
test -x ./obsidian && test -x ./obsidian-engine || { echo 'Build first with scripts/dev/build-linux.sh' >&2; exit 1; }
frontend_version=$(QT_QPA_PLATFORM=offscreen ./obsidian --version)
case "$frontend_version" in
  ObsidianExtended*) ;;
  *) echo 'The root executable is not the Qt frontend. Rebuild with scripts/dev/build-linux.sh.' >&2; exit 1 ;;
esac
destination="$PWD/build/Obsidian-Extended-Qt6-linux-$(uname -m).tar.gz"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/Obsidian-Extended"
cp -a obsidian obsidian-engine addons data docs engines games language modules ports scripts theme tools LICENSE.txt AUTHORS.md README.md CHANGELOG.md VERSION "$stage/Obsidian-Extended/"
cat > "$stage/Obsidian-Extended/start.sh" <<'EOF'
#!/bin/sh
set -eu
cd "$(dirname "$0")"
exec ./obsidian "$@"
EOF
chmod +x "$stage/Obsidian-Extended/start.sh"
printf '%s\n' 'Extract the archive and run ./start.sh. Settings are saved in the user configuration directory.' 'Install the Qt 6 runtime packages listed in docs/qt6/UBUNTU.md.' 'This archive targets its build distribution and architecture; it is not a universal Linux binary.' > "$stage/Obsidian-Extended/RUNNING.txt"
mkdir -p build
tar --exclude=__pycache__ --exclude='*.pyc' -czf "$destination" -C "$stage" Obsidian-Extended
printf '%s\n' "$destination"
