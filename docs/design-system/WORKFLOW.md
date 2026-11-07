# Agent workflow and reasoning budget

The coordinator is the primary Codex thread; the roles live in `.codex/config.toml` and `.codex/agents/*.toml`.

| Role | Requested reasoning | Ownership / permission |
|---|---|---|
| Coordinator | ultra (requested in project config; current session setting remains client-controlled) | Prioritize, integrate evidence, decide approval |
| apple_researcher | high | Official docs/references only; no production QML edits |
| ui_builder | medium | Scoped production QML implementation |
| visual_critic | high | Independent visual PASS/FAIL and screenshot comparison, read-only |
| art_director | high | Independent artistic proposals and A/B preferences, read-only |
| functional_tester | medium | Run builds, smoke and regression tests, report actual logs |
| accessibility_critic | medium | Keyboard, zoom, contrast, reduced motion, read-only |

These are reasoning levels, not model names. Store them in `model_reasoning_effort`
and explicitly pass each child's `reasoning_effort` when launching it. A coordinator
requesting ultra does not change the assigned medium/high of its specialists.
Keep the inherited model unless the user separately requests another model.
The shared [runtime observability note](reports/2026-11-06-agent-runtime.md)
documents the environment limitation once; ordinary reports need not repeat it.

## Four-option artistic comparisons

User preference, 2026-11-07: new artistic experiments present **four** options,
not a fixed two-option comparison. Use A as the current component/control and
B/C/D as three distinct, scoped alternatives. Keep all previous accepted choices
fixed; for ART-05 these are ART-01 A, ART-02 A, ART-03 A and ART-04 B.
For ART-06, also retain the accepted ART-05 C with its verified dark fill.

- Define the visual hypothesis, reference, expected benefit and cost for each
  alternative before implementation. Do not manufacture three unrelated redesigns.
- Expose A/B/C/D with an exclusive session-local control. Keep the current
  component as the launch default until the user selects its replacement.
- Capture all four in light/dark at identical data, window/DPR, text scale, focus,
  scroll and state. Include the changed component's relevant disabled/focus states.
  Compare B/C/D to A for deterministic invariants; six pairwise pixel audits are
  unnecessary when each alternative passes the same baseline contract.
- Visual Critic independently gives a verdict and tradeoffs for **each** option;
  Art Director independently ranks the acceptable options with reasons. Neither
  reviewer must pick a new design, or accept a broken option merely to keep four.
- Functional/accessibility gates cover all four. Repair confirmed regressions,
  then repeat affected gates on current source before presentation. Separate
  aesthetic preference from a failure requiring a fix.
- Present a four-up comparison, optional pair/solo views, original PNGs and
  independent reports to the user. Record the choice and make it the accepted
  baseline for later work. Historical A/B reports remain historical evidence.

Routine bug fixes are validated fixes, not new artistic competitions.

## Loop (max 3 iterations per scoped finding)
1. Researcher maps relevant official guidance and source-linked screenshots (one-time or cached; not every iteration).
2. Coordinator defines **one** specific problem, exact screen/state/size, acceptance criteria and baseline.
3. Builder edits limited QML, builds, captures identical screenshots at changed commit.
4. Functional tester checks runtime, logging, persistence and tests. If FAIL, fix before styling.
5. Visual critic inspects actual current screenshot + historical baseline + linked Apple/macOS reference, with 1–5 actionable issues.
6. Accessibility critic checks semantic interaction when applicable.
7. Coordinator accepts when all P0/P1 items pass, documents P2 deviations or escalates after three loops.

Run functional and visual reviews independently whenever possible. Sharing a worktree risks concurrent writes; reviewers should use read-only checkouts or detached worktrees at the same commit. Only builder changes production sources. Do not assume running multiple sessions automatically coordinates agents.

## Screenshot contract
Capture matching scene, window size, platform, DPI/scale, theme, selected nav item, inspector visibility and font zoom. Use `python3 scripts/dev/check-design-preview.py` as existing capture/test harness; output is in `build/design-preview-check/`. Do not mistake committed older images for current-commit proof. Label changes by commit SHA and environment. Compare screenshot pixels for layout regression with human/vision review for subjective hierarchy; never use raw pixel diff as a universal design score.

## Mandatory tests (if tools/environment available)
```sh
python3 scripts/dev/check-design-agent-setup.py
./scripts/dev/build-linux.sh
QT_QUICK_BACKEND=software ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
python3 scripts/dev/check-qt.py
python3 scripts/dev/check-design-preview.py
```
Also check actual generation WAD and CONFIG where impacted. Report SKIP/UNVERIFIED when dependencies or GUI cannot run; never claim tests pass from document text alone.

## Stop conditions
- 3 iteration rounds with unresolved aesthetic disagreement; human decision.
- Current screenshots unavailable; mark visual review UNVERIFIED.
- Core Qt test failures; block merging until triaged.
- External screenshot licensing unknown; keep link only.
