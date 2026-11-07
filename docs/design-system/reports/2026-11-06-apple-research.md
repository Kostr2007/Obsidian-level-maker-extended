# Apple/macOS design research

- Commit: `81cbc4f` (research baseline; documentation edits uncommitted)
- Agent: `apple_researcher`
- Date: `2026-11-06`
- Environment: Linux workspace; Python urllib HTTPS retrieval; `tools.view_image` for actual image inspection; no macOS runtime or browser
- Scope: official typography/layout/sidebar/toolbar/button/motion guidance and five concrete macOS app examples; no redesign or production edits
- Artifacts: [catalog](../references/apple/README.md), [provenance manifest](../references/apple/manifest.json); downloaded evidence only in `/tmp/apple-research-2026-11-06/`
- HIG sources: exact links below; substantive article text read from Apple's `/tutorials/data/design/human-interface-guidelines/<slug>.json` endpoint on `developer.apple.com`
- Reasoning effort: profile requests `high`; coordinator reports explicit spawn request `high` accepted. Effective runtime setting **UNVERIFIED**: no observable runtime evidence supplied. Profile/request is not proof of execution setting.

Five images were opened and inspected: `finder.png`, `settings.png`, `preview.png`, `notes.png`, `textedit.png` in the artifact directory above. The manifest records their exact Apple Support page URLs and asset URLs, SHA-256, image locator, visible observations, context, confidence and limits. Finder and Settings demonstrate different valid selection treatments; Notes provides a productivity inspector; Preview and TextEdit show actual transient/control states. Do not treat one app's styling as an Apple-wide requirement.

## Sourced evidence

All retrieval dates are `2026-11-06`. **Official guidance** is paraphrased in the second column; the last column is **project interpretation**, not an Apple specification. Confidence is high for text/visible observations, moderate for macOS-generation association, and unverified for runtime behavior.

