#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
command -v inkscape >/dev/null
for name in level-size monster-quantity steepness; do
  inkscape "docs/artwork/studio-samples/$name.svg" --export-type=png \
    --export-width=1680 --export-filename="docs/artwork/studio-samples/$name.png"
done
