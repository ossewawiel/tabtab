# CI/CD and Quality Gates

This document defines the quality gates every change to TabTab must pass, the CI
pipeline that enforces them, and the release process.

## Quality gates per component

Every pull request must pass the gates relevant to the files it touches. CI skips
irrelevant gates via path filters (see `.github/workflows/*.yml`).

### Builder (C++)

Enforced by `.github/workflows/ci-builder.yml`. Triggered on changes to `builder/**`.

| Gate | Tool | Blocking? |
|---|---|---|
| Configure | CMake 3.28+ | Yes |
| Compile | GCC 13+ / Clang 16+ (Linux CI) | Yes |
| Unit tests | Google Test via `ctest` | Yes |
| Static analysis | `clang-tidy` with project config | Yes |
| Format check | `clang-format --dry-run` | Yes |
| Coverage | `gcov` / `lcov`, minimum 80% in `core/` | Yes |
| Sanitizers (nightly) | ASan + UBSan run | Non-blocking, reports |

### Code generator

Enforced by `.github/workflows/ci-codegen.yml`. Triggered on changes to
`builder/src/codegen/**` or `tests/codegen/**`.

| Gate | Tool | Blocking? |
|---|---|---|
| Fixture tests | `tests/codegen/run_tests.py` | Yes |
| Generated project compiles | `./gradlew build -x test` for every fixture | Yes |
| Generated project tests pass | `./gradlew test` for every fixture that has tests | Yes |

A generator change that produces a diff in `tests/codegen/expected/` fails until
the expected output is updated in the same PR with a justification.

### Output projects

Enforced by `.github/workflows/ci-output.yml`. Triggered on changes to
`output-template/**` or `examples/**`.

| Gate | Tool | Blocking? |
|---|---|---|
| Build | `./gradlew build` | Yes |
| Unit tests | JUnit 5 + Kotlin Test | Yes |
| Lint | `ktlint` | Yes |
| Compose preview compile | (implicit in Gradle build) | Yes |

### Documentation

Doc-only changes run a minimal gate: Markdown lint + broken link check. Not
currently blocking while the project is pre-alpha.

---

## Pull request requirements

A PR may merge to `main` when:

1. **All applicable CI checks are green.**
2. **At least one review approval** from someone other than the author.
   - Trivial doc typo fixes can be self-approved with maintainer discretion.
3. **No unresolved review comments.**
4. **Branch is up to date with `main`** (rebase, don't merge).
5. **Conventional commit format** on the squash commit subject.
6. **Linked story or issue** in the PR body.

### PR description template (enforced by CI in INF-004)

```markdown
## Summary
- What changed (1-3 bullets)

## Story / issue
- Refs: BLD-007, #42

## Test plan
- [ ] Unit tests added / updated
- [ ] CI green
- [ ] Manual verification (if applicable)

## Screenshots / YAML diffs
(only if UI or codegen output changes)
```

---

## Branch protection (configured on GitHub)

The `main` branch has these protection rules:

- **Require a pull request before merging.** Direct pushes forbidden.
- **Require approvals: 1** (more as the team grows).
- **Dismiss stale approvals when new commits are pushed.**
- **Require status checks to pass before merging:**
  - `Builder CI / Build & Test (C++)` (when builder files change)
  - `CodeGen CI / Code Generation Tests` (when codegen files change)
  - `Output CI / Build Example Projects` (when output files change)
- **Require branches to be up to date before merging.**
- **Require conversation resolution before merging.**
- **Include administrators** (yes — maintainers follow the same rules).
- **Do not allow bypassing the above.**
- **Allow force pushes: NO.**
- **Allow deletions: NO.**

Initial setup is a one-time maintainer action. Re-run via
`scripts/init-github.sh` (which will print the `gh api` calls needed).

---

## Release process

TabTab follows [semantic versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

### When to bump

- **MAJOR** — incompatible change to the `.tt.yaml` schema or the generated
  output layout that breaks existing projects.
- **MINOR** — new features, new components, new generator capabilities, new
  data source connectors. Backward compatible.
- **PATCH** — bug fixes, performance improvements, doc updates, internal refactors.

### Release cycle

1. **During a phase:** merge feature PRs into `main`. Each merge may trigger a
   prerelease tag (`v0.1.0-beta.N`) if the maintainer chooses.
2. **Phase complete:** all stories in the phase's GitHub milestone are closed.
   The maintainer runs `/create-release` which:
   - Validates CI is green on `main`
   - Computes the next version (or accepts an explicit one)
   - Updates `builder/CMakeLists.txt` `project(... VERSION x.y.z)`
   - Regenerates `CHANGELOG.md` from closed issues since the last tag
   - Creates a commit `chore: release v{version}`
   - Creates a signed tag `v{version}`
   - Pushes the tag (with explicit approval)
3. **Tag push triggers** `.github/workflows/release.yml`:
   - Extracts the changelog entry for that version
   - Creates a GitHub Release
   - (Future) Uploads prebuilt builder binaries per platform
4. **Milestone closed** via `/close-handover`.

### Changelog generation

`CHANGELOG.md` is generated from GitHub issues closed since the previous tag,
grouped by `type:` label:

- **Features** — `type:feature`
- **Bug fixes** — `type:bug`
- **Improvements** — `type:improvement`
- **Maintenance & docs** — `type:maintenance`, `type:docs`

Format:

```markdown
## v0.2.0 — 2026-06-15

### Features
- [BLD-007] Batched signal propagation tick — #42
- [GEN-012] Emit StateFlow combine for Computed — #51

### Bug fixes
- [BLD-015] YAML parser rejects trailing commas — #58

### Improvements
- [GEN-014] Generated code now uses trailing commas — #60
```

Manual editing of the generated entry is allowed before committing.

---

## Local quality checks

Before pushing, run the equivalent of CI locally:

```bash
# C++ builder
cd builder
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DTABTAB_ENABLE_COVERAGE=ON
cmake --build build --parallel
cd build && ctest --output-on-failure
cmake --build . --target clang-format-check
cmake --build . --target clang-tidy

# Code generator fixtures
cd tests/codegen && python run_tests.py

# Output example
cd examples/hello-world/exported && ./gradlew build
```

Pre-commit hooks (to be added in INF-003) will run format checks automatically.
