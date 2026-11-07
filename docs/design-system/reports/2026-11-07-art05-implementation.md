# ART-05 implementation handoff

- Base commit: `74d161b623f2761ad8d7d6f93f618320df60f213`; development evidence describes the working tree, **not a committed visual approval**.
- Agent: UI Builder; 2026-11-07.
- Environment: Linux, Qt 6.8.2, Fusion, Xvfb/xcb, software rendering, DPR 1 and 1.5. Implementation uses Qt 6.4-compatible QML; a Qt 6.4 runtime was not exercised here.
- Scope: only `ui_arch/float_size` numeric handle in `--design-preview`, plus the already accepted ART-04 B launch default.
- Artifacts: `build/art05/development-edge-fix-02/manifest.json`, four `states.json` files and **48 original PNGs**, with build/core/capture logs in that directory. Independent reviewers must capture the coordinator's resulting commit again.

## Implemented options

| Variant | Construction | Builder observation in current development captures | Review status |
| --- | --- | --- | --- |
| A / `original` | Original 15×15 neutral circle, radius 8, existing border/focus | Compact; normal row matches accepted baseline pixels in both themes | Independent review pending |
| B / `disc` | Opaque 19×19 light disc, neutral border | More conspicuous light surface in dark theme | Independent review pending |
| C / `capsule` | Opaque 9×21 vertical light capsule | Clearly distinct narrow silhouette | Independent review pending |
| D / `tile` | Accent 16×16 tile, radius 4 | Accent persists without focus; separate outline/gap distinguishes focus | Independent review pending |

All shapes are centered using exact arithmetic inside the retained 15×15 wrapper. Qt's default centered-anchor pixel rounding shifted even-sized D by half a logical pixel; explicit `(parent.width - width) / 2` and corresponding y remove that shift. Slider implicit geometry and movement formulas remain unchanged. B/C/D focus has a separate 2-unit accent outline and 2-unit gap painted with the actual row color; their disabled visual opacity is 0.4. A retains its existing disabled and focus rendering.

`window.levelSizeSliderStyle` defaults to `original`. The exclusive session-only menu entries are `levelSizeSliderOriginal`, `levelSizeSliderDisc`, `levelSizeSliderCapsule`, and `levelSizeSliderTile`. The option row exposes `sliderStyle`; every other row receives `original`. Slider, wrapper, visual, ring, track, exact field and existing mode control have stable object names. No backend debug API or CONFIG preference was added.

Accepted ART-01 `classic`, ART-02 `zebra`, ART-03 `original` remain fixed. ART-04 now launches as `badges`; its original/badges manual comparison remains available. The existing ART-04 test now expects badges on both initial and fresh launch, while its explicit original-A historical comparison is retained.

## Round 1: visible handle input containment

The independent functional preflight found a P1 defect before commit: B's visible upper/lower bands (y321/y338) and C's bands (y320/y339) lay outside the retained Slider rectangle y322..337. A 60px drag beginning there left the backend value at 36; a central drag changed it to 56. A's visible inside bands worked. Independent original-binary evidence is `build/art05-review/preflight/edge-probe-live/result.md` and its actual main-app screenshots.

The bounded repair adds a native Slider `containmentMask` implemented by a QtObject with the required `contains(point: point): bool` signature. It preserves the original control rectangle for every style and, only while enabled and B/C/D is selected, accepts the current handle visual's overflow bounds. It does not expand the focus ring. Native Slider retains all pointer/drag/value handling; there is no custom MouseArea or duplicated drag logic, no layout-size change, and no expansion while disabled.

The first implementation attempt used an untyped JavaScript method; Qt explicitly warned that it was not a native invokable contains method, and the new regression reproduced the disc upper-band failure at min10. The typed method corrected that test failure. Final logs contain no such warning.

The regression now injects real window mouse presses/moves/releases from upper, lower, left and right visible handle bands at min10/default36/max75 for **all four** styles. Each drag must change the actual backend value in the expected direction; min/max drags move inward. This includes B/C vertical overflow, B's horizontal overflow at extremes, and D's fractional lower/right bounds. All 48 enabled edge drags per run pass; 16 disabled edge drags per run preserve backend revision and nan value. All four theme/DPR runs execute these interactions before capturing.

