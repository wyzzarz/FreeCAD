# wyzzarz fork of FreeCAD

Personal fork of [FreeCAD](https://github.com/FreeCAD/FreeCAD). The branch
`wyzzarz/1.1.4` is the upstream `1.1.4` release plus the changes below. Nothing here
is part of upstream FreeCAD. This folder (`contrib/wyzzarz/`) holds the build and
install scripts and this README.

Built and tested on Linux Mint 22.3 (Ubuntu 24.04 base), x86_64, and on macOS Apple
Silicon (osx-arm64). Not tried on Windows. The new functions are tested by unit tests
and were tried by hand in the installed FreeCAD.

## What the fork includes

| Change | Where | Status |
|---|---|---|
| Build and install scripts (pixi, Linux) | `contrib/wyzzarz/` | built and installed on Linux |
| macOS build and install | `contrib/wyzzarz/README.md` ("Build", "Install", "macOS: DMG bundle"), `contrib/wyzzarz/build-freecad.sh`, `contrib/wyzzarz/install-freecad.sh`, `CMakePresets.json` | tested on macOS Apple Silicon |
| US Tabloid blank TechDraw template | `src/Mod/TechDraw/Templates/ASME/` | added; a page created from it opens in the GUI |
| `imp()` spreadsheet/expression function | `src/App/Expression.cpp`, `src/App/ExpressionParser.h`, `src/Mod/Spreadsheet/TestSpreadsheet.py` | 5 tests pass |

### US Tabloid template

`ASME/USTabloid_Landscape_blank.svg`: a blank 431.8 x 279.4 mm (17 x 11 in) TechDraw
template, next to `USLetter_Landscape_blank.svg`. It is the same size as the existing
`ASME/ANSIB_Landscape_blank.svg`; this one adds the "USTabloid" name.

### `imp()`: imperial lengths

`imp(feet; inches; numerator; denominator)` returns a length. It takes 1, 2 or 4
arguments; other counts are not evaluated (the cell keeps the text).

| Expression | Result |
|---|---|
| `imp(1)` | 1 ft = 12 in |
| `imp(1; 2)` | 1 ft 2 in = 14 in |
| `imp(1; 2; 3; 4)` | 1 ft 2 3/4 in = 14.75 in |
| `imp(1.5)` | 18 in |
| `imp(-1; 2)` | -14 in: a negative number of feet makes the whole length negative |
| `imp(1; -2)` | 10 in: a negative number of inches only affects the inches |
| `imp(1; 2; 3; 0)` | error: the denominator must not be zero |

## Build and install

### Build (Linux and macOS)

**Goal:** compile a release build of this checkout. It does not touch any
installed copy of FreeCAD.

**Run** (`build-freecad.sh` can be run from any directory; bare `pixi run` commands
require the checkout root, where `pixi.toml` lives):
```bash
bash /path/to/freecad_source/contrib/wyzzarz/build-freecad.sh [jobs]   # default 8 jobs
```
It runs, in order:
1. Installs pixi into `~/.pixi/` if not already present.
2. `pixi install`: the conda-forge dependencies into `.pixi/` (~5.5 GB).
3. `pixi run configure-release`: CMake configure (also updates the git submodules).
4. `pixi run build-release`: the compile.

**Result:** the build is in `build/release/` (~1.3 GB). Try it without installing
(run from the checkout root, where `pixi.toml` lives):
```bash
cd /path/to/freecad_source
pixi run freecad-release
```

**Time:** the first full build took ~95 min with 8 jobs on Linux (6752 steps, 12
threads / 16 GB) and ~49 min on macOS Apple Silicon (M-series). Re-running is
incremental: only changed files recompile, so a typical edit takes seconds to a
few minutes. A full rebuild happens only if `build/release` is deleted, CMake
options change, or core headers change. ccache is in the pixi env and used
automatically (`FREECAD_USE_CCACHE` is ON): the cache is `~/.cache/ccache`
(5 GB limit; `pixi run --as-is ccache -s` for stats), so a from-scratch rebuild
of unchanged code should take minutes.

**Dev workflow:** edit, `build-freecad.sh`, try with `pixi run freecad-release`
(from the checkout root).
Install (below) only builds you have tried.

**Why pixi:** FreeCAD 1.1.x needs Qt 6.8, OCCT 7.8 and a recent compiler, which
Ubuntu 24.04's apt packages don't provide. Pixi supplies them from conda-forge in
a project-local environment, with no sudo and nothing changed on the system. It
is the project's own developer route (`pixi.toml`, `CMakePresets.json`). It is
like a Python venv, but it can hold compilers, C++ libraries and Python itself,
and `pixi.lock` pins the exact versions; `pixi run <cmd>` runs a command inside
the environment. The pixi binary is per user (`~/.pixi`), the environment per
project.

See also [Compile on macOS](https://wiki.freecad.org/Compile_on_MacOS).

### Install (Linux and macOS)

**Goal:** make the build convenient to launch day to day. This is **not a
standalone installation** — the launchers and `.app` are pointers back to this
checkout and its pixi environment; moving or deleting either breaks them. For a
self-contained package that has no dependency on the checkout, use the
Linux: AppImage or macOS: DMG bundle routes instead.

**Run** (from the checkout root, where `pixi.toml` lives):
```bash
bash contrib/wyzzarz/install-freecad.sh
```
1. Checks a release build exists in `build/release/`.
2. Runs `pixi run --as-is install-release` (`cmake --install`): copies the build
   into the pixi env `.pixi/envs/default/`. **This overwrites the currently
   installed copy.**
3. Deploys launchers `~/.local/bin/freecad` and `freecadcmd` (no sudo, nothing
   system-wide); they run the pixi env's FreeCAD via `pixi run --as-is`.
4. **Linux:** app-menu entry (`.desktop`), icons, and MIME types under `~/.local`.
   **macOS:** `/Applications/FreeCAD (WyzzarZ).app` — a launcher-backed stub with
   the FreeCAD icon; opens from Spotlight, Launchpad and the Dock.

**Result:** `freecad` in a terminal, or from the app menu (Linux) / `/Applications`
(macOS). `~/.local/bin` must be on PATH (it is by default on Mint; on macOS add
`export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc`).

- **Update after a rebuild:** run `install-freecad.sh` again.
- **Remove the deploy:** `bash contrib/wyzzarz/install-freecad.sh --uninstall`
  removes launchers, menu entry, icons, MIME and the `.app`; the installed copy
  in the pixi env stays.
- **Do not move or delete this checkout:** the launchers and `.app` point at it,
  and at its `.pixi` environment.
- **What can break the installed copy:** installing a bad build; a pixi
  dependency change (a plain `pixi run` / `pixi install` after switching to a
  branch with a different `pixi.toml`/`pixi.lock` updates the shared env; the
  launchers use `--as-is` to avoid this); and shared user settings
  (`~/.config/FreeCAD`, `~/.local/share/FreeCAD`) which dev builds also read and
  write. Compiling alone never touches it.
- Logs go to `build/logs/` (git-ignored).

### Linux: AppImage

Not done yet. For sharing or keeping a version, the project's own tooling makes
an AppImage: one self-contained file (roughly 1 GB, unmeasured) you copy to any
x86_64 Linux machine and run, with no install.
- **How it's made:** FreeCAD is built as a conda package
  (`package/rattler-build/recipe.yaml`) into a separate packaging env
  (`package/rattler-build/.pixi`); `pixi run -e package create_bundle` (from
  `package/rattler-build`) strips it and wraps it with `appimagetool`.
- **Separate from the dev flow:** it does its own full compile (~1.5-2 h+; ccache
  may help, unverified) and cannot reuse `build/release`. It only replaces the
  install step; keep the dev setup for incremental builds.
- Set `BUILD_TAG`, leave `UPLOAD_RELEASE` unset (set, it runs `gh release
  upload`); check the `freecad` conda channel in `package/rattler-build/pixi.toml`
  resolves. Expect a temporary disk spike (likely 15 GB+, unmeasured).
- Flatpak is not pursued: it needs a manifest built against a Flatpak runtime
  (not pixi), and nothing in this checkout makes one.

### macOS: DMG bundle

For a distributable, self-contained DMG (the macOS counterpart of the AppImage),
use `package/rattler-build/osx/create_bundle.sh`:
```bash
cd package/rattler-build && BUILD_TAG=1.1.4-wyzzarz pixi run -e package create_bundle
```
- **Separate from the dev flow:** it does its own full compile and cannot reuse
  `build/release`. Keep the dev setup for incremental builds.
- The `install-freecad.sh` `.app` is a dev-install launcher stub, not a
  self-contained bundle.
- The earlier conda/mambaforge steps (`conda devenv`, `-DBUILD_QT5` and so on) no
  longer work in 1.1.4. They are in the commit "Update README for compiling for
  MacOS" (`f110d93939`) on the fork's `feat/wyzzarz` branch.

## Moving to a new release

The changes are kept as commits so they can be cherry-picked onto the next release:

```bash
git switch -c wyzzarz/<new version> <new version tag>
git cherry-pick <the commits listed in Activities below, oldest first>
```
What needed fixing when porting to 1.1.4, and may again:
- `src/Mod/TechDraw/Templates/`: the US sizes moved into `ASME/`.
- `src/Mod/Spreadsheet/TestSpreadsheet.py`: upstream splits and reorganises these
  tests, so the cherry-pick conflicts. Keep upstream's file and re-add the new tests in
  the `SpreadsheetFunction` class.
- Then build with `build-freecad.sh` and run
  `pixi run --as-is build/release/bin/FreeCADCmd -t TestSpreadsheet`.

## Activities

A log of what was done on the `wyzzarz/1.1.4` branch, one entry per commit, oldest
first. Add an entry whenever a commit is added to the branch. (Entries describe the
commit as it was made; the sections above describe the branch as it is now.)

- **2026-10-07, Linux build and install** (commit "Add pixi build and Linux install
  scripts (contrib/wyzzarz)"): branch created from the upstream `1.1.4` tag. Added
  `build-freecad.sh`, `install-freecad.sh` and this README. First full pixi release
  build of 1.1.4 on Linux Mint 22.3 took ~95 min with 8 jobs; the install ran and
  `freecad` starts from the app menu.
- **2026-10-08, macOS build and install** (commit "Add macOS build and install support
  (contrib/wyzzarz)"): based on the fork's commit "Update README for compiling for MacOS"
  (`f110d93939`, originally 2024-06-13), which edited the top-level `README.md`. Its steps
  used conda/mambaforge (`conda devenv` and the `conda/` environment files, `-DBUILD_QT5`,
  `-DWITH_PYTHON3`, `-std=c++14`), which no longer exist in 1.1.4, so it was not
  cherry-picked as it was. The pixi steps were written in a "macOS: build" section;
  `build-freecad.sh` and `install-freecad.sh` were then extended to cover macOS (tested on
  Apple Silicon), and the build/install sections were merged into "Build (Linux and macOS)"
  and "Install (Linux and macOS)".
- **2026-10-07, US Tabloid template** (commit "Add Tabloid templates"): cherry-picked from
  the fork (originally 2024-07-11). Adds `USTabloid_Landscape_blank.svg`, a 431.8 x 279.4 mm
  (17 x 11 in) blank TechDraw template. In 1.1.4 the US sizes live in
  `src/Mod/TechDraw/Templates/ASME/`, so it was placed there next to
  `USLetter_Landscape_blank.svg` (the original commit had it in `Templates/`). Same size as
  the existing `ASME/ANSIB_Landscape_blank.svg`; this one only adds the "USTabloid" name.
  Checked on Linux with the build: the file is in the templates folder that TechDraw
  "Insert Page using Template" opens (`share/Mod/TechDraw/Templates/ASME/`); a
  `DrawSVGTemplate` loads it at 431.8 x 279.4 mm, like `ANSIB_Landscape_blank.svg`; and
  a page created from it opens in the TechDraw workbench. The sheet is blank (the SVG has
  no border or title block). The file dialog itself was not clicked through by hand.
- **2026-10-07, imperial `imp` expression** (commit "Add support for imperial (imp)
  expression"): cherry-picked from the fork (originally 2023-05-08). Adds `imp(feet;
  inches; numerator; denominator)` to spreadsheet/expressions: `imp(1)` is 1 ft,
  `imp(1; 2)` is 1 ft 2 in, `imp(1; 2; 3; 4)` is 1 ft 2 3/4 in. `Expression.cpp` and
  `ExpressionParser.h` applied cleanly; two behaviour changes were then made while
  porting:
  - A zero denominator (`imp(1; 2; 3; 0)`) is now an error; it used to give `inf`.
  - A negative number of feet now makes the whole length negative: `imp(-1; 2)` is
    -14 in (it was -10 in). A negative number of inches still only affects the inches.

  `TestSpreadsheet.py` conflicted because upstream split the old test class; only the
  new test was kept, as `test_imp` in `SpreadsheetFunction`, and four more were added
  (`test_imp_values`, `test_imp_zero_denominator`, `test_imp_invalid_argument_count`,
  `test_imp_contents`). Built on Linux: all 91 tests in `TestSpreadsheet` pass.
