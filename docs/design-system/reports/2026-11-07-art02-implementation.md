# ART-02 implementation handoff

- Agent: `ui_builder`; date: 2026-11-07; base: `41b5d16`; branch: `codex/art-02-settings-texture`.
- Purpose: user-authorized texture experiment, with the existing zebra A retained as launch default. No permanent ART-02 adoption or aesthetic approval is implied.
- Production scope: `Preview.qml` adds a session-local `geometryTextureStyle` and an exclusive A/B menu pair in its own ButtonGroup; `PreviewOptionRow.qml` adds an optional uniform group-colored surface and inset neutral separator. Only Geometry's `ui_arch` group opts in. The final row has no separator. Existing outer group, radius, typography, geometry, controls, slider, Seed and Qt 6.4 stable Column layout remain intact. ResourceGallery, backend, CONFIG and tokens are unchanged; ART-01 classic remains the launch default.
- Reference context: original option 2 in `build/art-direction/881ab88/art-director-proposals.md`; personally viewed cached official MAC-14 System Settings (`/tmp/apple-research-2026-11-06/settings.png`) and MAC-13 Finder (`finder.png`). Project line/color/inset values are implementation choices, not Apple-prescribed measurements.

`previewArt02Capture` loads actual resource-embedded Preview.qml in QtTest. It checks actual menu mouse clicks A,A,B,B,A, independent exclusivity from ART-01, fresh-window A/classic defaults, unchanged exported CONFIG bytes/revision/seed/options, exact target title, original off-scope surfaces, every separator including the final row, matching A/B visible item geometry/text/values, existing combo keyboard focus and its opened popup. The runner creates a unique artifact directory and builds before capturing. Metadata includes commit/tree/status, source/binary/PNG/patch hashes, section/group/style, resources=classic, theme, logical/pixel sizes, DPR/text scale, control focus/selection, inspected option and row geometry.

Commands (each shell first sources `/workspace/.obsidian-env/activate.sh`):

```sh
python3 scripts/dev/check-art02.py
python3 -m py_compile scripts/dev/check-art02.py
git diff --check
```

Current final run/results and artifact path are recorded below. The matrix is 24 shots: light/dark normal 1440×900, 125% text, narrow 1050×640, existing focused combo, open combo popup, each A/B at DPR 1; normal A/B light/dark at DPR 1.5. Names: `<theme>-paired-dpr<scale>/<scenario>-<zebra|uniform>.png`; scenario is `normal`, `large-text`, `narrow`, `focus` or `popup`.

The first invocation failed in test setup because it called the Studio-only `refreshInspection`; changed to Preview's existing `selectInitial`. The next complete matrix exited 0 (24 shots). Final strengthened guards are captured in the run below. No production QML warning was present in the successful logs.

These are developer working-tree captures with explicit provenance, not clean-commit visual acceptance. Coordinator commits, then independent testers recapture and run the mandatory broad suite. Qt 6.4 execution, native macOS/platform accessibility and artistic preference remain for independent review. No commit/push performed by builder.

Final focused verification: `python3 scripts/dev/check-art02.py` exited **0**, rebuilding successfully and capturing all **24** asserted screenshots under `build/art02/41b5d16-20261107T051615255717Z/`. Each of four `test.log` files reports 3 passed / 0 failed / 0 skipped, Qt 6.8.2, Xvfb/xcb/software renderer. `python3 -m py_compile scripts/dev/check-art02.py` and `git diff --check` exited **0**. Manifest: `build/art02/41b5d16-20261107T051615255717Z/manifest.json`.
