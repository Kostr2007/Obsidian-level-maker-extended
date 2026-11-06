# Design and functionality review

- Commit: `c363ac162403cda3d447b8aab1ac56f3202c5847`, branch `codex/apple-design-agents`.
- Agent: independent `functional_tester`; requested reasoning **medium** in assignment/profile. Effective runtime effort **UNVERIFIED**, because the runtime does not expose it.
- Date: `2026-11-06` task date; actual captures `2026-11-06T21:52–21:54Z` (`2026-11-07` Europe/Moscow). Exact UTC timestamps are in the manifest and dialog sidecars.
- Environment: Debian 13.6 x86_64, Qt/QtTest 6.8.2, Qt Quick software renderer. Studio and Preview use isolated Xvfb X11/xcb without a window manager (virtual screens 1600×1000 and 1800×1200 respectively). Registered Qt core uses offscreen. Light/dark scale 1; light HiDPI `QT_SCALE_FACTOR=1.5`.
- Scope: EV-01 QA-only correction of dialog capture evidence; production UI/engine/schema/CONFIG behavior unchanged. Read [accepted plan](2026-11-06-plan.md) and [builder handoff](2026-11-06-ev01-implementation.md). No code/harness edits or commits made by this reviewer.
- Artifacts: [postchange evidence](../../../build/design-audit/c363ac1/postchange/), [manifest](../../../build/design-audit/c363ac1/postchange/evidence-manifest.json), [supplemental validation log](../../../build/design-audit/c363ac1/postchange/logs/evidence-validation.log). Preserved 71 fresh PNGs, three dialog sidecars/helper logs, five generated WAD/CONFIG result directories and full command logs. Historical baseline is retained separately.
- HIG sources: N/A for executable functional gate; independent visual review owns source-linked appearance acceptance.

| ID | Severity | Area/state | Verdict | Evidence | Apple/project principle | Reproduction + acceptance criterion |
| --- | --- | --- | --- | --- | --- | --- |
| EV01-F01 | — | Dialog capture light/dark/HiDPI | PASS | `preview/{light,dark,hidpi}/game-dialog-state.json`, `game-dialog-test.log`, PNGs; manifest | Evidence must show and assert its claimed state | All three sidecars identify current HEAD and `sourceWorktreeDirty=false`; dialog visible/opened true, opacity 1, engine popup invisible, textScale 1, expected theme and CONFIG keys. Each bounded helper reports 3 passed, 0 failed/skipped. PNG sizes match sidecars. |
| EV01-F02 | — | Core configuration, generation and dialogs | PASS | [Full core output](../../../build/design-audit/c363ac1/postchange/logs/qt-core-full.log) | Preserve existing settings and product behavior | Full registered Qt core suite: **15 passed, 0 failed, 0 skipped**, including new `previewGameDialogCapture`, prior popup/dialog/motion interactions, CONFIG round-trip, transactional invalid input, unknown-setting retention, generation, cancellation and missing-worker error handling. |
| EV01-F03 | — | Studio dark/light and Preview all three modes | PASS | [Studio log](../../../build/design-audit/c363ac1/postchange/logs/check-qt.log), [Preview log](../../../build/design-audit/c363ac1/postchange/logs/check-design-preview.log), [validation](../../../build/design-audit/c363ac1/postchange/logs/evidence-validation.log) | Real WAD/CONFIG validation and diagnostic-free runtime | Full scripts exit 0. All five generated WADs have 56 bounded directory entries and MAP01/LINEDEFS/VERTEXES; paired result CONFIG contains seed 12345 and port boom. Five main launch logs are empty. Each separate QtTest helper log was explicitly scanned for QML errors, QWARN and QFATAL; none found. |
| EV01-F04 | — | Missing capture-test executable | PASS | [Intentional missing-test check](../../../build/design-audit/c363ac1/postchange/logs/missing-test.log) | Failed evidence collection must fail actionably | Imported the helper with a deliberately nonexistent ROOT, without altering/renaming the real binary. It raises before capture and names `./scripts/dev/build-linux.sh`, `BUILD_TESTING=ON` and the missing executable. |
| EV01-F05 | — | Native platform/accessibility and new motion clips | UNVERIFIED / unchanged scope | Accepted baseline and recorded environment | Do not infer coverage from test names | No screen reader/AT-SPI, native Wayland/macOS/Windows or GPU run. No new motion clips were recorded because production motion is unchanged; existing core motion assertions passed. Current PNGs are fresh; prior baseline videos were not copied into current evidence. |

