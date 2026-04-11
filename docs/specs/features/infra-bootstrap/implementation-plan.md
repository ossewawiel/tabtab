---
feature: infra-bootstrap
created: 2026-04-11
status: in-progress
---

# Implementation Plan: Infra Bootstrap

## Story status

- ✅ INF-001 — `.clang-format` config + CMake targets
- ✅ INF-002 — `.clang-tidy` config + CMake target
- 📋 INF-003 — pre-commit hooks
- 📋 INF-004 — GitHub PR description template

## Order

1. **infra** — INF-001, INF-002, INF-003, INF-004

This feature is single-platform (infra only). All four stories are implemented
by the same handover document.

## Rationale

The stories within the feature are sequenced to minimise rework:

1. **INF-001 (`.clang-format` + CMake target)** — lands first. Sets the formatting
   contract. The existing skeleton files (`main.cpp`, `test_smoke.cpp`) must be
   re-formatted to pass the check *as part of this story*, so every subsequent
   story lands on a clean base.
2. **INF-002 (`.clang-tidy` + CMake target)** — lands second. Depends on the
   compile database (`CMAKE_EXPORT_COMPILE_COMMANDS=ON`), which this story turns
   on. Skeleton must pass the check set with zero warnings before this story
   closes.
3. **INF-003 (pre-commit hooks)** — lands third. The `clang-format` hook
   requires INF-001's `.clang-format` file; the `yamllint` hook can land
   independently. Doing this story third lets the hook wire both tools in one
   configuration file.
4. **INF-004 (PR description template)** — lands last. Pure documentation /
   GitHub config, independent of the other three, so it can slot in whenever
   but closing it last keeps the feature tidy.

## Critical path

```
INF-001  ──▶  INF-002  ──▶  INF-003
                               │
INF-004  ─────────────────────┘   (INF-004 independent; closes the feature)
```

INF-002 depends on INF-001 **only** because of the skeleton pass-the-check
constraint — if INF-001 reformats a file and INF-002 lands against the
unformatted version, INF-002's skeleton check would pass on differently-formatted
code. Landing them in order avoids that trap.

INF-003's `clang-format` pre-commit hook points at the repo-root `.clang-format`
from INF-001, so INF-001 must land first.

## Risks

- **Windows path sensitivity.** Developer is on Windows; `clang-format` and
  `clang-tidy` may be invoked via Git Bash. CMake targets must not hard-code
  Unix-only shell syntax. Use `file(GLOB_RECURSE ...)` + CMake `execute_process`
  rather than shell pipelines.
- **`clang-tidy` against MSVC flags.** On the Windows dev machine, the compile
  database may contain MSVC-specific flags that confuse `clang-tidy`. The
  story's scope is Linux CI (`ci-builder.yml` runs on `ubuntu-latest`); local
  Windows runs are best-effort.
- **Skeleton files may fail the check set.** The existing `main.cpp`,
  `test_smoke.cpp`, and `CMakeLists.txt` were written before the config existed.
  Each story must verify and fix the skeleton as part of its Green phase.
- **`yamllint` false positives on `.tt.yaml` files.** The TabTab project format
  embeds expression strings (`=> signal + 1`) that look odd to a strict YAML
  linter. Configure `yamllint` with a relaxed ruleset (line-length off, indent
  2, truthy check off) before running against `examples/`.
- **`.pre-commit-config.yaml` hook versions drift.** Pin every hook to a
  specific `rev:`. Never use `main` or `HEAD` as a revision.

## Handover documents

- [Infra handover](./infra-handover.md)
