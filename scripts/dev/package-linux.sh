#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
test -x ./obsidian || { echo 'Build first with scripts/dev/build-linux.sh' >&2; exit 1; }
destination="$PWD/build/Obsidian-Extended-Material-Workspace-linux-$(uname -m).tar.gz"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/Obsidian-Extended"
cp -a obsidian addons data docs engines games language modules ports scripts theme tools LICENSE.txt AUTHORS.md README.md CHANGELOG.md VERSION "$stage/Obsidian-Extended/"
cat > "$stage/Obsidian-Extended/start.sh" <<'EOF'
#!/bin/sh
set -eu
cd "$(dirname "$0")"
exec ./obsidian "$@"
EOF
chmod +x "$stage/Obsidian-Extended/start.sh"
printf '%s\n' 'Extract the archive into a writable folder and run ./start.sh.' 'Ubuntu runtime packages: libfontconfig1 libxft2 libxinerama1 libxcursor1 libgl1 libglu1-mesa' 'This archive targets its build distribution and architecture; it is not a universal Linux binary.' > "$stage/Obsidian-Extended/RUNNING.txt"
mkdir -p build
tar -czf "$destination" -C "$stage" Obsidian-Extended
printf '%s\n' "$destination"
