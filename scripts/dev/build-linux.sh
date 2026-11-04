#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
# Dependencies for Ubuntu 24.04 / 26.04; install explicitly before building:
# sudo apt install build-essential cmake ninja-build flex libfontconfig1-dev \
#   libxft-dev libxinerama-dev libxcursor-dev libgl1-mesa-dev libglu1-mesa-dev
cmake -S . -B build/material -G Ninja -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_WAYLAND=OFF
cmake --build build/material --parallel "${OBSIDIAN_BUILD_JOBS:-4}"
printf 'Build complete. Run ./obsidian from %s\n' "$PWD"