Current evidence is the new unique `build/art05/development-edge-fix-02` directory. Earlier `build/art05/development-final` evidence is preserved unchanged. All 48 current original PNGs are **byte-identical** to their pre-fix counterparts; see current `visual-regression.json`. I personally re-opened all 48 current component crops in temporary light/dark contact sheets. This correction addresses input containment without a visual redesign.

## Evidence and deterministic checks

`previewArt05Capture` loads real production `Preview.qml` and captures `QQuickWindow::grabWindow()`. Its checks cover real menu clicks and repeated selections for all four exclusive entries; actual drag to minimum/midpoint/maximum with schema snap, exact drag endpoints, arrow increments, precise field entry, actual nan mode, disabled ignored input, and returning to numeric mode through the mode control. Current schema is min **10**, max **75**, step **1**, normal value **36**. Style-only switches preserve backend revision and exported CONFIG. A second numeric control (`ui_mons/float_mons`) remains original with D selected. Fresh QML launch restores A slider and B icons.

The 48 captures are matched across all four styles: normal/focus/disabled/minimum 900×540/text 125% in light/dark at DPR1 (40), plus normal light/dark at DPR1.5 (8). State JSON records actual value/mode/range/step/enabled/focus/revision, accepted styles, viewport/DPR/theme, editor and scroll geometry, and row/slider/wrapper/visual/ring/field/track rectangles. `comparisonRect` encloses the mode plus numeric control block; normal DPR1 is `[806,278,280,66]`.

For every scenario, B/C/D have identical row/slider/wrapper/field/track/editor/scroll geometry to A, and strict full-image pixel identity outside a bounded **32×34 logical unit** handle/focus exclusion. Actual min/mid/max focus bounds fit the row and every clipping ancestor. The optional baseline comparison verifies **only the complete level-size row**, `rowRect` `[238,270,864,82]` in normal DPR1, against accepted `f4ba69b` Geometry badges captures in both themes. It does not claim whole-window historical identity.

The manifest contains source/app/test/PNG SHA-256, Git state, patch hash and accepted baseline hashes; the runner rejects source changes during capture and requires exactly 48 states. Original PNGs are unmodified. I personally opened the eight normal light/dark development screenshots and focus/minimum/disabled/125% examples, then inspected all 48 final component crops in temporary contact sheets. This is an implementation sanity check, not independent artistic/accessibility approval.

Official visual sources personally opened before implementation were the cached [no tick marks](https://developer.apple.com/tutorials/images/com.apple.HIG/sliders-no-tick-marks@2x.png) and [text field](https://developer.apple.com/tutorials/images/com.apple.HIG/sliders-text-field@2x.png) illustrations, alongside accepted light/dark Geometry badges images. The [HIG Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders) interpretation and exact project brief are recorded in the concepts report. No Apple asset was added; project dimensions are not Apple pixel requirements.

## Tests executed

```text
source /workspace/.obsidian-env/activate.sh
./scripts/dev/build-linux.sh
PASS, exit 0; development-build.log

QT_QUICK_BACKEND=software xvfb-run -a ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
PASS, exit 0; 1/1 suite, 56.82 seconds; development-qt-core.log

python3 scripts/dev/check-art05.py --out build/art05/development-edge-fix-02 --baseline-dir build/art04-review/f4ba69b/captures
PASS, exit 0; 20 + 20 + 4 + 4 screenshots; development-capture.log

git diff --check
PASS, exit 0
```

Earlier disposable development runs identified test-only helper/decoded-image-format issues and the actual centered-anchor rounding issue described above. The current set also includes the independently requested Round 1 containment repair and was built and captured with unchanged source hashes throughout. No broader generation/backend behavior changed; full standard smoke gates belong to the independent functional handoff.

## Recommendation and handoff

Ready for the coordinator to commit and commission independent functional, visual, artistic and accessibility review. No variant is self-approved or selected. Source is frozen after passing build/core/48 stable captures; only this implementation report was written afterward. Final choice remains the user's.
