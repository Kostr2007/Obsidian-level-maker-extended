# Design and functionality review

- Commit: `81cbc4f532397f28c9d940b923a97b6a7f7733bd` (`codex/apple-design-agents`), rebuilt at this HEAD.
- Agent: `functional_tester`; requested reasoning **medium** in the role profile and coordinator assignment. The effective runtime reasoning setting is **UNVERIFIED**: this tool surface does not expose it.
- Date: `2026-11-06` (task date). Actual captures: `2026-11-06` UTC, approximately 21:38–21:40; Europe/Moscow wall clock was already `2026-11-07`. Exact UTC timestamps are retained per artifact.
- Environment: Debian GNU/Linux 13.6, x86_64, Qt 6.8.2, Qt Quick software renderer. GUI checks use isolated Xvfb X11/xcb without a window manager; Qt core uses the CTest-registered offscreen platform. Studio: dark/light, scale 1, 1600×1000 virtual screen. Preview: light/dark scale 1 and light `QT_SCALE_FACTOR=1.5`, 1800×1200 virtual screen. `hidpi.png` actually measures 1728×1110 pixels; requested window size must not be substituted for measured capture size.
- Scope: read-only baseline of real Studio **and the separate design-preview experiment**, before any redesign. No production source, test, harness or historical documentation screenshot was changed; no commit made.
- Artifacts: [baseline directory](../../../build/design-audit/81cbc4f/baseline/) is at repository root under `build/design-audit/81cbc4f/baseline/`. [Evidence manifest](../../../build/design-audit/81cbc4f/baseline/evidence-manifest.json) records 87 fresh PNG/MP4/GIF artifacts, hashes, measured PNG sizes, theme/scale and UTC capture timestamps. Generated results and runtime launch logs are retained in `studio/` and `preview/`.
- HIG sources: N/A for this functional gate. Official-source visual interpretation belongs to the independent researcher/visual critic.

| ID | Severity | Area/state | Verdict | Evidence | Apple/project principle | Reproduction + acceptance criterion |
| --- | --- | --- | --- | --- | --- | --- |
| FUNC-01 | — | Core, configuration and generation | PASS | [Full QtTest output](../../../build/design-audit/81cbc4f/baseline/logs/qt-core-full.log): 14 passed, 0 failed/skipped | Preserve CONFIG round-trip, schema IDs and existing results | Executed registered `qt-core`; unknown options survive round-trip/import/export, invalid CONFIG is transactional, generation creates readable geometry and CONFIG, repeat generation preserves prior result/config, cancellation preserves existing files, missing worker reports failure. |
| FUNC-02 | — | Studio dark/light; preview light/dark/HiDPI | PASS within executed checks | [Studio log](../../../build/design-audit/81cbc4f/baseline/logs/check-qt.log), [preview log](../../../build/design-audit/81cbc4f/baseline/logs/check-design-preview.log), [result validation](../../../build/design-audit/81cbc4f/baseline/logs/artifact-validation.log) | Actual generated WAD/CONFIG and clean application exit | Both full scripts exited 0. All five fresh GUI results have valid PWAD directories, 56 bounded entries and MAP01/LINEDEFS/VERTEXES; result CONFIG contains seed 12345 and port boom. All five application launch logs are empty. Search, resize and shortcuts were exercised; screenshots alone do not prove interaction outcomes. |
| FUNC-03 | P2 | Preview intended popup/dialog screenshots | UNVERIFIED / evidence gap | [light/game-dialog.png](../../../build/design-audit/81cbc4f/baseline/preview/light/game-dialog.png); `typography_captures()` in existing `scripts/dev/check-design-preview.py`; independent visual critic reports project/engine focus rather than a modal | Current screenshot must show its claimed state | The harness sends Tab/Space/Escape/Ctrl+G but does not assert the resulting popup/dialog visibility. Its printed “dialogs passed” is broader than its assertions. `engine-popup.png`, other dialog-named images and shortcut-driven motion clips must be inspected for actual state before treating them as proof. Later scoped harness correction should wait for the actual target state and fail on absence; no correction performed during this baseline. |
| FUNC-04 | — | Actual popup/dialog behavior and motion | PASS in independent QtTest scope | [Full QtTest output](../../../build/design-audit/81cbc4f/baseline/logs/qt-core-full.log); `previewResourcesAndMotion()` in `source_files/qt_frontend/tests/test_core.cpp` | Executable interaction evidence takes precedence over filenames | QtTest asserts combo popup opens, Escape cancels and Return commits; commands menu opens, menu click opens gameDialog, Ok closes it; comparison Close and inspector Escape close actual dialogs. Opacity signals have intermediate events. Eight real X11 MP4/GIF pairs were captured, including reduced-motion actions; every clip’s intended semantic state is not independently asserted. |
| FUNC-05 | — | Native platform/accessibility coverage | UNVERIFIED | [Environment](../../../build/design-audit/81cbc4f/baseline/logs/environment.log) | Report platform limits honestly | No screen reader/AT-SPI, real Wayland compositor, native desktop/window manager, hardware renderer, macOS/Windows or Qt 6.4 run was performed. Xvfb interaction and offscreen tests establish only their recorded environment. |

## Tests executed

All commands ran from the repository root after `source /workspace/.obsidian-env/activate.sh`. Full logs retain `AUDIT_EXIT_CODE=0` markers written only after observed process exit 0.

```text
python3 scripts/dev/check-design-agent-setup.py
  exit 0; build/design-audit/81cbc4f/baseline/logs/setup.log
./scripts/dev/build-linux.sh
  exit 0; build/design-audit/81cbc4f/baseline/logs/build-linux.log
QT_QUICK_BACKEND=software ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
  exit 0; build/design-audit/81cbc4f/baseline/logs/qt-core.log
  full individual-case output: logs/qt-core-full.log (14 passed)
python3 scripts/dev/check-qt.py
  exit 0; build/design-audit/81cbc4f/baseline/logs/check-qt.log
python3 scripts/dev/check-design-preview.py --motion
  exit 0; build/design-audit/81cbc4f/baseline/logs/check-design-preview.log
  all default modes: light, dark, hidpi; ffmpeg 7.1.5 available
Supplemental inline Python WAD directory/CONFIG/runtime-log validation
  exit 0; build/design-audit/81cbc4f/baseline/logs/artifact-validation.log
```

Build configuration emitted missing optional XKB discovery and QtQuick qmldir warnings. Build succeeded; these are retained in the full build log and are separate from runtime QML diagnostics. There were no runtime diagnostics in the five GUI launch logs and no test failure.

Fresh output was copied from `build/qt-ui-check/` and `build/design-preview-check/` only when its modification time was after this audit began (`2026-11-06T21:37:00Z`). Older results/screenshots were excluded. The report does not assert deterministic equality of WAD geometry across runs; the existing engine contract explicitly excludes it.

## Recommendation

**ACCEPT for the executed functional baseline.** No functional P0/P1 regression was reproduced. Overall visual acceptance remains with the independent visual critic. Named popup/dialog screenshot coverage and motion semantics remain **UNVERIFIED** where the harness lacks state assertions; retain this limitation before using them as redesign acceptance evidence.

## Handoff to builder

No production UI change is requested by this functional audit. Collect the independent reviews and prioritize findings first. A later, separately assigned capture-harness correction should assert intended dialog/popup state before saving evidence. No new tests or harness edits were authorized or made in this audit.
