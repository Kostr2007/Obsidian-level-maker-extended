# Repeatable screenshot and functionality review

Every PASS requires a **current commit** and matching artifact. Findings must include screenshot filename/link, region, objective symptom, principle/source URL and measurable or observable success criterion.

| Area | What reviewers inspect |
|---|---|
| Typographic hierarchy | heading vs navigation vs values vs captions; legibility, Inter Text/Display optical roles; clipping |
| Layout | sidebar/content/inspector boundaries, density, row alignment, consistent grouping, narrow/HiDPI |
| Controls | consistent radius, stroke, height, pressed/hover/disabled/focus, combo popup, error feedback |
| Color | semantic role, light/dark readability, selection not conveyed by color only |
| Interaction | keyboard-only path, focus order, shortcuts, popup dismiss, selection persistence, reduced motion |
| Animation | continuity, duration, no interruptions or stale transition states, reduced-motion behavior |
| Product correctness | actual data bound to settings, correct game/port visibility, CONFIG, generation, cancellation |
| Media/assets | gameplay sprites not mislabeled; pixel-art integrity; licensing and origin documented |

## Verdict
- PASS — verified and consistent with project standard.
- PARTIAL — meaningful progress, measurable remaining gap.
- FAIL — real bug/major contradiction with evidence.
- N/A — not relevant to this screen.
- UNVERIFIED — no adequate screenshot/runtime/source evidence.

Severity: **P0** unusable, data loss or broken critical workflow; **P1** accessibility, navigation or prominent visual consistency; **P2** polish/detail. Avoid ungrounded numerical scores and invented Apple HIG pixel requirements.

Report only top 5 distinct findings. If all pass, say so and do not manufacture improvements. Screenshots are evidence, not an excuse to copy Apple's exact assets.
