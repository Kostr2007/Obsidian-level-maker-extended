# Accessibility baseline review

- Commit: `81cbc4f532397f28c9d940b923a97b6a7f7733bd` (runtime preview unchanged from `8154537`, per coordinator baseline).
- Agent: `accessibility_critic`; profile requests medium effort, explicit medium override accepted. Effective runtime effort: **UNVERIFIED**, not exposed by the agent runtime.
- Requested report date: `2026-11-06`. Actual UTC screenshot times: `2026-11-06T21:43:30Z` onward; exact per-image times are in [manifest.json](../../../build/design-audit/81cbc4f/accessibility/manifest.json).
- Environment: Debian 13, Qt 6.8.2, independent Xvfb X11 display `:0`, software Qt Quick renderer, no window manager; own captures 1440×900, display scale 1, text scales 1 and 1.25. Baseline also includes 900×540 minimum and 1.5 display scale.
- Scope: current `--design-preview` keyboard paths, focus, enlarged text, minimum window/list scrolling, HiDPI, explicit accessible names, nominal text contrast, reduced motion. This is a bounded preview audit; the real studio is separately identified in the functional baseline.
- Artifacts: [independent captures/logs](../../../build/design-audit/81cbc4f/accessibility/), [immutable current baseline](../../../build/design-audit/81cbc4f/baseline/preview/), [functional baseline](2026-11-06-functional-baseline.md). No production QML or tests edited; no commits created.
- HIG source actually read through researcher-fetched official page text: [Motion](https://developer.apple.com/design/human-interface-guidelines/motion), local `/tmp/apple-research-2026-11-06/motion.txt`. Its relevant guidance makes motion optional and avoids motion as the sole communication channel. [Layout](https://developer.apple.com/design/human-interface-guidelines/layout), local `layout.txt`, read for adaptation to window resizing. Apple guidance is advisory for this Qt desktop app, with no Apple pixel requirements asserted.
- Visual Apple reference actually viewed: `/tmp/apple-research-2026-11-06/settings.png`, the Apple Support System Settings Menu Bar screenshot listed in the [reference catalog](../references/apple/README.md). It shows named rows, persistent sidebar labels and grouped controls; it does not prove keyboard or assistive technology behavior. No Apple image copied into repository assets.

No confirmed P0, P1 or P2 production issue was found in this bounded review. The rows below describe verified checks and evidence limits, rather than proposing speculative redesign.

| ID | Severity | Area/state | Verdict | Evidence | Apple/project principle | Reproduction + acceptance criterion |
| --- | --- | --- | --- | --- | --- | --- |
| A11Y-01 | — | Keyboard menu and modal opening, dismissal, focus | PASS for executed path | [actual game modal](../../../build/design-audit/81cbc4f/accessibility/game-dialog-keyboard.png), [Escape returns search focus](../../../build/design-audit/81cbc4f/accessibility/dialog-escape.png), [Down highlights menu item](../../../build/design-audit/81cbc4f/accessibility/menu-keyboard-focus.png), [menu dismissed](../../../build/design-audit/81cbc4f/accessibility/menu-escape.png) | Project: keyboard interaction and visible focus | From ready preview: Ctrl+F → Ctrl+G → Tab → Escape; Ctrl+Shift+P → Down → Escape. Modal and menu visibly open, Escape closes each, and search has a blue outline afterward. This does not assert a complete modal tab cycle or every control's focus state. |
| A11Y-02 | — | 125% text, minimum layout and HiDPI | PASS within inspected states | Own [geometry 125%](../../../build/design-audit/81cbc4f/accessibility/geometry-125.png); baseline `preview/light/{large-text,geometry-large-text,minimum,minimum-list-last}.png`, `preview/dark/{geometry-large-text,minimum-list-last}.png`, `preview/hidpi.png` | Project: enlarged-text readability, adaptive layout, visible keyboard selection | Ctrl++ enlarges typography; geometry labels/values remain readable. At 900×540 the last list card is fully above the footer after navigation. 1.5-scale toolbar and gallery remain legible. Long unselected gallery title elides at 125%; selection has a full inspector title, and source retains its full accessible name. No confirmed loss of the item's identity/function. Minimum size combined with 125% text was not independently captured. |
| A11Y-03 | — | Resource keyboard focus and reduced motion | PASS for tested paths | [health selected via Right](../../../build/design-audit/81cbc4f/accessibility/resource-health-focus.png); [checked enlarged-text/reduced-motion menu](../../../build/design-audit/81cbc4f/accessibility/reduced-motion-menu.png); [Qt interaction assertions](../../../build/design-audit/81cbc4f/accessibility/qt-preview-interaction.log) | Motion: optional animation; project: keyboard selection and scroll reachability | Alt+3 → Right changes category and inspector to health. Ctrl+Shift+M enables reduced motion. Independent existing QtTest asserts active focus follows cards, last-list navigation remains visible, actual popup/dialog close behavior, and reduced navigation emits zero motion-active changes. Own static captures prove checked setting/final state; they do not quantify animation duration or prove OS reduced-motion integration. |
| A11Y-04 | — | Accessible names and assistive technology | Source checks PASS; runtime exposure UNVERIFIED | `prototype/Preview.qml` explicit names for toolbar icon buttons/search/seed; `prototype/ResourceGallery.qml` full title and selected description; `GameSetup.qml` names combo boxes from row labels; `prototype/PreviewOptionRow.qml` names option controls and help buttons | Project: descriptive names and icon+text semantics | Names are explicit in reviewed source. Keyboard behavior is verified independently of assistive technology. The environment's Python cannot import `pyatspi`; no AT-SPI accessible-tree or real screen-reader test was completed. Do not claim screen-reader compliance, complete name coverage, or that all runtime roles/states are correct. |
| A11Y-05 | — | Sample body/secondary/primary-action text contrast | PASS for nominal sampled token pairs only | [source contrast calculation](../../../build/design-audit/81cbc4f/accessibility/source-contrast.log); `prototype/DesignTokens.qml` | Project: legible text in light/dark; arithmetic ratios are not visual estimates | Eight explicit foreground/background pairs calculated using relative luminance: minimum 5.22:1 (white on light-theme accent); secondary text/sidebar 5.30:1 light and 6.81:1 dark. This calculation does not cover rendered opacity, all states, control boundaries, images or every UI text/background pair. |

## Tests executed

```text
source /workspace/.obsidian-env/activate.sh
python3 /tmp/obsidian-accessibility-runner.py
Exit 0; independent Xvfb keyboard path, 13 images and UTC manifest.
Log: build/design-audit/81cbc4f/accessibility/runner.log
Exact disposable runner preserved at build/design-audit/81cbc4f/accessibility/runner.py.

QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
OBSIDIAN_TEST_ENGINE=/workspace/Obsidian-level-maker-extended/build/qt/obsidian-engine \
OBSIDIAN_TEST_DATA=/workspace/Obsidian-level-maker-extended \
build/qt/source_files/qt_frontend/qt-core-tests previewResourcesAndMotion
Exit 0; 3 passed, 0 failed, 0 skipped; 8569ms.
Log: build/design-audit/81cbc4f/accessibility/qt-preview-interaction.log

Python relative-luminance calculation from eight source token pairs: exit 0.
Log: build/design-audit/81cbc4f/accessibility/source-contrast.log

Python import pyatspi: unavailable (No module named 'pyatspi').
Accessible tree / screen reader: UNVERIFIED.
```

The existing baseline harness's dialog-named image gap remains as documented in FUNC-03. This review only accepts a dialog/menu screenshot after visually observing the actual surface. Fresh `game-dialog-keyboard.png` shows the modal; a filename alone is not evidence. Full build/core/studio suites were already executed by functional_tester and were not repeated here; consult that independent report for their results.

## Recommendation

**ACCEPT for the bounded keyboard/layout/reduced-motion baseline.** Assistive technology interoperability remains **UNVERIFIED**, not a production failure established by this audit. No confirmed production change is requested.

## Handoff to builder

No changes are needed from the evidence collected in this scope. Any later accessibility work should first capture the actual accessible tree and run an appropriate screen reader; source names and screenshots cannot substitute for that test.
