# Compiling Obsidian Extended

The standard desktop build uses **Qt 6.4+** and a separate console worker.
See [Ubuntu instructions](docs/qt6/UBUNTU.md) for dependencies and runtime QML modules.

```sh
./scripts/dev/build-linux.sh
ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
./obsidian
```

To build the generator alone, without Qt or FLTK:

```sh
cmake -S . -B build/console -G Ninja -DCONSOLE_ONLY=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build/console --parallel 4
```

This standalone target retains the original executable name `obsidian`; do not
use its output in a Qt package. The Qt build produces both `obsidian` and
`obsidian-engine`. `scripts/dev/package-linux.sh` packages the Qt application
with its worker and resources.

## Historical FLTK interface

```sh
cmake -S . -B build/fltk -G Ninja -DOBSIDIAN_QT=OFF -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_WAYLAND=OFF
cmake --build build/fltk --parallel 4
```

Additional dependencies and old platform notes are retained in
[COMPILING_FLTK.md](docs/legacy/COMPILING_FLTK.md). Those commands predate the Qt
migration and require `OBSIDIAN_QT=OFF`. Windows/macOS Qt deployment is not yet
validated; the packaged target is Ubuntu 24.04+ x86_64.
