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

## Targeted outline / split / icon / slider study — 2026-11-07

Complete Outline views and Split views articles were read, including platform subsections; selected HIG diagrams and concrete app images below were personally opened with `tools.view_image`. These six additions bring the catalog to **23 entries**. Images remain temporary under `/tmp/apple-research-2026-11-07/`; exact asset URLs and SHA-256 are in [manifest.json](manifest.json).

| ID | Official source and inspected visual | Useful comparison |
| --- | --- | --- |
| MAC-18 | [Outline views](https://developer.apple.com/design/human-interface-guidelines/outline-views) · [intro diagram](https://developer.apple.com/tutorials/images/com.apple.HIG/components-outline-view-intro@2x.png) | Four-column diagram: disclosure triangles and child indentation only in first column; selection spans row. An outline requires real hierarchy; flat resource categories do not become a file tree. |
| MAC-19 | [Split views](https://developer.apple.com/design/human-interface-guidelines/split-views) · [sidebar/canvas/inspector diagram](https://developer.apple.com/tutorials/images/com.apple.HIG/components-split-view-intro@2x.png) | Persistent selection, supplementary inspector and reasonable pane limits. Three macOS laptop diagrams also inspected. Illustrative proportions and tvOS ratios are not macOS requirements. |
| MAC-20 | [Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders) · [exact value example](https://developer.apple.com/tutorials/images/com.apple.HIG/sliders-text-field@2x.png) · [Energy Saver crop](https://developer.apple.com/tutorials/images/com.apple.HIG/sliders-labels@2x.png) | Four specimens inspected: filled track, visible thumb, optional meaningful ticks and exact value field. Historical settings crop is not a whole-window current System Settings screenshot. |
| MAC-21 | [Finder Gallery guide](https://support.apple.com/guide/mac-help/change-how-folders-are-displayed-in-the-finder-mchldaafb302/mac) · [actual app image](https://ipcdn-web.apple.com/assets/v2/web/c92ae0db-5f72-471b-818c-b01fd3aa3a46) | Navigation, dominant center content and quiet right metadata pane. Gallery is not an outline screenshot. |
| MAC-22 | [Settings, Sequoia 15 guide](https://support.apple.com/guide/mac-help/change-system-settings-mh15217/15/mac/15) · [Appearance image](https://help.apple.com/assets/67D1B1065D0706C4AD080C54/67D1B10E5D0706C4AD080C79/en_US/9d447c4b1ecc39663a72d63e67093be5.png) | Colorful rounded-square category tiles with text and independent selected-row fill, before newer material styling. |
| MAC-23 | [Settings, Tahoe 26 guide](https://support.apple.com/guide/mac-help/change-system-settings-mh15217/26/mac/26) · [Appearance image](https://help.apple.com/assets/69DD569682238CF8EC0621E2/69DD569982238CF8EC0621E9/en_US/1a55c8ea0fef87ffd5215a0ef88a615c.png) | Same tile/label pattern with newer settings/materials. Category tile inspiration does not require Apple artwork or Liquid Glass. |

HIG relative `/images/com.apple.HIG/` references resolved successfully under `https://developer.apple.com/tutorials/images/com.apple.HIG/`; domain-root and HIG-page-prefix attempts for the outline intro returned 404. This corrects the retrieval strategy for the earlier unavailable relative images, without claiming they were previously viewed.

Versioned guides establish **guide context**, not screenshot build dates. The new unversioned Finder page again identifies macOS 27 Golden Gate. Catalog IDs such as MAC-14 are unrelated to OS version numbers. See [targeted findings, source limits and proposed acceptance criteria](../../reports/2026-11-07-outline-split-research.md). No production change or aesthetic defect is implied by this research.
