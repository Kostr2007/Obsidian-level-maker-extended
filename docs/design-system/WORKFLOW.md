# Agent workflow and reasoning budget

The coordinator is the primary Codex thread; the roles live in `.codex/config.toml` and `.codex/agents/*.toml`.

## Source hierarchy (mandatory for design decisions)

1. **Authoritative guidance:** [Apple Design](https://developer.apple.com/design/) and the exact [HIG](https://developer.apple.com/design/human-interface-guidelines/) section relevant to the proposed UI behavior. Look at official illustrations on those pages first.
2. **Design demonstrations:** [Apple Design Resources](https://developer.apple.com/design/resources/) and [Apple design sessions](https://developer.apple.com/videos/design/) to understand component anatomy and reasoning, respecting reuse licensing.
3. **Official application examples:** [Apple Support user guides](https://support.apple.com/guide/mac-help/welcome/mac) show actual Finder/Settings/Notes UI, but do **not** establish mandatory styling rules. Support is Apple-owned, not a community forum.
4. **Third-party websites:** optional context only, with attribution and independent verification; never the sole authority for a macOS/HIG requirement.

Each art proposal / visual finding must include a separately identifiable `HIG source + relevant principle` and `visual screenshot source + what it shows`. If no corresponding HIG principle is found, label as **subjective art direction**, not as "required by Apple". Distinguish HIG requirements, Apple's app-specific choices and Obsidian's owner-approved preferences.

User's decision **ART-01 = A (classic) as main style** takes precedence over agent preferences for experimental B; the B experiment may remain accessible for comparison, not silently promoted.


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
