---
feature: infra-bootstrap
platform: infra
stories: [INF-001, INF-002, INF-003, INF-004]
status: pending
dependencies: []
created: 2026-04-11
---

# Infra Handover: Infra Bootstrap

## Context

TabTab's builder is a C++20 application under `builder/` using CMake 3.28+ and
Google Test via `FetchContent`. Target compilers are GCC 13+, Clang 16+, and
MSVC 19.38+. The repo already contains a compiling skeleton (`builder/src/main.cpp`,
`builder/tests/test_smoke.cpp`, `builder/CMakeLists.txt`) with stub
`clang-format` / `clang-tidy` CMake targets that only print a placeholder
message. This feature replaces those stubs with real, enforced tooling.

Per `docs/standards/coding-standards.md` §C++, the formatting contract is:
**Google base, 100-col lines, 4-space indent, Allman for namespaces/class bodies,
K&R for functions and control flow, `T* ptr` / `T& ref` left-aligned, `#pragma once`
header guards, include groups separated by blank lines.** The naming conventions
(`PascalCase` classes, `camelCase` functions, `camelCase_` member vars, `kPascalCase`
constants) are enforced by `clang-tidy` check `readability-identifier-naming`.

CI is `.github/workflows/ci-builder.yml`, which already runs configure, build,
`ctest`, and a `clang-tidy` step that currently no-ops. It does **not** yet run
`clang-format-check`. That is added here.

Pre-commit hooks are a third-party convention via `pre-commit.com`; the config
lives at repo root as `.pre-commit-config.yaml`. Hook revisions must be pinned
(no `main`). The README's existing "Developer setup" section needs a line about
`pre-commit install`.

Branch protection is currently off (see `docs/standards/cicd-quality.md`), so
the PR description template from INF-004 is advisory rather than gated — but it
still pre-fills every new PR.

## Tasks

| # | Task | Story ID | Status | Files |
|---|------|----------|--------|-------|
| 1 | Add `.clang-format` config and wire `clang-format` + `clang-format-check` CMake targets; reformat skeleton; add format-check step to `ci-builder.yml` | INF-001 | ✅ Complete | `.clang-format`, `builder/CMakeLists.txt`, `builder/src/main.cpp`, `builder/tests/test_smoke.cpp`, `.github/workflows/ci-builder.yml` |
| 2 | Add `.clang-tidy` config, enable `CMAKE_EXPORT_COMPILE_COMMANDS`, wire `clang-tidy` CMake target against compile database; make skeleton clean; ensure `ci-builder.yml` `clang-tidy` step now runs the real target | INF-002 | ✅ Complete | `.clang-tidy`, `builder/CMakeLists.txt`, `builder/cmake/strip-modmap.cmake`, `builder/src/main.cpp`, `.github/workflows/ci-builder.yml` |
| 3 | Add `.pre-commit-config.yaml` with `clang-format`, `yamllint`, `trailing-whitespace`, `end-of-file-fixer` hooks; verify `pre-commit run --all-files` is green; update README developer setup | INF-003 | ⬜ Pending | `.pre-commit-config.yaml`, `.yamllint` (optional config), `README.md` |
| 4 | Add `.github/pull_request_template.md` matching the template in `docs/standards/cicd-quality.md` §PR description template | INF-004 | ⬜ Pending | `.github/pull_request_template.md` |

## Files to Create/Modify

### New Files

- `.clang-format` — Repo-root clang-format config. `BasedOnStyle: Google`,
  `ColumnLimit: 100`, `IndentWidth: 4`, `UseTab: Never`,
  `BreakBeforeBraces: Custom` with `AfterNamespace: true`, `AfterClass: true`,
  `AfterStruct: true`, `AfterEnum: true`, `AfterFunction: false`,
  `AfterControlStatement: Never`, `PointerAlignment: Left`,
  `ReferenceAlignment: Left`, `IncludeBlocks: Regroup` with project header
  categories (matching header → stdlib → third-party → `tabtab/*`).
  **Header the file with a comment block explaining the deviations from Google
  base and linking to `docs/standards/coding-standards.md` §C++.**
