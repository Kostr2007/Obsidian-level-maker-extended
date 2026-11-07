# ART-01 experimental resource selection implementation

- Agent: `ui_builder`; date: 2026-11-07.
- Base: `881ab88be7db36cd712be6cc2b261035c6a2102c`; branch: `codex/art-01-resource-selection`.
- Environment: Debian 13, retained Qt 6.8.2 toolchain, Xvfb/xcb, software renderer; normal DPR 1 and supplemental DPR 1.5. Qt 6.4 runtime execution remains for CI/independent verification.
- Scope: Resources selection in `--design-preview`, ART-01 option 1 only. Prototype decision remains with the user; this report is implementation evidence, not visual approval.

| ID | Area/state | Result | Evidence / criterion |
| --- | --- | --- | --- |
| ART-01 | Session-local A/B | Implemented | Preview commands menu offers A/classic and B/ART-01, with exclusive ButtonGroup; classic is the initial value on every launch. Actual mouse sequence A,A,B,B,A asserts both checkmarks and variant state. |
| ART-01-TYPE | B selected title | Implemented | Existing Inter `sectionFont` supplies DemiBold at exactly `bodyFont` pixelSize; title uses `tokens.text`, pill transparent. Selected card still uses unchanged `thumbnailSelected`; no layout, padding, assets or grid/list sizing edits. QtTest asserts these values. |
| ART-01-FOCUS | Arrow navigation, A and B | Bounded repair | Before fix, existing `previewResourcesAndMotion` gained an assertion that failed: health had activeFocus but visualFocus=false after Right. `navigate()` now explicitly passes TabFocusReason to the queued focusSelection; default calls retain OtherFocusReason. Existing 2px accent border is unchanged. Right/Left captures assert actual visualFocus and border width; keyboard border was personally opened in light B screenshot, without approving the aesthetic proposal. |

Production changes are only `prototype/Preview.qml` and `prototype/ResourceGallery.qml`. No DesignTokens, Studio, backend, CONFIG/preset migration, gameplay, other art proposals or assets changed. New `resourceTitle_<id>` object names permit private QtTest inspection; no public test/debug application API was added.

HIG/project source context is the already-reviewed ART-01 proposal in `build/art-direction/881ab88/art-director-proposals.md`, option 1, and project README/WORKFLOW/checklist. No new Apple-source research or Apple asset redistribution was performed.

## Tests executed

The retained toolchain needs `source /workspace/.obsidian-env/activate.sh`; plain host PATH initially lacked cmake. No packages were installed.

```sh
source /workspace/.obsidian-env/activate.sh
cmake --build build/qt -j2
xvfb-run -a env QT_QUICK_BACKEND=software \
  OBSIDIAN_TEST_ENGINE=$PWD/build/qt/obsidian-engine OBSIDIAN_TEST_DATA=$PWD \
  build/qt/source_files/qt_frontend/qt-core-tests \
  previewArt01Capture previewResourcesAndMotion
python3 scripts/dev/check-art01.py
```

Capture runner always creates a fresh directory under `build/art01` (or a new `--out` directory), builds the binary, and uses actual `Preview.qml` in QtTest. The 26-shot matrix includes eight matched A/B × light/dark × grid/list Ammo screenshots without card focus/hover; separate A/B keyboard states in both themes; B hovered Health neighbor, chosen Health, chosen Items/long title, 125% text and narrow list in both themes; and B grid/list at DPR 1.5 in both themes. State guards verify selected ID, active/visual focus, 2px focus border, hover IDs, image dimensions/DPR and unchanged Ammo/Health configuration values. Manifest records commit/tree, dirty status, exact source hashes, patch hash, binary hash, PNG hashes, dimensions, DPR, theme, variant, selection and focus. Rendering uses the existing app assets and tokens.

Early development captures failed state guards (startup queued focus, inaccessible search ID and menu layout timing); these incomplete runs are retained and are not review evidence. The successful capture path and final focused-test result are appended below. Historical baseline images were never overwritten.

## Recommendation

Independent functional, visual and accessibility review must use screenshots recaptured after the coordinator commits the implementation. Broad mandatory build/ctest/check-qt/check-design-preview checks remain for the coordinator/tester handoff. Native platform/screen-reader coverage and actual Qt 6.4 execution are unverified locally. No visual PASS or permanent replacement decision is made here.

Final local validation: build exit 0 (`build/art01-final-build.log`); focused QtTest exit 0, **4 passed / 0 failed**, including init/cleanup (`build/art01-focused-tests.log`); capture runner exit 0 (`build/art01-final-capture.log`). Final local artifact set: `build/art01/881ab88-20261107T044045942879Z/manifest.json`, six runs / 26 asserted screenshots, with current uncommitted source hashes and dirty-tree patch recorded. The final dark B keyboard screenshot was also personally opened: the accent focus border surrounds the selected Ammo card. `git diff --check` passed. These are development captures at base HEAD plus documented changes; coordinator/tester must recapture after commit for independent approval.
