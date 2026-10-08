#!/usr/bin/env bash
# Build FreeCAD (release) in this checkout using pixi. Build only: it does NOT install.
# To install/deploy the result, run install-freecad.sh afterwards.
# Safe to re-run: the build is incremental.
# Usage: build-freecad.sh [jobs]   (default 8)
set -euo pipefail
JOBS="${1:-8}"
export PATH="$HOME/.pixi/bin:$PATH"
cd "$(dirname "$0")/../.."
export CMAKE_BUILD_PARALLEL_LEVEL="$JOBS"

echo "== $(date) pixi install (conda-forge deps)"
pixi install
echo "== $(date) configure-release (also updates submodules)"
pixi run configure-release
echo "== $(date) build-release, $JOBS jobs"
pixi run build-release
echo "== $(date) done (not installed). Try it: pixi run freecad-release. Install: install-freecad.sh"
