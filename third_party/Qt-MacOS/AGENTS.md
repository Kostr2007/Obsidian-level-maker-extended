# Working on Qt-MacOS

Qt-MacOS is a reusable Qt Quick/QML library **above Qt**, not a qtbase fork.
Read [README.md](README.md), [GETTING_STARTED.md](docs/GETTING_STARTED.md) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) before changing the project.
The repository's current scope is a preview library and component gallery.

## Code map

- `qml/QtMacOS/`: public `import QtMacOS` components and `Theme` singleton.
  CMake flattens component resource aliases; add new public types to `mac_qml`.
- `qml/QtMacOS/Controls/`: explicit Basic-derived controls; this is not a global
  Qt Quick Controls style plugin.
- `demo/`: Finder, Mouse settings and ten layout pages. `WorkspaceModel` is
  demo-only C++; public QML must not import `QtMacOS.Demo` or access an app backend.
- `tests/`: QML interaction tests and C++ model tests.
- `examples/minimal/`: standalone consumer; it links only the public plugin.
- `integrations/obsidian/`: optional patches against a pinned external commit.
  `layout.patch` is cumulative; never apply it on top of `qtmacos.patch`.
- `docs/`: design decisions, verified HIG sources, API notes and actual captures.

## Build and test

Use a matching compiler and Qt SDK; Qt 6.8.2 is the tested development version.
If this cloud machine has `/workspace/qt-sdk/activate.sh`, source it first.
That path is an optional local setup, not a project requirement.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 4
ctest --test-dir build -C Release --output-on-failure --no-tests=error
cmake -S examples/minimal -B build-example -DCMAKE_BUILD_TYPE=Release
cmake --build build-example --config Release --parallel 4
```

CTest configures `offscreen` and software rendering for QML tests. Offscreen
success does not establish native window behavior on another OS. Use the
existing native-window smoke script with X11, a WM and a compositor for changes
to `MacWindow` or `WindowButtons`; see [FINDER_LINUX.md](docs/FINDER_LINUX.md).
Keep existing user changes, use the current checkout, and inspect `git status`
before editing. Do not include SDKs or build trees in commits.

## API and behavior

- Preserve bindings, keyboard operation, visible focus and accessible names.
  Use `qsTr()` for user-facing strings and theme tokens for shared colors.
- Keep selection by stable item ID across filtering, sorting and model resets.
  Do not retain invalid `QModelIndex` values across model resets.
- Respect the model/role/adapter contracts documented in
  [LAYOUT_IMPLEMENTATION.ru.md](docs/LAYOUT_IMPLEMENTATION.ru.md). Check list,
  table, outline and column behavior against the same data.
- Lists and collections must remain virtualized. Do not instantiate a visual
  delegate for every entry in large datasets.
- Prefer a focused behavior test for a changed public contract. Run the
  existing regression suites; don't replace assertions with screenshots.
- Do not claim native blur/vibrancy, screen-reader compliance, a full Obsidian
  redesign or platform support on the basis of appearance alone.

## Screenshots and evidence

Use actual Qt captures, never generated or edited mockups as implementation
evidence. Preserve the historical captures and their manifests. For a new run:

```sh
python3 scripts/capture_layout.py --binary build/qtmacos-gallery \
  --output docs/screenshots/layout --timeout 30
```

The script creates a unique directory with PNGs, HTML, commands, hashes and
diagnostics. Review captures and stderr before updating documentation. On
multi-config builds use `build/Release/qtmacos-gallery.exe` as appropriate.
Interaction frames can be recorded by setting `QTMACOS_STORY_DIR` to a fresh
directory when running `qtmacos-tests`; keep manifests with those frames.

## Release and licensing

Follow [RELEASING.md](docs/RELEASING.md). Keep MIT, Inter/OFL, Phosphor/MIT and
Obsidian/GPL notices distinct. Do not introduce Apple fonts or SF Symbols as
redistributable assets without checking their actual terms. Do not expose
credentials in logs, manifests, documentation or commits. Commit, push and
release only within the user's authorized scope; keep repository visibility
unchanged unless requested.
