---
feature: infra-bootstrap
phase: 1
status: planned
created: 2026-04-10
stories: [INF-001, INF-002, INF-003, INF-004]
---

# Infra Bootstrap

## Summary

Stand up the tooling everything downstream depends on: `clang-format` for C++
formatting, `clang-tidy` for static analysis, pre-commit hooks to run them
locally, and a GitHub PR description template that matches the cicd-quality
standards doc.

## Motivation

Every other story assumes these tools exist. If we add them later, we have to
reformat/refactor the backlog of code that landed without them. Landing them
first keeps the history clean and makes the very first real code story
(BLD-001) land with formatting already enforced.

## Stories

| ID | Platform | Title | Status |
|---|---|---|---|
| INF-001 | infra | Add `.clang-format` config and CMake target | 📋 Planned |
| INF-002 | infra | Add `.clang-tidy` config and CMake target | 📋 Planned |
| INF-003 | infra | Add pre-commit hooks for C++ format and YAML lint | 📋 Planned |
| INF-004 | infra | Add GitHub PR description template | 📋 Planned |

## Acceptance criteria

- [ ] `.clang-format` at repo root, used by `cmake --build build --target clang-format`
- [ ] `.clang-tidy` at repo root, used by `cmake --build build --target clang-tidy`
- [ ] `.pre-commit-config.yaml` at repo root; `pre-commit run --all-files` green
- [ ] `.github/pull_request_template.md` exists with the checklist from
      `docs/standards/cicd-quality.md`

## Dependencies

None. This is the first feature.
