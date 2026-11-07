# Agent workflow and reasoning budget

The coordinator is the primary Codex thread; the roles live in `.codex/config.toml` and `.codex/agents/*.toml`.

| Role | Requested reasoning | Ownership / permission |
|---|---|---|
| Coordinator | high (set in current Codex session) | Prioritize, integrate evidence, decide approval |
| apple_researcher | high | Official docs/references only; no production QML edits |
| art_director | high | Seek artistic improvement opportunities even when QA passes; read-only, needs owner approval |
| ui_builder | medium | Scoped production QML implementation |
| visual_critic | high | Independent visual PASS/FAIL and screenshot comparison, read-only |
| functional_tester | medium | Run builds, smoke and regression tests, report actual logs |
| accessibility_critic | medium | Keyboard, zoom, contrast, reduced motion, read-only |

**The labels high/medium/xhigh/ultra mean reasoning effort, NOT model names.** `model_reasoning_effort` in each agent TOML requests that cognitive budget for that role without selecting a different model. `agents.default_subagent_reasoning_effort` is a fallback for unspecified subagents. Explicit spawn settings and role settings have precedence per the Codex runtime; always distinguish requested from observed effort. Do not assert actual runtime level when introspection is unavailable (UNVERIFIED). See https://developers.openai.com/codex/multi-agent and https://developers.openai.com/codex/config-reference.

Use xhigh only when the coordinator must resolve architectural conflicts or difficult regressions; ultra only for exceptional research/architecture if the client/model supports it. The coordinator's own effort belongs to its current session; the role table does not change it.

## Two independent tracks

1. **Quality gate (mandatory for changed UI):** `visual_critic` validates against accepted requirements; `functional_tester` verifies behavior. PASS means no proven defect in inspected states, not that the design cannot be improved.
2. **Art direction (optional and distinct):** `art_director` produces up to three high-impact proposals, even after PASS. It does not label good UI as broken, and it does not edit code. The coordinator forwards proposals to the **user/owner for explicit approval**. Only approved proposals are passed to `ui_builder` and then receive normal QA.

See [ART_DIRECTION.md](ART_DIRECTION.md) for the decision format. Neither a research report nor an art-direction suggestion is itself permission to redesign.

## Loop (max 3 iterations per scoped finding)
1. Researcher maps relevant official guidance and source-linked screenshots (one-time or cached; not every iteration).
2. Coordinator defines **one** specific problem OR one **owner-approved** art-direction proposal, exact screen/state/size, acceptance criteria and baseline.
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
