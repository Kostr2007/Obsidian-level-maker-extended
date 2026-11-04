# Material Workspace validation

Current development checkout, 4 November 2026:

- Native Release GUI build succeeded in Debian 13 and in an isolated Ubuntu 24.04 x86_64 container.
- Xvfb checks exercised World / Gameplay / Preview, Ctrl+F, an empty search,
  clearing the search, resizing from 1280×740 to 1000×680, and normal exit.
- Selected engine, game, port, length, theme and map size remained unchanged
  after navigation, search and resizing.
- All eight combinations of four accent palettes and light/dark schemes opened
  and saved their theme and accent. Classic layout and single-pane mode opened
  and exited successfully.
- An actual GUI F2 build, including the output-file chooser, produced a PWAD
  with MAP01 and 56 lumps. The preview showed the generated map and Success.
- Ubuntu batch generation and generation from the extracted Ubuntu archive
  both produced PWAD files with valid directory bounds and MAP01.

Screenshots in this directory are captures of the native application. `sage.png`
shows a completed GUI generation. These checks do not establish screen-reader
support, Unicode case folding in search, system accent integration, or testing
on every Ubuntu desktop/graphics configuration.

Reproduction: see `.github/workflows/material-you.yml`,
`scripts/dev/check-workspace.py` and [UBUNTU.md](UBUNTU.md).
