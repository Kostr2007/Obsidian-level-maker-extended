# ART-01 owner decision — 2026-11-07

- Branch reviewed: `codex/art-01-resource-selection`, starting at `41b5d1646479441a99d844e18988f98a47aff80f`.
- User choice: **A / classic** is the final preferred default for the resource selection styling.
- B: keep available as an experimental opt-in A/B alternative only; do not promote it to default without explicit owner approval.
- Implementation: `source_files/qt_frontend/prototype/Preview.qml` already initializes `resourceSelectionStyle: "classic"`, and `ResourceGallery.qml` already maps classic to the blue selected-title treatment. **No production UI change is required for this decision**.
- Reviewer opinions were advisory: Visual Critic favored A for clarity of selected vs hover; Art Director favored B for a calmer composition. The owner selected A based on their own visual judgment.
- Related Apple image: Finder screenshot at `support.apple.com/guide/mac-help/...` is an official Apple Support product example, not an external forum and not a normative HIG specification. Future agent proposals must source their design principles primarily from `developer.apple.com/design/`.
- Evidence: user-supplied A/B report and existing repository docs; this decision log does not claim a fresh Qt test or new screenshot review.
- Other proposals ART-02/ART-03: not approved.
