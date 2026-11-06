# EV-01 implementation handoff

- Builder: `ui_builder`; requested effort **medium** explicitly passed in the assignment and profile. Effective runtime effort **UNVERIFIED** (not exposed).
- Source: dirty worktree based on `cc7d2919d4dab74c43a2f1cdd4a297820ba3d26b`, 2026-11-06 UTC. No builder commit. Production UI remains unchanged.
- Scope: QA-only correction of `game-dialog.png`; no production QML/C++, engine, schema or CONFIG behavior changed. Independent visual approval is **UNVERIFIED / pending**.

The old sequence was reproduced with temporary diagnostics in the new QtTest slot: immediately after Escape the actual combo popup still had `visible=true`; after immediately sending Ctrl+G and waiting 400 ms, the popup was closed but `gameDialog.opened=false`. See `build/design-audit/ev01-builder/reproduction.log`. Escape starts the popup exit transition, during which the shortcut is consumed. The diagnostic/immediate-shortcut lines were removed from the final test.

`previewGameDialogCapture()` now opens the real engine popup, asserts `opened`, sends Escape, waits for actual `!visible`, sends Ctrl+G, asserts `gameDialog.opened` and opacity 1, waits for a rendered frame and rechecks visible/opened before saving. It also asserts Escape closes the dialog. These assertions run in the regular Qt core suite even without a screenshot destination.

The X11 harness retains its existing `engine-popup.png` capture. After the main application exits successfully, it invokes this bounded QtTest slot for each mode and fails on missing test executable, nonzero test exit, timeout or absent artifacts. Old dialog artifacts are removed before the test. The success message explicitly attributes dialog verification to QtTest. No public test/debug API or image-content heuristic was added.

The dialog image is a **separate QtTest process using the same production QML**, captured by `QQuickWindow::grabWindow`, rather than an image of the main `obsidian` process. It uses an isolated temporary backend, the same engine/game/port/length/seed CONFIG, project destination, default text zoom and inherited X11 screen/DPI. Generation is still checked in the main process; the test capture itself starts in the ready-to-generate state, so footer status/output path and transient inspection/focus history differ from the former post-generation image. Sidecars explicitly identify the capture origin and record actual logical/pixel sizes, DPR, theme, zoom, CONFIG keys, popup/dialog state, source HEAD/dirty state and UTC time.

| Mode | Actual logical size | Actual pixels | DPR | Theme / text zoom | State at capture |
| --- | --- | --- | --- | --- | --- |
| light | 1440×900 | 1440×900 | 1 | light / 1 | popup invisible; dialog visible/opened, opacity 1 |
| dark | 1440×900 | 1440×900 | 1 | dark / 1 | popup invisible; dialog visible/opened, opacity 1 |
| hidpi | 1152×740 | 1728×1110 | 1.5 | light / 1 | popup invisible; dialog visible/opened, opacity 1 |

Evidence: `build/design-audit/ev01-builder/captures/{light,dark,hidpi}/` contains `game-dialog.png`, `game-dialog-state.json`, `game-dialog-test.log`, the unchanged-path `engine-popup.png` and main `launch.log`. `captures/manifest.json` records image hashes and state. Historical incorrect images remain under `build/design-audit/81cbc4f/baseline/preview/`.

Commands executed from the repository root after `source /workspace/.obsidian-env/activate.sh` (Qt 6.8.2, software Qt Quick, Debian 13):

```text
cmake --build build/qt --target qt-core-tests --parallel 4
  exit 0; build/design-audit/ev01-builder/build-focused-final.log
QT_QUICK_BACKEND=software ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
  exit 0; build/design-audit/ev01-builder/qt-core.log; 1/1 registered test passed, 30.75 s
python3 scripts/dev/check-design-preview.py
  exit 0; build/design-audit/ev01-builder/check-design-preview.log; all three modes passed
python3 -m py_compile scripts/dev/check-design-preview.py
  exit 0
python3 scripts/dev/check-design-agent-setup.py
  exit 0; build/design-audit/ev01-builder/setup.log
```

Supplemental inline checks exited 0: imported the harness with a nonexistent test executable and asserted its actionable `build-linux.sh` / `BUILD_TESTING=ON` error (`missing-test.log`); copied/validated all three capture sidecars, dimensions/theme/zoom/state and empty main runtime logs, recording SHA-256 hashes in `captures/manifest.json`. Three capture QtTest logs each report 3 passed, 0 failed/skipped. `git diff --check` for both authorized source files passed.

Builder inspected the light and HiDPI images to confirm the intended surface was captured, without claiming independent visual acceptance. The full build, Studio smoke test, committed-source recapture and independent functional/visual gates remain assigned to the coordinator's reviewers. Native platform/screen-reader coverage is unchanged and UNVERIFIED. This is the first implementation round of the maximum three.
