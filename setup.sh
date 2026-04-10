#!/usr/bin/env bash
# TabTab developer environment setup.
#
# This is a STUB. Real implementation is tracked as story INF-001.
# For now it just verifies prerequisites and prints next steps.

set -euo pipefail

say() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; }

need() {
    local name="$1" check="$2"
    if eval "$check" >/dev/null 2>&1; then
        say "$name: OK"
    else
        warn "$name: missing or not on PATH"
        MISSING=$((MISSING + 1))
    fi
}

MISSING=0

say "Checking prerequisites..."
need "cmake >= 3.28"   "cmake --version"
need "C++ compiler"    "command -v cc || command -v clang || command -v g++ || command -v cl"
need "ninja"           "command -v ninja"
need "python >= 3.10"  "python --version || python3 --version"
need "java >= 21"      "java -version"
need "gradle >= 8.10"  "gradle --version"
need "git"             "git --version"
need "gh (GitHub CLI)" "gh --version"

if [ "$MISSING" -gt 0 ]; then
    err "$MISSING prerequisite(s) missing. Install them and re-run."
    exit 1
fi

say "All prerequisites present."
cat <<'EOF'

Next steps:
  1. Fetch Skia:         cd builder && bash scripts/fetch-skia.sh
  2. Configure builder:  cd builder && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
  3. Build:              cmake --build builder/build --parallel
  4. Run tests:          cd builder/build && ctest --output-on-failure

See docs/standards/coding-standards.md for conventions before contributing.
EOF
