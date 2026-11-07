# ART-04 implementation handoff

- Agent: `ui_builder`; date: 2026-11-07.
- Base commit: `0e8df85acdaf69afc63730701ce24bbae12cba42`; production/test/helper working-tree patch, awaiting coordinator commit and independent review.
- Scope: six main category icons in `--design-preview`, session-only A/B. No shared `PreviewIcon.qml`, Studio, backend, CONFIG, preset, slider or inspector implementation change.
- Development evidence: `build/art04/0e8df85-20261107T145835757829Z/manifest.json`. All four source hashes match the finished production/test/helper files. This is explicitly dirty-tree development evidence, not clean-commit acceptance evidence.

## Implementation

`sidebarIconStyle` is `original` on each fresh QML application engine. The exclusive command-menu entries `sidebarIconsOriginal` / `sidebarIconsBadges` switch A/B. Neither writes backend preferences. Existing classic/zebra/original choices remain default and unchanged.

A keeps the exact six original colored glyphs and their 18×18 icon slots. B centers a 22×22, radius-5 colored square behind the same 18×18 original glyph, with white ink. The wrapper retains the original implicit size, so rows, labels, editor and inspector do not shift. Existing selected-row fill, focus outline and accessible names remain in place. Each wrapper, glyph, badge, row and label has a stable objectName for runtime evidence. No external artwork is added.

B uses matching hues darkened where needed. Actual runtime colors and white/backplate contrast are recorded per icon in every state:

| Category | B backplate | Contrast |
| --- | --- | --- |
| Project | `#77818d` | 3.96:1 |
| Geometry | `#1678ce` | 4.55:1 |
| Combat | `#d44946` | 4.34:1 |
| Resources | `#b87512` | 3.76:1 |
| Appearance | `#9864c8` | 4.21:1 |
| Results | `#147fa3` | 4.57:1 |

These are measured glyph/background ratios, not a claim about complete WCAG compliance or an Apple-mandated palette.

## Tests and capture evidence

`previewArt04Capture` exercises real menu clicks A/A/B/B/A and exclusivity; real clicks on all six sidebar rows in both styles; Return activation; Escape menu dismissal; Tab focus movement; and Resources grid/list arrow navigation with B. It asserts unchanged CONFIG export, backend revision, Ammo value and retained ART01–03 choices, then creates a fresh QML engine and checks A reset.

The helper writes only to a newly created unique `build/art04/` directory, builds the test executable, captures actual `QQuickWindow::grabWindow()` pixels and records source/tree/dirty-state/patch, binary/source/PNG SHA256, Qt version, theme/DPR, actual inspected value, selected section/resource, focus, scroll positions and icon/row/label/editor/sidebar rectangles. The final stable development run produced 28 PNGs: both themes, Geometry and Resources at 1440×900/DPR1 and DPR1.5, plus Geometry minimum 900×540, 125% text and keyboard-focus states at DPR1.

Every A/B pair asserts equal row/label/icon/editor/scroll geometry and exact rendered image equality outside the six badge rectangles. Initial strict pixel checking detected transient existing scrollbar fades; waiting for navigation scrollbars to settle resolved that capture timing issue without changing production behavior.

Optional `--baseline-dir build/art03-review/83be9ad/captures` supplied the accepted ART03 original screenshots. Both themes passed exact current-A versus accepted-A pixel comparison of the sidebar region `(0,62,210,390)`, covering all six glyphs, labels and selection. Historical baseline PNG hashes are recorded in the manifest. This proves the retained A sidebar rather than comparing A to its own implementation.

Executed with `/workspace/.obsidian-env/activate.sh` sourced:

```text
./scripts/dev/build-linux.sh
  PASS, exit 0 (local Qt 6.8.2).
python3 scripts/dev/check-art04.py --baseline-dir build/art03-review/83be9ad/captures
  PASS, exit 0; 28 asserted screenshots, four theme/DPR runs.
QT_QUICK_BACKEND=software xvfb-run -a ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
  PASS, exit 0; 1/1 qt-core test, 43.59 seconds.
  Log: build/qt/Testing/Temporary/LastTest.log.
git diff --check
  PASS, exit 0.
```

Personally opened official cached Settings Sequoia and Tahoe images before implementation, plus accepted ART03 light original. Personally inspected the finished development run's normal Resources A/B in both themes, normal Geometry B in both themes, minimum light B, large-text dark B and focused dark B. The selected-row fill and focus outline remain visually distinct, all six glyphs are visible, the long first label stays in its original position and badges do not touch text. These are builder observations, not independent visual approval.

Official image sources inspected: [Settings Sequoia](https://help.apple.com/assets/67D1B1065D0706C4AD080C54/67D1B10E5D0706C4AD080C79/en_US/9d447c4b1ecc39663a72d63e67093be5.png), [Settings Tahoe](https://help.apple.com/assets/69DD569682238CF8EC0621E2/69DD569982238CF8EC0621E9/en_US/1a55c8ea0fef87ffd5215a0ef88a615c.png). Project proportions are implementation choices, not prescribed Apple measurements.

## Recommendation

Ready for coordinator commit, clean-commit Functional Tester recapture, independent Visual Critic / Art Director comparison and bounded accessibility review. B remains experimental; final A/B choice belongs to the user. Native platform/screen-reader behavior and Qt 6.4 runtime execution are not established by this local Qt 6.8.2 development run. Broad Studio/Preview smoke and clean-commit evidence remain assigned to the independent tester.
