#!/usr/bin/env bash
# Fetch the Skia source tree into third_party/skia.
#
# This is a STUB. The real implementation is tracked as INF-005:
# - Clone Skia at a pinned revision
# - Sync gn dependencies
# - Build Skia with the right arguments for TabTab
# - Verify libskia.a exists
#
# For now this script just prints guidance and exits 0 so CI can
# cache the "not-fetched-yet" state without failing.

set -euo pipefail

say() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER_DIR="$(dirname "$SCRIPT_DIR")"
SKIA_DIR="$BUILDER_DIR/third_party/skia"

if [ -f "$SKIA_DIR/include/core/SkCanvas.h" ]; then
    say "Skia already present at $SKIA_DIR — nothing to do."
    exit 0
fi

say "Skia not yet fetched. This is expected during pre-alpha."
say "The real fetch is tracked as story INF-005."
say ""
say "When INF-005 lands, this script will:"
say "  1. git clone https://skia.googlesource.com/skia.git at a pinned tag"
say "  2. python tools/git-sync-deps"
say "  3. bin/gn gen out/Release with the TabTab args"
say "  4. ninja -C out/Release"
say ""
say "For now, the CMake build proceeds with TABTAB_HAS_SKIA=OFF."

# Create the directory so CMake can reference it without erroring.
mkdir -p "$SKIA_DIR"
exit 0
