# Apple design study — sourced research map

**Source precedence:** Apple Design/HIG (principles, official illustrations) → Apple Design Resources and Apple WWDC design sessions → official Apple Support application screenshots (visual examples only) → optional attributed third-party context. Apple Support is not a forum, but its screenshots are not normative HIG rules. Require an exact HIG citation for claimed Apple guidance; if none exists, mark the idea as subjective art direction.


Scope: desktop productivity/editor UI patterns **first** (macOS), broad Apple philosophy **second**. Do not mistake an iPhone-specific recommendation for a macOS requirement.

## Primary sources (official)
| Priority | Topic | Source | Question for Obsidian |
| --- | --- | --- | --- |
| P0 | Design hub | https://developer.apple.com/design/ | What Apple considers foundational vs ornamental |
| P0 | Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines/ | Cross-platform hierarchy and interaction guidelines |
| P0 | Designing for macOS | https://developer.apple.com/design/human-interface-guidelines/designing-for-macos | Desktop navigation and control density |
| P0 | Typography | https://developer.apple.com/design/human-interface-guidelines/typography | Optical sizes, semantic type roles, text zoom |
| P0 | Layout | https://developer.apple.com/design/human-interface-guidelines/layout | Flexible panels, margins, adaptive density |
| P0 | Color | https://developer.apple.com/design/human-interface-guidelines/color | Semantic contrast, state and meaning |
| P0 | Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility | Focus, perceivability, interaction |
| P0 | Sidebars | https://developer.apple.com/design/human-interface-guidelines/sidebars | Navigation vs inspector |
| P0 | Toolbars | https://developer.apple.com/design/human-interface-guidelines/toolbars | Commands vs content |
| P1 | Buttons | https://developer.apple.com/design/human-interface-guidelines/buttons | Hierarchy and states |
| P1 | Windows | https://developer.apple.com/design/human-interface-guidelines/windows | Sizing and layout behavior |
| P1 | Motion | https://developer.apple.com/design/human-interface-guidelines/motion | Subtle feedback, reduced motion |
| P1 | Materials | https://developer.apple.com/design/human-interface-guidelines/materials | Layering, not blindly adding blur |
| P1 | Icons | https://developer.apple.com/design/human-interface-guidelines/icons | Consistency, semantic clarity |
| P1 | Apple Design Resources | https://developer.apple.com/design/resources/ | Kit reference only; check permitted usage |
| P1 | Design videos | https://developer.apple.com/videos/design/ | Demonstrated interaction patterns |
| P2 | Liquid Glass | https://developer.apple.com/documentation/technologyoverviews/liquid-glass | Content/control hierarchy, with platform caveats |
| P1 | Qt Quick Controls customization | https://doc.qt.io/qt-6/qtquickcontrols-customize.html | Implement own components without Apple proprietary APIs |

Some Apple pages are dynamic or reorganized. Verify destination, date and relevant macOS/platform applicability when using them. Source links are a roadmap, **not** evidence that every linked article has been fully reviewed.

## Required research deliverable
For each researched pattern, report:
- ID (e.g. TYPO-01); official URL; date checked; macOS / other platforms.
- Explicit guideline (paraphrased) vs project-specific interpretation; link to closest visual example.
- Existing QML component / screenshot; current evidence; applicability PASS / PARTIAL / FAIL / N/A / UNVERIFIED.
- Proposed acceptance criteria; trade-off for Qt 6.4+ Linux/Windows.
- A short research summary, plus unsupported/unclear claims that need verification.

Study order: typography -> layout -> sidebars/toolbars -> controls/states -> accessibility -> color -> motion -> material details -> wider Apple philosophy. Researcher should add concrete examples, not write endless unsourced generalizations.