- `.clang-tidy` — Repo-root clang-tidy config. Enabled check groups:
  `bugprone-*`, `cppcoreguidelines-*`, `modernize-*`, `performance-*`,
  `readability-*`, `portability-*`, `misc-*`. Disable noisy checks that fight
  the coding standards: `modernize-use-trailing-return-type`,
  `readability-named-parameter`, `cppcoreguidelines-avoid-magic-numbers`,
  `readability-magic-numbers`, `cppcoreguidelines-pro-bounds-pointer-arithmetic`,
  `misc-non-private-member-variables-in-classes`,
  `cppcoreguidelines-non-private-member-variables-in-classes`. Configure
  `readability-identifier-naming` to enforce: `ClassCase: CamelCase`,
  `StructCase: CamelCase`, `FunctionCase: camelBack`, `VariableCase: camelBack`,
  `PrivateMemberSuffix: _`, `ProtectedMemberSuffix: _`,
  `ConstexprVariableCase: CamelCase`, `ConstexprVariablePrefix: k`,
  `EnumCase: CamelCase`, `EnumConstantCase: CamelCase`,
  `NamespaceCase: lower_case`. `WarningsAsErrors: '*'`. **Header the file with a
  comment block documenting the rationale for every disabled check.**
- `.pre-commit-config.yaml` — Pre-commit config. Pinned hooks:
  `pre-commit/pre-commit-hooks` v4.6.0 (`trailing-whitespace`, `end-of-file-fixer`,
  `check-yaml`, `check-merge-conflict`, `mixed-line-ending`);
  `pre-commit/mirrors-clang-format` v18.1.3 (`clang-format` against
  `files: ^builder/(src|include|tests)/.*\.(h|hpp|cpp)$`);
  `adrienverge/yamllint` v1.35.1 (`yamllint` against
  `files: ^(examples/.*\.tt\.yaml|\.github/workflows/.*\.ya?ml)$`,
  with `args: ['-c', '.yamllint']`).
- `.yamllint` — Relaxed yamllint config: `extends: default`,
  `rules: { line-length: disable, truthy: disable, indentation: { spaces: 2 },
  document-start: disable, comments-indentation: disable }`.
- `.github/pull_request_template.md` — Verbatim copy of the template in
  `docs/standards/cicd-quality.md` §PR description template, wrapped as the
  repository's default PR body.

### Modified Files

- `builder/CMakeLists.txt` — Remove the two `add_custom_target` stubs. Replace
  with: (a) a `file(GLOB_RECURSE TABTAB_CXX_SOURCES ...)` over
  `builder/src/**/*.{h,hpp,cpp}`, `builder/include/**/*.{h,hpp}`,
  `builder/tests/**/*.{h,hpp,cpp}`; (b) a `clang-format` target that runs
  `clang-format -i` via `execute_process` on the glob; (c) a
  `clang-format-check` target that runs `clang-format --dry-run --Werror` and
  exits non-zero on drift; (d) `set(CMAKE_EXPORT_COMPILE_COMMANDS ON)` at the
  top of the file; (e) a real `clang-tidy` target that runs `clang-tidy -p build`
  against the globbed sources. Each target `find_program`s its tool and
  `message(FATAL_ERROR ...)` if missing.
- `builder/src/main.cpp` — Re-run `clang-format -i` against it after `.clang-format`
  lands. No semantic changes. The existing file is close to the final format
  (already 4-space indent, Allman namespaces, K&R functions, `T*` left-aligned)
  but the glob + diff will surface minor drift.
- `builder/tests/test_smoke.cpp` — Same: re-format in place.
- `.github/workflows/ci-builder.yml` — Insert a `clang-format-check` step between
  "Run tests" and the existing "clang-tidy" step. Both steps invoke the CMake
  targets (not the tools directly) so local and CI invocations stay identical.
- `README.md` — Append a short "Developer setup" subsection mentioning
  `pip install pre-commit && pre-commit install`. Keep it to 4–5 lines.

## TDD Test Plan

INF-001–INF-004 are infrastructure/config work — per `docs/standards/tdd-guidelines.md`
§"What does not require TDD", tooling and build configuration land via
**smoke-style verification**, not unit tests. The equivalent of a "failing test"
is running the CMake target and observing the expected exit code.

Each story has a smoke-test matrix that must be executed locally before the
review checkpoint, and the Green state is **CI + a clean `pre-commit run --all-files`**.

