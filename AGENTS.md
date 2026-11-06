# Obsidian Extended — instructions for Codex

Read `docs/design-system/README.md` before any visual/design task. This repository has a real Qt Quick/QML studio and a separate `--design-preview` experiment; never confuse them.

## Non-negotiable boundaries
- Keep C++/Lua level generation, gameplay semantics, schema IDs, CONFIG round-trip and existing user presets unchanged unless specifically tasked.
- Only `ui_builder` changes production QML for design work; auditors give findings and evidence, not self-approved edits.
- Use official Apple HIG as *guidance*, never assert a project-specific pixel value is prescribed by Apple.
- Never claim visual PASS without a real screenshot of the current commit. An image description or old screenshot is not proof.
- Never ship proprietary Apple UI kit screenshots, fonts, logos or SF Symbols as repo assets without verified redistribution rights. External source links are welcome.
- Don't fabricate tool runs, screenshots, measurements or passing tests. Record unavailable checks as UNVERIFIED.

## Team workflow
1. Delegate bounded research to `apple_researcher` (high) when needed; reuse its findings for subsequent changes.
2. Give `ui_builder` (medium) one narrowly scoped UI issue, requirements and acceptance criteria.
3. After the change, run `functional_tester` (medium), separately run `visual_critic` (high), and use `accessibility_critic` (medium) for interactive or layout changes.
4. Reviewer(s) compare against Apple reference catalog AND Obsidian baseline screenshots; developer receives evidence-based FAIL/PARTIAL findings.
5. Iterate at most 3 rounds for a scope; escalate unresolved ambiguity to the user, not an endless redesign.
6. Fix functional regressions before purely visual polish. A critic must be permitted to say PASS/no change needed.

Read `docs/design-system/REVIEW_CHECKLIST.md` and write each review using `docs/design-system/reports/TEMPLATE.md`.
Use the existing `scripts/dev/check-design-preview.py`, `scripts/dev/check-qt.py`, and Qt core tests. The independent critic must not edit source files.

## Evidence and cost
- Prefer mechanical scripts/tests for deterministic checks; reserve vision inspection for composition, hierarchy and visual defects.
- Don't launch every agent on trivial changes. Keep research/audits focused on the diff, not all ~6k repository files.
- Agent profile efforts are requested defaults; check effective child settings in Codex runtime because some surfaces inherit parent settings.
