---
feature: core-result-type
phase: 1
status: planned
created: 2026-04-10
stories: [BLD-001]
---

# Core Result Type

## Summary

Introduce a header-only `tabtab::Result<T, Error>` type in
`builder/include/tabtab/result.h`. All fallible operations in the builder's
core subsystems will return a `Result` instead of throwing — per the coding
standards, hot paths may not use exceptions.

## Motivation

This is deliberately a one-story feature. It's the first real code landing in
the repo and exists to:

1. Prove the TDD loop works end-to-end (Red → Green → Refactor with Google Test)
2. Prove the C++ toolchain works (CMake + GCC/Clang/MSVC)
3. Give every subsequent builder story a consistent error-handling primitive

There is deliberately no dependency on Skia, yaml-cpp, or any third-party
library — so the first real code landing can't be blocked by toolchain issues
in those libraries.

## Stories

| ID | Platform | Title | Status |
|---|---|---|---|
| BLD-001 | builder | `Result<T, Error>` type in `tabtab/result.h` | 📋 Planned |

## Acceptance criteria

- [ ] Header-only implementation at `builder/include/tabtab/result.h`
- [ ] `Result<T, Error>` is constructible via `Result::ok(value)` and
      `Result::err(error)`
- [ ] `isOk()` and `isErr()` predicates
- [ ] `value()` and `error()` accessors (assert on wrong state)
- [ ] `valueOr(default)` accessor
- [ ] `andThen(fn)` for monadic chaining (where `fn: T -> Result<U, Error>`)
- [ ] `map(fn)` for value transformation (where `fn: T -> U`)
- [ ] `Error` is a simple struct with a `code` enum and a `message` string
- [ ] Unit tests cover every public method
- [ ] Code follows `docs/standards/coding-standards.md` §C++

## Dependencies

- `infra-bootstrap` (needs `.clang-format` + `.clang-tidy` landed so BLD-001
  can be formatted/linted in CI)
