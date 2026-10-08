# wyzzarz fork of FreeCAD

Personal fork of [FreeCAD](https://github.com/FreeCAD/FreeCAD). The branch
`wyzzarz/1.1.4` is the upstream `1.1.4` release plus the changes below. Nothing here
is part of upstream FreeCAD. This folder (`contrib/wyzzarz/`) holds the build and
install scripts and this README.

Built and tested on Linux Mint 22.3 (Ubuntu 24.04 base), x86_64. Not tried on macOS
or Windows.

## What the fork includes

| Change | Where | Status |
|---|---|---|
| Build and install scripts (pixi, Linux) | `contrib/wyzzarz/` | built and installed on Linux |

## Build and install

### Linux: build

**Goal:** compile a release build of this checkout. It does not touch any
installed copy of FreeCAD.

**Prerequisite:** pixi in `~/.pixi/bin/pixi`. Install it with the official
installer from https://pixi.sh/install.sh (`PIXI_NO_PATH_UPDATE=1` leaves shell
config alone; the scripts use the full path).

**Run:**
```bash
bash contrib/wyzzarz/build-freecad.sh [jobs]   # default 8 jobs
```
It runs, in order:
1. `pixi install`: the conda-forge dependencies into `.pixi/` (~5.5 GB).
2. `pixi run configure-release`: CMake configure (also updates the git submodules).
3. `pixi run build-release`: the compile.

**Result:** the build is in `build/release/` (~1.3 GB). Try it without installing:
```bash
pixi run freecad-release
```

**Time:** the first full build took ~95 min with 8 jobs (6745 steps) on 12
threads / 16 GB. Re-running is incremental: only changed files recompile, so a
typical edit takes seconds to a few minutes. A full rebuild happens only if
`build/release` is deleted, CMake options change, or core headers change.
ccache is in the pixi env and used automatically (`FREECAD_USE_CCACHE` is ON):
the cache is `~/.cache/ccache` (5 GB limit; `pixi run --as-is ccache -s` for
stats), so a from-scratch rebuild of unchanged code should take minutes.

**Dev workflow:** edit, `build-freecad.sh`, try with `pixi run freecad-release`.
Install (below) only builds you have tried.

**Why pixi:** FreeCAD 1.1.x needs Qt 6.8, OCCT 7.8 and a recent compiler, which
Ubuntu 24.04's apt packages don't provide. Pixi supplies them from conda-forge in
a project-local environment, with no sudo and nothing changed on the system. It
is the project's own developer route (`pixi.toml`, `CMakePresets.json`). It is
like a Python venv, but it can hold compilers, C++ libraries and Python itself,
and `pixi.lock` pins the exact versions; `pixi run <cmd>` runs a command inside
the environment. The pixi binary is per user (`~/.pixi`), the environment per
project.

### Linux: install

**Goal:** use the build day to day: app-menu entry, a `freecad` command, and
`.FCStd` files that open with FreeCAD.

**Run:**
```bash
bash contrib/wyzzarz/install-freecad.sh
```
1. Checks a release build exists in `build/release/`.
2. Runs `pixi run --as-is install-release` (`cmake --install`): copies the build
   into the pixi env `.pixi/envs/default/`. **This overwrites the currently
   installed copy.**
3. Deploys per user under `~/.local` (no sudo, nothing system-wide): launchers
   `~/.local/bin/freecad` and `freecadcmd` (they run the pixi env's FreeCAD via
   `pixi run --as-is`), the app-menu entry, icons, and MIME types.

**Result:** FreeCAD starts from the app menu, or with `freecad` (needs
`~/.local/bin` on PATH).

- **Update after a rebuild:** run `install-freecad.sh` again.
- **Remove the deploy:** `bash contrib/wyzzarz/install-freecad.sh --uninstall`
  removes launchers, menu entry, icons and MIME; the installed copy in the pixi
  env stays.
- **Do not move or delete this checkout:** the launchers point at it, and at
  its `.pixi` environment.
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

## Moving to a new release

The changes are kept as commits so they can be cherry-picked onto the next release:

```bash
git switch -c wyzzarz/<new version> <new version tag>
git cherry-pick <the commits listed in Activities below, oldest first>
```

## Activities

A log of what was done on the `wyzzarz/1.1.4` branch, one entry per commit, oldest
first. Add an entry whenever a commit is added to the branch. (Entries describe the
commit as it was made; the sections above describe the branch as it is now.)

- **2026-10-07, Linux build and install** (commit "Add pixi build and Linux install
  scripts (contrib/wyzzarz)"): branch created from the upstream `1.1.4` tag. Added
  `build-freecad.sh`, `install-freecad.sh` and this README. First full pixi release
  build of 1.1.4 on Linux Mint 22.3 took ~95 min with 8 jobs; the install ran and
  `freecad` starts from the app menu.
