# Infrastructure — Story Backlog

Stories for CI/CD, build systems, tooling, and repository infrastructure.
Use prefix `INF-` for all IDs.

Platform: **infra** — directories: `.github/`, `scripts/`, root configs.

See `docs/standards/cicd-quality.md` for the CI pipeline and quality gates.

## Status legend
- 📋 Planned
- 🔄 In progress
- 👀 In review
- ✅ Done
- ❌ Cancelled

---

<!-- New stories go here. /plan-feature appends to this file. -->

### INF-001 — Add `.clang-format` config and CMake target
**Feature:** infra-bootstrap
**Phase:** 1
**Status:** 📋 Planned

Add a project-wide `.clang-format` at the repo root with the settings called
out in `docs/standards/coding-standards.md` §C++ (100-col lines, 4-space
indent, Allman for namespaces/classes, K&R for functions, left-aligned
pointers). Wire a `clang-format` CMake target that formats every file under
`builder/src/` and `builder/include/` in place, plus a `clang-format-check`
target that fails CI if any file would change.

**Acceptance criteria:**
- [ ] `.clang-format` at repo root, BasedOnStyle: Google with the overrides above
- [ ] `cmake --build build --target clang-format` formats all builder C++ files
- [ ] `cmake --build build --target clang-format-check` exits non-zero if anything needs reformatting
- [ ] `ci-builder.yml` runs `clang-format-check` and fails the build on drift
- [ ] The skeleton files (`main.cpp`, `test_smoke.cpp`) already pass the check

---

### INF-002 — Add `.clang-tidy` config and CMake target
**Feature:** infra-bootstrap
**Phase:** 1
**Status:** 📋 Planned

Add a `.clang-tidy` at the repo root enabling a sensible check set
(bugprone-*, cppcoreguidelines-*, modernize-*, performance-*, readability-*,
minus the noisy checks we don't care about). Wire a `clang-tidy` CMake target
that runs it against every file in the compile database.

**Acceptance criteria:**
- [ ] `.clang-tidy` at repo root with the check set documented in the file header
- [ ] `cmake --build build --target clang-tidy` runs against all builder C++ files
- [ ] `CMAKE_EXPORT_COMPILE_COMMANDS=ON` set in the top-level CMakeLists
- [ ] `ci-builder.yml` runs the target and fails on any warning
- [ ] The skeleton files already pass

---

### INF-003 — Add pre-commit hooks for C++ format and YAML lint
**Feature:** infra-bootstrap
**Phase:** 1
**Status:** 📋 Planned

Add `.pre-commit-config.yaml` wiring `clang-format` for C++ staged files,
`yamllint` for `.tt.yaml` files under `examples/` and `.github/workflows/`,
and a trailing-whitespace / end-of-file-fixer pass.

**Acceptance criteria:**
- [ ] `.pre-commit-config.yaml` at repo root
- [ ] Hooks: `clang-format`, `yamllint`, `trailing-whitespace`, `end-of-file-fixer`
- [ ] `pre-commit run --all-files` green on the current scaffold
- [ ] README has a "Developer setup" subsection that mentions `pre-commit install`

---

### INF-004 — Add GitHub PR description template
**Feature:** infra-bootstrap
**Phase:** 1
**Status:** 📋 Planned

Add `.github/pull_request_template.md` with the exact checklist shown in
`docs/standards/cicd-quality.md` under "PR description template". Every new
PR should open with that template pre-filled.

**Acceptance criteria:**
- [ ] `.github/pull_request_template.md` exists
- [ ] Body matches the template in `docs/standards/cicd-quality.md` §PR description template
- [ ] Opening a draft PR in the repo shows the template pre-filled (verified manually)
