# Qt-MacOS integration audit

User requested integration and independent style checks on 2026-11-08.
Source inspected: Kostr2007/Qt-MacOS, pinned commit
`9e113b16c827be17f04783b496c0354c639f88ec` (v0.1.0).

The repository is a reusable Qt Quick library, not a replacement Qt SDK or a
qtbase fork. Public components use explicit Basic-derived controls. The gallery
and sample WorkspaceModel remain demonstration code and are excluded from the
Obsidian consumer. Original code is MIT, embedded Inter OFL, gallery icons MIT;
the supplied Obsidian patches are GPL-2.0-or-later.

The existing cumulative layout pilot targets Obsidian7a9391a. Integration adapts
its build/plugin/resource-overlay approach to current56931aa, preserving real
backend bindings, comparisons, Freedoom artwork and the accepted independent
Preview. Scope: Studio buttons, surfaces, parameter inspector and disclosure.
ART06's four Preview inspector backgrounds remain a separate pending scope.

Upstream build/test CI at this exact pin succeeded on windows-latest, macos-15
and ubuntu-22.04: https://github.com/Kostr2007/Qt-MacOS/actions/runs/42499574348.
That result establishes the upstream job results, not native macOS behavior of
the integrated Obsidian. Current cloud runtime is Linux/Qt6.8.2; integrated
macOS execution, AppKit parity and screen-reader certification are not implied.

Independent library verification retained at build/qtmacos-review/library/:
Release build, 6 C++ and74 QML outcomes passed, standalone consumer launched,
15 asset hashes matched. An initial missing Qt.labs.qmlmodels import was fixed
by supplying the retained SDK's QML_IMPORT_PATH; no dependency source edit or
package installation was needed. Integration gates and current screenshots
are recorded separately after the code is committed.
