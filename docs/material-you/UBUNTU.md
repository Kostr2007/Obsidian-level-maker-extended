# Material Workspace on Ubuntu

The native C++/FLTK application now has a section rail, searchable settings,
a responsive preview, keyboard focus states, Material sliders and checkboxes,
and four curated accent palettes. Choose Appearance → Accent and Appearance →
Material You Light / Dark. Theme and accent selections survive restart.

## Build from source

On Ubuntu 24.04 or newer, from the extracted source or repository root:

```sh
sudo apt update
sudo apt install build-essential cmake ninja-build flex libfontconfig1-dev libxft-dev libxinerama-dev libxcursor-dev libgl1-mesa-dev libglu1-mesa-dev
./scripts/dev/build-linux.sh
./obsidian
```

On a Wayland desktop, this build uses XWayland. Keep the executable alongside
`data`, `games`, `scripts`, and the other resource folders. No Doom IWAD is needed
to generate maps; playing a generated map requires the corresponding game data
and a compatible engine, for example GZDoom.

## Packaged build

Download the Ubuntu archive from [GitHub Releases](https://github.com/Kostr2007/Obsidian-level-maker-extended/releases/latest).
Release assets include the version in their filenames; local packaging keeps the generic Material-Workspace filename.

An archive built on Ubuntu 24.04 x86_64 targets Ubuntu 24.04 and newer x86_64.
Do not substitute a binary built on a newer Debian distribution: its glibc
requirement can exceed Ubuntu's version.

```sh
sudo apt install libfontconfig1 libxft2 libxinerama1 libxcursor1 libgl1 libglu1-mesa
tar -xzf Obsidian-Extended-0.2.0-ubuntu-24.04-x86_64.tar.gz
cd Obsidian-Extended
./start.sh
```

Extract into a directory you own. The application saves its configuration there.
Create a distributable archive from a native build with
`./scripts/dev/package-linux.sh`; the result is placed in `build/`.

## Try the interface

- World contains map layout settings. Gameplay contains combat and extra modules.
  With the existing single-pane option enabled, All settings contains both.
- Find settings searches card titles and option names in the current section.
  Matching cards retain all their options; the search never changes generator values.
  Ctrl+F focuses search; clear the field to show all compatible cards again.
- On wide windows the preview stays beside the settings; on compact windows,
  select Preview in the rail. It displays actual generator output, not an invented map.
- Create map / F2 starts generation; Cancel replaces Quit while a build runs.
- Presets, Set seed, Surprise me and Options open existing application features.
- Appearance → Classic and Custom preserves the legacy layout and theme editor.

Current scope: desktop Material styling and workflow. Accent palettes are curated,
not wallpaper-derived dynamic color. System theme synchronization, expressive
motion, and screen-reader integration are not implemented in this version.
