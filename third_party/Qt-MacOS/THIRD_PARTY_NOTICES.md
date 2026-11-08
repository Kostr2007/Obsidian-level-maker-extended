# Third-party notices

The root [MIT license](LICENSE) covers original Qt-MacOS code, documentation,
original vector drawings and application screenshots. The following material
retains its own license; the root license does not replace these terms.

| Material | License and source | Distribution in this repository |
| --- | --- | --- |
| Inter Variable font | SIL Open Font License 1.1, Rasmus Andersson; [Inter](https://github.com/rsms/inter) | `assets/fonts/InterVariable.ttf`, [license](assets/fonts/LICENSE.txt), [pinned provenance and hash](assets/fonts/manifest.json). The font is embedded in the QML module. |
| Phosphor SVG icons and our recolored variants | MIT, Phosphor Icons; [source](https://github.com/phosphor-icons/core) | `assets/icons/*.svg`, [license](assets/icons/LICENSE), [provenance](assets/icons/manifest.json). These are gallery resources. |
| Obsidian integration patches | GPL-2.0-or-later; [Obsidian-level-maker-extended](https://github.com/Kostr2007/Obsidian-level-maker-extended), commit `7a9391a28e5ba21f088b164be488ead6d88c00fb` | `integrations/obsidian/*.patch` contain modified/contextual Obsidian code. [Upstream copyright notice and full license](integrations/obsidian/LICENSE-OBSIDIAN.txt). Patch contributions are distributed under GPL-2.0-or-later. The rest of the QML library has no Obsidian dependency. |

Qt is an external build/runtime dependency and is not vendored here. Its own
licensing terms apply to the Qt version and modules you use. A source release
of this project does not include Qt or grant rights to Qt.

Apple's Human Interface Guidelines are linked as design references in
[HIG_LAYOUT_SOURCES.md](docs/HIG_LAYOUT_SOURCES.md). Apple screenshots, San
Francisco fonts and SF Symbols are not bundled. Finder, macOS and Apple names
are used to describe design references; this is an independent project and
does not imply Apple affiliation. The gallery contains original sample data
and drawings, rather than a copy of Apple's file manager or system settings.
