# ART-05 C adoption — implementation handoff

- Base commit: `5c8ea609b521fbaa533ee525f48bcf7a23615e13`, uncommitted Stage 1 patch.
- Agent: UI Builder; date: 2026-11-07.
- Environment: Linux, Qt 6.8.2, Fusion, software renderer, Xvfb/xcb, DPR 1 and 1.5.
- Scope: selected level-size C capsule default and dark body/edge only. ART-06 production work has not started.
- Evidence: `build/art05-c/manifest.json`, `working-tree.patch`, 48 original PNGs and state records under the four theme/DPR directories.

The launch and fresh-window default is now `capsule`. Its dark fill is opaque
`#55555e`; its dark edge is `#92929c`. Light C is unchanged. A/B/D, other numeric
controls, 9×21 visual geometry, 15px wrapper, native extended hit testing, separate
blue focus ring, disabled opacity, track, input, modes and CONFIG behavior retain
their existing implementation. No global token changes were made.

The existing ART05 QtTest updates only the two default expectations and adds a
bounded dark-C assertion: opaque, dark, low-saturation fill and nominal outline
and focus contrast at least 3:1 against the actual row color. At `#2a2a2e`, the
edge contrast is approximately 4.64:1 and focus is 5.44:1. These are project
checks, not Apple palette or size requirements. Disabled opacity remains 0.4;
the normal nominal contrast target does not claim disabled 3:1 contrast.

## Checks executed

```text
source /workspace/.obsidian-env/activate.sh && ./scripts/dev/build-linux.sh
  exit 0; build/art05-c/developer-build.log
source /workspace/.obsidian-env/activate.sh && QT_QUICK_BACKEND=software xvfb-run -a ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
  exit 0; 1/1 passed (57.55 seconds); build/art05-c/developer-core.log
source /workspace/.obsidian-env/activate.sh && python3 scripts/dev/check-art05.py --out build/art05-c
  exit 0; 20 light + 20 dark DPR1, 4 light + 4 dark DPR1.5
  build/art05-c/developer-capture.log
```

The unchanged helper records source hashes, binary hashes, source commit/tree,
working-tree patch and per-image hashes. Source hashes remained stable through
capture. Existing assertions continue to cover actual native drag and visible
edges, keyboard/value modes, disabled noninteraction, exact input, CONFIG,
exclusive choices, other controls and geometry/pixels outside the handle region.

## Historical and visual evidence

Compared actual `normal-capsule.png` with
`build/art05-review/3dd5fa3/captures/{light,dark}-paired-dpr1/`:

- Light: entire frame, including level-size row, is exactly pixel-identical.
- Dark: full-frame difference bounds `(887,319)-(896,340)` lie entirely inside
  the C handle visual bounds; the rest of the image is exact.
- Recorded mechanical result: `build/art05-c/historical-c-pixels.json`.

Personally inspected the actual dark normal full frame, and light/dark C normal,
focus, disabled and 125% text crops in `build/art05-c/c-state-contact.png`, plus
both DPR1.5 normal crops in `c-hidpi-contact.png`. The dark capsule is visibly
darker than the former white body, with a gray outline; the separate blue focus
ring remains clear, and disabled C is visibly dimmer while still discernible.
The original PNGs are the evidence; contact sheets are viewing aids only.

Recommendation: ready for coordinator commit and independent Functional Tester,
Visual Critic and Accessibility Critic gates. This builder handoff does not grant
independent visual approval or authorize starting ART-06 before those gates pass.
