# Apple / macOS reference board (external originals)

This board is designed for image-capable reviewer agents. **No external Apple screenshots are embedded or redistributed here.** Open the official link, view the real illustrations/screenshots, then record the page, visible UI region and capture date. The exact screenshot assets must only be committed after checking explicit redistribution rights.

| ID | Reference & authoritative visual source | Compare with Obsidian | Focus |
|---|---|---|---|
| MAC-01 | [Apple macOS design](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) | [light](../../../../docs/qt6/design-preview/light.png) | Toolbar vs sidebar vs content hierarchy |
| MAC-02 | [Apple sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars) | [light](../../../../docs/qt6/design-preview/light.png) | Selection, navigation density, icons and text |
| MAC-03 | [Apple toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) | [commands menu](../../../../docs/qt6/design-preview/commands-menu.png) | Primary actions, icon/label hierarchy |
| MAC-04 | [Apple typography](https://developer.apple.com/design/human-interface-guidelines/typography) | [large text](../../../../docs/qt6/design-preview/large-text.png) | Optical roles, readability and hierarchy |
| MAC-05 | [Apple color](https://developer.apple.com/design/human-interface-guidelines/color) | [dark](../../../../docs/qt6/design-preview/dark.png) | Dark surfaces, contrast and selection |
| MAC-06 | [Apple layout](https://developer.apple.com/design/human-interface-guidelines/layout) | [minimum window](../../../../docs/qt6/design-preview/minimum.png) | Responsive three-column composition |
| MAC-07 | [Apple controls — buttons](https://developer.apple.com/design/human-interface-guidelines/buttons) | [inspector](../../../../docs/qt6/design-preview/inspector.png) | Button hierarchy, stroke, focus |
| MAC-08 | [Apple windows](https://developer.apple.com/design/human-interface-guidelines/windows) | [result](../../../../docs/qt6/design-preview/result.png) | Window chrome vs app-owned content |
| MAC-09 | [Apple motion](https://developer.apple.com/design/human-interface-guidelines/motion) | [navigation GIF](../../../../docs/qt6/design-preview/navigation-motion.gif) | Intentional transitions, reduced motion |
| MAC-10 | [Apple Design Resources — macOS UI kit](https://developer.apple.com/design/resources/) | [Obsidian typography comparisons](../../../../docs/qt6/typography/README.md) | Component anatomy; license restrictions |
| MAC-11 | [Apple Support: macOS user guide](https://support.apple.com/guide/mac-help/welcome/mac) | [light](../../../../docs/qt6/design-preview/light.png) | Real consumer Mac screenshots and workflows |
| MAC-12 | [Apple WWDC design videos](https://developer.apple.com/videos/design/) | [motion GIF](../../../../docs/qt6/design-preview/inspector-motion.gif) | Design choices in motion, not static-only |

## Capture/review protocol
- Researcher verifies every link and chooses **specific screenshot/example** on each official page (some pages are conceptual, not full app screenshots). Record source title, date viewed and exact observed feature in `manifest.json`.
- Prioritize Finder, System Settings, Preview and productivity-style layouts via official Apple Support guides. Keep editorial / cross-generation differences visible: a macOS screenshot from an older release is not the definition of today's HIG.
- For legally reusable third-party visuals, keep source URL, creator, license, attribution and version in manifest. Do not assume Wikimedia/Apple screenshot copyright is waived simply because file is public.
- If authorized to use a specific asset, place it in `references/apple/approved/` with a sidecar source/license record.
- Reviewer should use an image-capable browser or licensed local screenshots, not infer appearance solely from the textual page title. If image inaccessible, mark visual match UNVERIFIED.


## Concrete app images actually inspected — 2026-11-06

These are descriptive visual evidence, not normative specifications. The five original assets were downloaded **only to `/tmp/apple-research-2026-11-06/`** and opened with `tools.view_image`. Those ephemeral paths help this session's reviewers; future reviewers must retrieve the exact URLs in [manifest.json](manifest.json). No Apple image is tracked or licensed for redistribution here.

| ID | Official source / exact asset | Observed composition and state | Obsidian comparison |
|---|---|---|---|
| MAC-13 | [Finder guide](https://support.apple.com/guide/mac-help/get-to-know-the-finder-mchlp2605/mac) · [asset](https://ipcdn-web.apple.com/assets/v2/web/e52e5620-baa3-41cc-8102-8d7f9ef2cebb) | Quiet grouped sidebar; selected Documents row has gray fill and stronger text; icon-view content dominates; command groups are compact. Long names sometimes elide. | Navigation hierarchy, selected-row clarity, resource content; elision alone is not a defect. |
| MAC-14 | [System Settings guide](https://support.apple.com/guide/mac-help/change-system-settings-mh15217/mac) · [asset](https://ipcdn-web.apple.com/assets/v2/web/40bd24b5-d964-4cb9-8248-1d8bad524aba) | Blue selected Menu Bar row; aligned labels and trailing values; subtle grouped surfaces; visible on/off toggles and checks. | Inspector grouping, values, semantic emphasis. |
| MAC-15 | [Preview guide](https://support.apple.com/guide/preview/welcome/mac) · [asset](https://ipcdn-web.apple.com/assets/v2/web/852f6fc5-175c-43cd-8376-6f3708f277f8) | Compact title/status and grouped toolbar; signature popover has selected segment, focused action and faded unavailable controls. | Command groups, transient panels, focus/inactive-state distinction. |
| MAC-16 | [Notes guide](https://support.apple.com/guide/notes/welcome/mac) · [asset](https://ipcdn-web.apple.com/assets/v2/web/40d54ad6-0c18-47c8-93f5-6212d1b637f0) | Large quiet note pane; narrower gray audio/transcript inspector; compact mostly monochrome toolbar; secondary metadata. | Content/inspector balance. Full desktop image is unsuitable for direct font-size measurement. |
| MAC-17 | [TextEdit guide](https://support.apple.com/guide/textedit/welcome/mac) · [asset](https://ipcdn-web.apple.com/assets/v2/web/507f9c99-aad6-4cbd-a17a-c68d5c389bad) | Save sheet dims document; focused name field; open format menu has selected row plus checkmark; equally sized neutral Cancel and blue Save. | Combo selection, form focus, dialog action hierarchy. |

All five Support pages identify **macOS 27 Golden Gate** in the retrieved page metadata. This associates the guide context, not an independently verified screenshot build: creation dates and whether artwork was reused are unknown. The manifest records exact assets, SHA-256, provenance, observations, confidence and missing evidence. The current HIG also includes 2025/2026 Liquid Glass updates; these references do not justify imposing translucency or native Apple controls on Qt Linux/Windows.

The MAC-01–12 roadmap entries are preserved. Typography, layout, sidebars, toolbars, buttons, motion and designing-for-macOS article text was read through Apple's DocC JSON (`https://developer.apple.com/tutorials/data/design/human-interface-guidelines/<slug>.json`). Color/windows and discovery landing pages were fetched, but are not claimed as substantive visual studies. Relative HIG image URLs for Notes returned 404; they were not visually inspected. All existing local comparison links were checked and resolved successfully; no broken link required repair.

See [research evidence and acceptance criteria](../../reports/2026-11-06-apple-research.md). Static images cannot prove hover/press behavior, animation, keyboard order, actual font identity or contrast ratios. Exact sizes, radii, colors and timings for Obsidian require project decisions and runtime verification.
