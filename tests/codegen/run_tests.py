"""
Code generator fixture test runner.

Walks every directory under fixtures/, runs the generator on its project.tt.yaml,
and compares the output against expected/<name>/.

This is a SKELETON. The real implementation is tracked as GEN-001 (generator
wiring) and GEN-002 (fixture runner). For now it just reports that no fixtures
exist, so CI has a stable entry point.

Usage:
    python run_tests.py              # run all fixtures
    python run_tests.py --update     # regenerate expected/ from current generator output
    python run_tests.py NAME         # run a single fixture
"""

from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"
EXPECTED = HERE / "expected"


def main(argv: list[str]) -> int:
    update = "--update" in argv
    argv = [a for a in argv if not a.startswith("--")]
    only = argv[0] if argv else None

    if not FIXTURES.exists():
        print(f"no fixtures directory at {FIXTURES}")
        return 0

    fixtures = [p for p in FIXTURES.iterdir() if p.is_dir()]
    if only:
        fixtures = [p for p in fixtures if p.name == only]

    if not fixtures:
        print("no fixtures to run (this is expected during pre-alpha)")
        return 0

    print(f"would run {len(fixtures)} fixture(s): {[p.name for p in fixtures]}")
    print("generator not yet wired — tracked as GEN-001")
    if update:
        print("(--update noted; will be honoured once the generator exists)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
