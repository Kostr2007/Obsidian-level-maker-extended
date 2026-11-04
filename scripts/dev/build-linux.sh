#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
# Ubuntu dependencies are documented in docs/qt6/UBUNTU.md.
cmake -S . -B build/qt -G Ninja -DCMAKE_BUILD_TYPE=Release -DOBSIDIAN_QT=ON
cmake --build build/qt --parallel "${OBSIDIAN_BUILD_JOBS:-4}"
printf 'Qt 6 build complete. Run ./obsidian from %s\n' "$PWD"
