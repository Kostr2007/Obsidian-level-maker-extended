# ART-03 implementation handoff

- Agent: ui_builder; 2026-11-07; branch `codex/art-03-resource-inspector`, base `204dc3c`, uncommitted implementation.
- Environment: retained Qt 6.8.2, Xvfb/xcb, software renderer, DPR 1 and 1.5.
- Scope: selected Resources → `ui_pickups.ammo` inspector in `--design-preview`. No CONFIG/schema/preset, asset, font, Studio or gameplay changes.
- Artifacts: `build/art03/204dc3c-20261107T102111303323Z/manifest.json`, per-run `states.json`, `test.log`, paired original PNGs. Historical captures remain untouched. This is dirty-tree builder evidence; independent reviewers must recapture the committed source.
- Design source: approved option 3 in `build/art-direction/881ab88/art-director-proposals.md`. No additional HIG research or aesthetic approval is claimed.

The existing inspector stack uses a one-column GridLayout with explicit Qt 6.4-compatible row bindings. A preserves the existing visible-block order and 16 px spacing; B moves the existing divider and current-value labels directly after the description. Defaults and related text remain reachable below the gallery. No duplicate current-value component, proxy, cache or new action was introduced. The same inspectorContent serves inline and modal views.

AssetPreview adds `unifiedSurface: false`. A small wrapper keeps the stable two-column GridLayout at the available width and supplies B's common neutral backdrop; existing sprite image boxes, painted sizes, pixel settings and captions stay identical. The Studio/shared default remains the original separate tile surfaces.

The commands menu contains a separate exclusive pair: `Инспектор боеприпасов: A · Исходный` / `Инспектор боеприпасов: B · ART-03 (эксперимент)`. The session property defaults to `original`; Resources classic and Geometry zebra remain fixed in every ART-03 screenshot.

| Check | Result / evidence |
| --- | --- |
| Actual menu clicks A, A, B, B, A | PASS: exactly one ART-03 check, independent ART-01/02 A checks retained |
| Scope | PASS: Health/Items/Weapons and Geometry do not activate B; actual Heretic backend selection suppresses Freedoom examples; shared component defaults to false |
| Values / persistence | PASS: raw `normal` in both variants, live `more` update and restoration; exported CONFIG bytes identical across experiment; fresh window starts A |
| Ordering / original spacing | PASS: actual item scene positions assert A gallery before value / B value before gallery; all visible A stack gaps remain exactly 16 px |
| Sprites / editor | PASS: eight expected sources and captions; painted sizes, relative grid geometry, smooth=false/mipmap=false, editor card/row geometry match each pair |
| Scroll / visibility | PASS: B current value and gallery start visible at normal top; bottom reaches final captions, rights notice and default in inline and modal |
| Aesthetic / native accessibility | UNVERIFIED here; independent critics own these decisions |

## Executed commands

Every shell used `source /workspace/.obsidian-env/activate.sh`.

```text
qmlformat -i source_files/qt_frontend/AssetPreview.qml source_files/qt_frontend/prototype/Preview.qml
exit 0
python3 scripts/dev/check-art03.py
exit 0; build + 24 actual QQuickWindow.grabWindow screenshots, 4 passing QtTest capture processes
QT_QUICK_BACKEND=software xvfb-run -a ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
exit 0; see build/qt/Testing/Temporary/LastTest.log
source hash comparison against capture manifest
all source hashes match: True
git diff --check
exit 0
```

An initial capture attempt exposed a test-only resize/open timing race before the narrow dialog. The test now waits for `inlineInspector` to become false before opening the actual dialog. The successful fresh run above includes modal top and bottom. Early failed-run directories were retained separately and are not approval evidence.

## Capture matrix and metadata

At DPR 1, light/dark each contain `normal`, `large-text` (125%), `bottom`, `modal` (1050×640), and `modal-bottom`, each paired `-original.png` / `-priority.png`. At DPR 1.5, light/dark each contain the normal pair. Inline scenes use 1440×900. Total: 24 unaltered PNGs.

The manifest records commit/tree/dirty status, working patch hash, production/test/script/source-asset hashes, app/test binary hashes and per-PNG SHA-256. Each state records viewport, actual visible `inspectorRect` and DPR, dimensions/theme/experiment defaults, selected Ammo and raw value, focus/scroll location, block geometry, all eight sprites' source/painted dimensions/grid-relative coordinates and captions, notice/default text and rectangles, and editor card/row geometry. For modal states `inspectorRect` is the visible dialog background; otherwise it is the inline panel. Global gallery Y changes intentionally; intrinsic gallery and main editor geometry match the pair. The actual visible modal content root is used rather than the hidden inline Loader.

Ready for coordinator commit and independent functional, visual, artistic and accessibility review. No commit or push made by the builder; B has no final acceptance.