The baseline engine dropdown screenshot concern was corrected by independent inspection: `engine-popup.png` does show the dropdown. The confirmed baseline gap was `game-dialog.png`; EV-01 addresses that gap without implying a production dialog defect.

## Capture identity and dimensions

These dialog PNGs come from **a separate QtTest process loading the same production `qrc:/ui/prototype/Preview.qml`**, via `QQuickWindow::grabWindow`; they are not a screenshot of the main application process after F2. The helper uses an isolated backend with engine `idtech_1`, game `doom2`, port `boom`, length `single`, seed `12345`, project section and default text zoom. Its ready-to-generate footer and transient focus/inspection history can differ from the main process. Main-process generation remains independently validated.

| Mode | Logical size | Actual PNG pixels | DPR | Theme | Asserted state |
| --- | --- | --- | --- | --- | --- |
| light | 1440×900 | 1440×900 | 1 | light | opened/visible; opacity 1; popup hidden |
| dark | 1440×900 | 1440×900 | 1 | dark | opened/visible; opacity 1; popup hidden |
| hidpi | 1152×740 | 1728×1110 | 1.5 | light | opened/visible; opacity 1; popup hidden |

The manifest records all PNG SHA-256 hashes, measured dimensions and timestamps, plus complete dialog sidecar state. No tracked report was written until all captures and the clean-worktree evidence validation finished. Only source artifacts modified after this run's setup log were copied; stale files were excluded.

## Tests executed

All commands ran from the repository root after `source /workspace/.obsidian-env/activate.sh`:

```text
python3 scripts/dev/check-design-agent-setup.py
  exit 0; build/design-audit/c363ac1/postchange/logs/setup.log
./scripts/dev/build-linux.sh
  exit 0; build/design-audit/c363ac1/postchange/logs/build-linux.log
QT_QUICK_BACKEND=software ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
  exit 0; build/design-audit/c363ac1/postchange/logs/qt-core.log
  full individual results: logs/qt-core-full.log; 15 passed, 0 failed/skipped
python3 scripts/dev/check-qt.py
  exit 0; build/design-audit/c363ac1/postchange/logs/check-qt.log
python3 scripts/dev/check-design-preview.py
  exit 0; build/design-audit/c363ac1/postchange/logs/check-design-preview.log
  all default modes: light, dark, hidpi; no --motion requested
Minimal imported-helper missing-binary check
  exit 0; build/design-audit/c363ac1/postchange/logs/missing-test.log
python3 build/design-audit/c363ac1/postchange/logs/validate-evidence.py
  exit 0; build/design-audit/c363ac1/postchange/logs/evidence-validation.log
```

Build configuration retains the existing optional XKB discovery and QtQuick qmldir warnings; full build exits 0. These configuration warnings are separate from application/helper runtime QML diagnostics. No command failure or runtime diagnostic was reproduced. WAD byte equality across generation runs is not asserted; existing engine behavior does not promise it. CONFIG keys, result preservation and readable map output remain checked.

## Recommendation

**ACCEPT** the EV-01 functional gate at `c363ac1`. The confirmed dialog evidence gap is closed by executable state assertions and fresh clean-commit artifacts. Independent visual acceptance remains assigned to `visual_critic`; Ubuntu Qt 6.4 validation remains with the coordinator.

## Handoff to builder

No additional changes are needed from this functional review. Production UI remains unchanged, so the accepted independent accessibility baseline applies within its recorded limits.
