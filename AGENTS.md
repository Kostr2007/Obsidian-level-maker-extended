# Obsidian Extended — instructions for Codex

Read `docs/design-system/README.md` before any visual/design task. This repository has a real Qt Quick/QML studio and a separate `--design-preview` experiment; never confuse them.

## Non-negotiable boundaries
- Keep C++/Lua level generation, gameplay semantics, schema IDs, CONFIG round-trip and existing user presets unchanged unless specifically tasked.
- Only `ui_builder` changes production QML for design work; auditors and art director give findings/proposals and evidence, not self-approved edits.
- Artistic opportunities are NOT visual QA defects. A user/owner must approve a specific proposal before the builder changes production QML for aesthetic reasons.
- Use official Apple HIG as *guidance*, never assert a project-specific pixel value is prescribed by Apple.
- Never claim visual PASS without a real screenshot of the current commit. An image description or old screenshot is not proof.
- Never ship proprietary Apple UI kit screenshots, fonts, logos or SF Symbols as repo assets without verified redistribution rights. External source links are welcome.
- Don't fabricate tool runs, screenshots, measurements or passing tests. Record unavailable checks as UNVERIFIED.

## Team workflow
1. Delegate bounded research to `apple_researcher` (high) when needed; reuse its findings for subsequent changes.
2. On an optional art-direction track, ask `art_director` (high reasoning effort) to identify **improvement opportunities even when the existing design passes QA**. Use `docs/design-system/ART_DIRECTION.md` and submit options for user/owner approval; no changes are authorized merely by the art director's proposal.
3. Give `ui_builder` (medium reasoning effort) one confirmed bug or **user-approved** visual proposal, requirements and acceptance criteria.
4. After the change, run `functional_tester` (medium), separately run `visual_critic` (high), and use `accessibility_critic` (medium) for interactive or layout changes.
5. Reviewer(s) compare against Apple reference catalog AND Obsidian baseline screenshots; developer receives evidence-based FAIL/PARTIAL findings.
6. Iterate at most 3 rounds for a scope; escalate unresolved ambiguity to the user, not an endless redesign.
7. Fix functional regressions before purely visual polish. A critic must be permitted to say PASS/no change needed.

Read `docs/design-system/REVIEW_CHECKLIST.md` and write each review using `docs/design-system/reports/TEMPLATE.md`.
Use the existing `scripts/dev/check-design-preview.py`, `scripts/dev/check-qt.py`, and Qt core tests. The independent critic must not edit source files.

## Evidence and cost
- Prefer mechanical scripts/tests for deterministic checks; reserve vision inspection for composition, hierarchy and visual defects.
- Don't launch every agent on trivial changes. Keep research/audits focused on the diff, not all ~6k repository files.
- `medium`, `high`, `xhigh` and `ultra` denote **reasoning effort**, not model selection. The Codex profile key is `model_reasoning_effort`; no specific model is forced. Profiles express requested effort; verify effective child runtime settings when introspection is available, otherwise mark UNVERIFIED. Parent's selected Ultra effort does not automatically imply Ultra for specialized agents with explicit efforts.