| Smoke test | Tests what | Priority |
|------|-----------|----------|
| `cmake --build build --target clang-format-check` against an unformatted-on-purpose file exits non-zero | INF-001 check target actually detects drift | Must have |
| `cmake --build build --target clang-format` rewrites that same file in place | INF-001 format target actually reformats | Must have |
| `cmake --build build --target clang-format-check` on a fresh checkout exits zero | Skeleton already passes | Must have |
| `ci-builder.yml` fails on a PR that introduces a misformatted line | CI gate actually enforces the check | Must have |
| `cmake --build build --target clang-tidy` on a fresh checkout emits zero warnings | INF-002 skeleton already clean | Must have |
| `cmake --build build --target clang-tidy` against a file that introduces a `member_var` (wrong case) emits `readability-identifier-naming` and fails the build because of `WarningsAsErrors: '*'` | INF-002 check set actually flags naming violations | Must have |
| `find build -name compile_commands.json` exists after configure | INF-002 export of compile database | Must have |
| `pre-commit run --all-files` on a fresh checkout exits zero | INF-003 hooks don't false-positive on the current tree | Must have |
| Staging a file with trailing whitespace and running `pre-commit run` fails that hook | INF-003 hooks actually fire | Must have |
| Staging a misformatted `.cpp` file and running `pre-commit run clang-format` rewrites it | INF-003 clang-format hook points at the right binary | Must have |
| Staging a `.tt.yaml` file with a tab character and running `pre-commit run yamllint` fails | INF-003 yamllint hook targets TabTab project files | Should have |
| Opening a draft PR in the GitHub UI pre-fills the body from the template | INF-004 template is picked up by GitHub | Must have |
| The template body matches the §"PR description template" section in `docs/standards/cicd-quality.md` line-for-line | INF-004 fidelity | Must have |

Because there are no C++ unit tests to add, the **review checkpoint for each
story** should include a screenshot (or captured terminal output) of the smoke
matrix passing locally, plus a link to the CI run on the PR.

## Acceptance Criteria

### INF-001 — Add `.clang-format` config and CMake target

- [ ] `.clang-format` at repo root, BasedOnStyle: Google with the overrides above
- [ ] `cmake --build build --target clang-format` formats all builder C++ files
- [ ] `cmake --build build --target clang-format-check` exits non-zero if anything needs reformatting
- [ ] `ci-builder.yml` runs `clang-format-check` and fails the build on drift
- [ ] The skeleton files (`main.cpp`, `test_smoke.cpp`) already pass the check

### INF-002 — Add `.clang-tidy` config and CMake target

- [ ] `.clang-tidy` at repo root with the check set documented in the file header
- [ ] `cmake --build build --target clang-tidy` runs against all builder C++ files
- [ ] `CMAKE_EXPORT_COMPILE_COMMANDS=ON` set in the top-level CMakeLists
- [ ] `ci-builder.yml` runs the target and fails on any warning
- [ ] The skeleton files already pass

### INF-003 — Add pre-commit hooks for C++ format and YAML lint

- [ ] `.pre-commit-config.yaml` at repo root
- [ ] Hooks: `clang-format`, `yamllint`, `trailing-whitespace`, `end-of-file-fixer`
- [ ] `pre-commit run --all-files` green on the current scaffold
- [ ] README has a "Developer setup" subsection that mentions `pre-commit install`

### INF-004 — Add GitHub PR description template

- [ ] `.github/pull_request_template.md` exists
- [ ] Body matches the template in `docs/standards/cicd-quality.md` §PR description template
- [ ] Opening a draft PR in the repo shows the template pre-filled (verified manually)

## Definition of Done

- [ ] All tasks marked ✅ Complete
- [ ] Every story's acceptance criteria ticked on its GitHub issue
- [ ] Smoke-test matrix (above) executed and output captured in the story's PR description
- [ ] CI green on the feature branch: `ci-builder.yml` runs `clang-format-check` and `clang-tidy` against the real configs
- [ ] `pre-commit run --all-files` green on a fresh checkout of the feature branch
- [ ] No compiler warnings introduced in `builder/` (the skeleton's `-Wall -Wextra -Wpedantic` must stay clean)
- [ ] `clang-tidy` clean against the skeleton
- [ ] `docs/standards/coding-standards.md` §C++ §Formatting reference to INF-002 replaced with a link to the committed `.clang-format`
- [ ] `README.md` developer setup section mentions `pre-commit install`
- [ ] Review checkpoint approved per story before marking the GitHub issue `status:done`