| Source actually read | Official guidance / macOS relevance | Closest viewed example | Qt applicability and reviewer question |
|---|---|---|---|
| [Typography](https://developer.apple.com/design/human-interface-guidelines/typography) | Readable type; restrained typeface count; preserve relative hierarchy when text changes. macOS uses SF Pro but explicitly does not support Dynamic Type. Optical sizing is explained; custom fonts must remain legible. | MAC-13 Finder labels vs group headings; MAC-14 Settings headings vs descriptions; MAC-15 title/status | Use licensed project fonts and meaningful roles; do not redistribute SF or port iOS Dynamic Type tables to desktop. Does actual large-text capture preserve hierarchy without overlap? |
| [Layout](https://developer.apple.com/design/human-interface-guidelines/layout) | Align elements to aid scanning; indentation expresses hierarchy; group related functions; test smallest/largest layouts. Some size-class examples concern iOS/iPadOS. | MAC-14 aligned label/value groups; MAC-16 note/inspector separation | Review coherent columns and grouping at supported Qt sizes; exact panel widths/margins remain project choices. Does the minimum window preserve access to all settings? |
| [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) | Comfortable desktop information density; less nesting/modality on large displays; resizable windows, keyboard commands and precision input. Retrieved change history mentions touch guidance added October 28, 2026. | MAC-13 Finder; MAC-16 Notes desktop window | Keep Qt desktop affordances and platform conventions. Does the interface support sustained keyboard/pointer work? No real Mac runtime was tested. |
| [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars) | Succinct group labels; generally at most two hierarchy levels; allow hiding; familiar symbols. macOS sidebar row/text/glyph sizes depend on sidebar size; avoid critical actions at the bottom. | MAC-13 neutral selected row; MAC-14 blue selection with icon/text | Clear selected item and content relationship, with discoverable navigation. Does selection stay identifiable without relying only on hue? Fixed icon colors can be contextual; no mandate to copy Settings colors. |
| [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) | Deliberate items, logical function/frequency grouping, recognizable commands; support narrower windows and overflow. Native macOS manages overflow; native framework instructions are not directly executable in Qt. | MAC-13 grouped navigation/view/actions; MAC-15 compact toolbar; MAC-16 mostly monochrome commands | Reserve strong emphasis for the main project action; preserve command access at narrow sizes. Is each visible action clear? Icon-only Apple examples do not prove that unfamiliar editor actions should lose labels. |
| [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) | Custom buttons need press feedback; clear labels; distinguish preferred choice with style rather than different size. macOS hover tooltips explain controls; flexible-height push buttons are for tall/variable content. | MAC-17 matched Cancel/Save, focus ring and popup selection/checkmark; MAC-15 active/inactive controls | Verify focus/press/disabled states separately. General 44-point hit-region guidance must not be represented as a mandatory 44-pixel visible Qt desktop button height. Does keyboard focus remain visible in runtime? |
| [Motion](https://developer.apple.com/design/human-interface-guidelines/motion) | Purposeful, brief, optional feedback; avoid gratuitous animation in frequent interactions; allow cancellation. No additional macOS-specific considerations. | No Apple motion artifact inspected; five screenshots are static | Review project animations and reduced-motion behavior independently. Timing, easing and motion equivalence remain UNVERIFIED; no duration is prescribed here. |

## Research findings and review handoff

| ID | Severity | Area/state | Verdict | Evidence | Apple/project principle | Reproduction + acceptance criterion |
|---|---|---|---|---|---|---|
| RES-01 | P2 | Typography and text zoom | UNVERIFIED | Typography text; MAC-13/14/15 actually viewed | Official hierarchy and legibility; project font/size choices | Critic inspects fresh default/large-text captures; labels, values and headings remain distinct, readable and nonoverlapping. No pixel prescription. |
| RES-02 | P2 | Layout/navigation | UNVERIFIED | Layout/sidebars text; MAC-13/14/16 | Official grouping/alignment; project content/inspector hierarchy | Inspect fresh wide/minimum-window captures; selected navigation corresponds to content, related rows align, and narrow layout retains access. Finder itself elides names; elision alone is not a failure. |
| RES-03 | P2 | Toolbar command hierarchy | UNVERIFIED | Toolbars text; MAC-13/15/16 | Official functional grouping and clear commands | Inspect current command row/menu and narrow state; commands remain identifiable and reachable; primary-action emphasis is restrained. |
| RES-04 | P2 | Buttons, popup, focus and inactive states | UNVERIFIED | Buttons text; MAC-15/17 | Official feedback/roles; project keyboard implementation | Independent runtime audit activates controls by keyboard/pointer; focus, selected item and disabled state are distinguishable. Static references cannot establish keyboard traversal or press transitions. |
| RES-05 | P2 | Motion/reduced motion | UNVERIFIED | Motion article only; no Apple moving example viewed | Official purposeful, optional and cancellable motion | Independently inspect current animation and reduced-motion paths. Navigation must remain usable while transitions run and when animation is reduced. |

These are bounded review questions, **not confirmed defects** or required redesigns. No current Obsidian screenshot was inspected by this researcher; UI conformity is intentionally left to the independent critic. The visual critic received all five exact artifact paths plus source links and article payload paths while research completed.

## Provenance and limits

Support page metadata associates the five pages with **macOS 27 Golden Gate**; this identifies guide context, not the assets' exact OS build or screenshot date. Some images may be reused across guide editions. Preview document lettering and TextEdit document formatting are content, not interface font recommendations. Notes is a scaled desktop image, unsuitable for direct size measurement. The research did not measure actual fonts, pixel values, contrast ratios, or native-scale dimensions. Liquid Glass-specific 2025/2026 guidance is contextual; it does not authorize unnecessary blur/material imitation in a Linux/Windows editor.

All Apple imagery is **link-only** in tracked files. `/tmp` artifacts are session evidence, not redistributed repository assets. Rights to redistribute remain unverified. Roadmap entries MAC-01–12 remain intact; previously unreviewed entries are explicitly distinguished from observed examples MAC-13–17. Color/windows and discovery pages returned HTTP 200 but were not substantively reviewed. Direct relative HIG Notes image URLs returned 404; those images were not inspected. Existing local catalog links all resolved; no repair was required.

## Tests executed

```text
Python urllib retrieval: exit 0; seven substantive HIG DocC payloads + official Support pages/assets fetched HTTP 200.
Image inspection: tools.view_image opened finder.png, settings.png, preview.png, notes.png, textedit.png successfully.
Manifest parsing and local Markdown-link validation: exit 0; 17 entries, 5 inspected assets, all local catalog links resolve.
python3 scripts/dev/check-design-agent-setup.py: exit 0; PASS, 5 roles and 17 reference entries (not runtime or visual verification).
Production builds/runtime tests: N/A for this documentation-only research; delegated baseline execution is reported separately.
```

## Recommendation

`UNVERIFIED` for current UI quality. Research evidence is ready for independent baseline review; there is no research-backed production change to authorize from this report alone.

## Handoff to builder

No implementation task assigned. Wait for independent current-screenshot findings; do not copy Apple artwork, proprietary fonts, exact component dimensions or unverified animation behavior. A critic can accept the current design with no changes.
