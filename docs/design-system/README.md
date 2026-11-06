# Apple-inspired design research and agent-driven QA

This is a **research-first and evidence-first** system for Obsidian Extended's Qt Quick/QML preview. It is not an Apple UI replica and does not contain redistributed Apple artwork.

## Read in order
1. [APPLE_RESEARCH.md](APPLE_RESEARCH.md) — official documentation map, design principles, what to investigate.
2. [references/apple/README.md](references/apple/README.md) — curated visual targets and their official source pages.
3. [references/obsidian/README.md](references/obsidian/README.md) — actual screenshots already captured from this project.
4. [REVIEW_CHECKLIST.md](REVIEW_CHECKLIST.md) — evidence standard and severity rules.
5. [reports/TEMPLATE.md](reports/TEMPLATE.md) — repeatable review format.
6. [WORKFLOW.md](WORKFLOW.md) — actor roles, effort, handoffs and test commands.

## Deliverables / state
**Prepared:** Codex roles, task contracts, research roadmap, source-backed external reference catalog, cross-linked local Obsidian screenshot baselines, review template and setup validator.
**Not yet done:** exhaustive study of *every* Apple HIG article, redistribution-approved local macOS screenshots, actual new design audits or functional test results from the agent team. These must be performed in a Codex session with repository execution and screen/image access.

No Apple-owned screenshot, UI kit, SF font or symbol has been copied into the repo. External pages serve as visual sources; approved assets can be added later with license/source metadata.

## First run
From repository root:
```sh
python3 scripts/dev/check-design-agent-setup.py
codex
```
Ask the coordinator:
> Read AGENTS.md and docs/design-system/WORKFLOW.md. First delegate the official-Apple research and catalog verification to apple_researcher. Then commission a baseline, read-only visual_critic audit of the existing design-preview with the currently captured screenshots. Have functional_tester validate the existing app and report actual results. Do not change code until evidence-based issues are prioritized. Start with typography, layout and navigation; ask ui_builder to fix only the highest-impact agreed issue. Capture new screenshots and re-review.

Codex's exact features and selected reasoning levels depend on the running client/model. Check the effective role configuration rather than inferring it from the files.
