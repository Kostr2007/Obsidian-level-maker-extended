# Apple-inspired design research and agent-driven QA

This is a **research-first and evidence-first** system for Obsidian Extended's Qt Quick/QML preview. It is not an Apple UI replica and does not contain redistributed Apple artwork.

## Read in order
1. [APPLE_RESEARCH.md](APPLE_RESEARCH.md) — official documentation map, design principles, what to investigate.
2. [references/apple/README.md](references/apple/README.md) — curated visual targets and their official source pages.
3. [references/obsidian/README.md](references/obsidian/README.md) — actual screenshots already captured from this project.
4. [REVIEW_CHECKLIST.md](REVIEW_CHECKLIST.md) — evidence standard and severity rules.
5. [reports/TEMPLATE.md](reports/TEMPLATE.md) — repeatable review format.
6. [WORKFLOW.md](WORKFLOW.md) — actor roles, *reasoning effort*, handoffs and test commands.
7. [ART_DIRECTION.md](ART_DIRECTION.md) — optional artistic improvement track that is separate from bug-finding QA.

## Deliverables / state
**Prepared:** Codex roles (including independent `art_director`), task contracts, research roadmap, source-backed external reference catalog, cross-linked local Obsidian screenshot baselines, review template and setup validator. `medium` / `high` settings are **reasoning-effort levels**, not model selection. Art direction can propose improvements after QA PASS but must receive user approval before `ui_builder` implements aesthetic changes.
**Baseline audited (2026-11-06):** five concrete official macOS app images inspected,
17 source entries cataloged, and independent functional, visual and keyboard reviews
completed at `81cbc4f`. See the [prioritized plan and reports](reports/2026-11-06-plan.md).
The inspected design was accepted. The confirmed game-dialog screenshot evidence gap
was corrected in `c363ac1` and independently passed functional and visual review in
light/dark/HiDPI. See the [result and acceptance evidence](reports/2026-11-06-result.md).

**Not yet done:** exhaustive study of *every* Apple HIG article, redistribution-approved
local macOS screenshots, native platform/screen-reader coverage, and effective runtime
reasoning introspection. These are not implied by the baseline acceptance.

No Apple-owned screenshot, UI kit, SF font or symbol has been copied into the repo. External pages serve as visual sources; approved assets can be added later with license/source metadata.

## First run
From repository root:
```sh
python3 scripts/dev/check-design-agent-setup.py
codex
```
Ask the coordinator:
> Read AGENTS.md and docs/design-system/WORKFLOW.md. First delegate the official-Apple research and catalog verification to apple_researcher. Then commission a baseline, read-only visual_critic audit of the existing design-preview with the currently captured screenshots. Have functional_tester validate the existing app and report actual results. Do not change code until evidence-based issues are prioritized. Start with typography, layout and navigation; ask ui_builder to fix only the highest-impact agreed issue. Capture new screenshots and re-review.

Codex's exact features and selected reasoning levels depend on the running client/model. `model_reasoning_effort` specifies the **requested** effort per agent, not the selected model and not proof of actual runtime effort. Check the effective role configuration when available; otherwise report UNVERIFIED.

To request ideas after QA accepts a design, ask: *"Start a read-only art_direction pass with art_director (high effort). Give me three optional, evidence-backed visual improvements and do not implement any without my approval."*
