# Art direction — optional visual improvement track

**Purpose:** improve aesthetic quality and identity beyond the minimum needed to pass a defect-oriented QA gate. A `visual_critic` PASS is not a claim of perfection; it also must not be reclassified as a FAIL merely because the art director can imagine a better direction.

## Inputs
- Current-commit **real** screenshots from `--design-preview`, including light/dark, narrow window and text zoom whenever relevant.
- User-approved preferences for Obsidian (compact productive Qt editor, macOS-inspired hierarchy without cloning macOS).
- [Apple reference catalog](references/apple/README.md), official HIG and any legitimately usable visual examples.
- Existing app constraints and known validated behavior in [WORKFLOW](WORKFLOW.md).

## Review lens
Explore: optical hierarchy, negative space, density, alignment, role-sensitive typography, understated surfaces, semantic color, recognizability, icon rhythm and meaningful motion. Evaluate fit to the task of creating Doom maps, not just similarity to Finder/System Settings. State where a proposal would *harm* discoverability, native platform expectations, contrast, performance or keyboard accessibility.

## Output (max 3 optional proposals)
For each:
1. **Opportunity ID** `ART-01`, screen and screenshot evidence (current commit + state).
2. **Observed limitation** as a subjective opportunity (not a software defect), plus official visual inspiration URL.
3. **Proposed visual change** with an actionable scope and acceptance criterion; optionally alternative A/B.
4. **Expected improvement** to hierarchy/usability/brand and **risks/tradeoffs**.
5. **Estimated work** (small/medium/large) and confidence level.
6. **Decision status**: `PROPOSED` / `APPROVED_BY_OWNER` / `REJECTED` / `DEFERRED`. Default is PROPOSED. Only the owner/user may authorize implementation.

Include an explicit **"no worthwhile change"** outcome when appropriate. Do not invent gaps to justify the role. A pass requires the art director actually viewed current images; absence of images yields UNVERIFIED visual observations, not imagined criticism.

## Implementation contract
- Read-only art director returns suggestions to coordinator, not direct builder tasks.
- Coordinator asks for/receives explicit user approval per proposal. No silent opt-in.
- UI builder implements ONLY the approved scope, usually medium effort, with before/after capture and bounded Qt checks.
- Independent visual and functional reviewers verify the changed commit and compare against the chosen target.
- Stop after 3 correction loops and return aesthetic choices to owner.

Template: [ART_DIRECTION_TEMPLATE.md](reports/ART_DIRECTION_TEMPLATE.md).
