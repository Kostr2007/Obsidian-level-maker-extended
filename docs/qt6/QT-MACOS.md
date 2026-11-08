# Optional Qt-MacOS Studio integration

The normal Studio can use the public [Qt-MacOS](https://github.com/Kostr2007/Qt-MacOS)
QML library. This is a library above Qt, not a Qt fork or a native macOS backend.
The integration is optional at build time. Its current scope is action buttons,
card surfaces and the parameter inspector; the existing Studio navigation and
editor continue to own the layout, schema, settings and generation actions.

The inspector uses `MacLabel`, `MacBox` and `MacDisclosureGroup` with the real
parameter title, current backend value, default and generator help. Choice labels
and boolean values retain their existing conversion. Changing parameters closes
the help and resets scrolling. Resource illustrations, gameplay comparisons and
the last WAD preview remain available. `Theme.dark` follows the existing backend
appearance preference. Highlighted actions and focus borders retain Studio’s
selected accent. Explicit Basic-derived library controls work alongside
Studio's global Fusion style, preserving the independent `--design-preview`
scene and its accepted artistic choices.

## Reproducible build

Use Qt 6.8.2 (the verified SDK) and a separate build directory. The dependency is
not downloaded by CMake, and an OFF build needs no Qt-MacOS checkout.

```sh
git submodule update --init third_party/Qt-MacOS
git -C third_party/Qt-MacOS rev-parse HEAD
# Expected: 9e113b16c827be17f04783b496c0354c639f88ec
cmake -S . -B build/qt-macos -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DOBSIDIAN_QT=ON -DOBSIDIAN_QTMACOS_ROOT="$PWD/third_party/Qt-MacOS"
cmake --build build/qt-macos --parallel 4
QT_QUICK_BACKEND=software ctest --test-dir build/qt-macos \
  -R '^qt-core$' --output-on-failure --no-tests=error
./obsidian
```

The source path enables the integration; there is no runtime switch. The library
is linked as a static QML plugin. The gallery and its demo models are excluded.
The public module embeds the Inter variable font, though Studio retains its
existing application font. CMake copies the selected build's executable to the
repository root, so run ON and OFF builds serially.

To restore the regular Studio build:

```sh
cmake -S . -B build/qt -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DOBSIDIAN_QT=ON -DOBSIDIAN_QTMACOS_ROOT=
cmake --build build/qt --parallel 4
QT_QUICK_BACKEND=software ctest --test-dir build/qt \
  -R '^qt-core$' --output-on-failure --no-tests=error
```

## Provenance and limits

The adaptation follows the dependency's cumulative
[`layout.patch`](https://github.com/Kostr2007/Qt-MacOS/blob/9e113b16c827be17f04783b496c0354c639f88ec/integrations/obsidian/layout.patch),
originally targeting Obsidian `7a9391a28e5ba21f088b164be488ead6d88c00fb`.
It was adapted to the current Studio rather than applied over older application
sources. Integration sources remain GPL-2.0-or-later. Qt-MacOS original library
code is MIT; the embedded Inter font is OFL-1.1. Preserve upstream `LICENSE`,
`THIRD_PARTY_NOTICES.md` and `assets/fonts/LICENSE.txt` when distributing the
dependency. Gallery Phosphor assets are MIT and are not linked by this consumer.
Qt remains a separate dependency under its own applicable licenses.

No Apple fonts, SF Symbols, screenshots or SDK have been copied. The integration
does not establish native vibrancy, AppKit parity, Windows/macOS behavior or
screen-reader compliance. Linux Qt captures and tests describe that tested
platform only. ART-06 background comparisons remain a separate pending task.
