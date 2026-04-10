# TabTab Coding Standards

This document defines the coding conventions for all TabTab source code. Every
Claude Code agent and human contributor must follow these standards before
opening a PR.

The standards cover four languages/formats:

1. [C++ (Builder)](#c-builder)
2. [Kotlin (Generated Output)](#kotlin-generated-output)
3. [YAML (`.tt.yaml` project files)](#yaml-ttyaml-project-files)
4. [Git conventions](#git-conventions)

---

## C++ (Builder)

### Language version
- **C++20** is the baseline. Use concepts, `std::span`, `std::format`, ranges,
  `constexpr` where they improve clarity.
- Compiler targets: GCC 13+, Clang 16+, MSVC 19.38+ (VS 2022 17.8+).
- Do **not** use C++23-only features without prior agreement — we care about the
  three-compiler portability guarantee.

### Naming

| Entity | Convention | Example |
|---|---|---|
| Namespace | `snake_case`, rooted at `tabtab::` | `tabtab::codegen` |
| File | `snake_case.cpp` / `snake_case.h` | `signal_graph.cpp` |
| Class / struct | `PascalCase` | `SignalNode`, `YamlParser` |
| Enum type | `PascalCase` | `NodeKind` |
| Enum value | `PascalCase` (scoped enums only) | `NodeKind::Computed` |
| Function | `camelCase` | `resolveDependencies()` |
| Local variable | `camelCase` | `childNodes` |
| Member variable | `camelCase_` trailing underscore | `value_`, `isDirty_` |
| Constant / constexpr | `kPascalCase` | `kMaxDepth` |
| Macro | `TABTAB_SCREAMING_SNAKE` (avoid unless unavoidable) | `TABTAB_ASSERT` |

**Hungarian notation is forbidden.** The type is already in the declaration.

### File structure
- Header guard: `#pragma once`. Never use include guards.
- Include order (each group separated by a blank line):
  1. Matching header for this .cpp (e.g. `foo.cpp` includes `"foo.h"` first)
  2. C++ standard library (`<vector>`, `<string>`, ...)
  3. Third-party (Skia, fmt, yaml-cpp, ...)
  4. Project headers (`"tabtab/..."`)

### Memory and ownership
- **Default to value semantics.** Pass by const reference for non-owning reads,
  by value for sinks, by rvalue reference for moves.
- Ownership: `std::unique_ptr<T>` for single owners, `std::shared_ptr<T>` only when
  shared ownership is genuinely required (most code paths don't need it).
- Non-owning references: raw pointers (`T*`) or references (`T&`). Never `new`/`delete`.
- Containers: prefer `std::vector`. Reach for `std::unordered_map` only when
  hashing cost is justified; otherwise `std::map`.

### Error handling
- **No exceptions in hot paths** (signal graph tick, render loop, layout pass).
- Prefer a `Result<T, Error>` type (header in `builder/include/tabtab/result.h`)
  for fallible operations in core subsystems.
- Exceptions are acceptable in I/O and initialization code (YAML parsing,
  file load) where the failure is terminal for that operation.
- `TABTAB_ASSERT(condition, message)` for preconditions that must hold; crashes
  in debug, documents intent in release.

### Formatting
- All C++ files are formatted by `clang-format` using the project's
  `.clang-format` file (to be added in INF-002).
- Line length: **100 columns**.
- Indent: **4 spaces**, no tabs.
- Brace style: Allman for namespaces and class bodies, K&R for functions and
  control flow. (`clang-format` enforces.)
- Pointer/reference alignment: `T* ptr`, `T& ref` (left-aligned to the type).

### Comments
- Use `//` for line comments, `/** ... */` for Doxygen-style doc comments.
- Document the **why**, not the what.
- Public API in headers must have doc comments. Implementation files rarely need
  comments — if you feel the need to explain, rename or restructure instead.
- `TODO(name): ...` and `FIXME(name): ...` with a name attribution.

### Testing
- Every non-trivial class in `core/`, `codegen/`, and `data/` has a Google Test
  file in `builder/tests/`.
- Test file name: `test_<unit>.cpp`.
- Test name: `TEST(<ClassName>, <scenario>_<expected>)` — e.g.
  `TEST(SignalGraph, addsNodeWithNoDependencies_succeeds)`.
- See `docs/standards/tdd-guidelines.md` for the red-green-refactor process.

### What not to do
- No raw `new`/`delete`.
- No `using namespace` at file scope (ever). At function scope only if it makes
  a call site obviously cleaner.
- No exception specifiers other than `noexcept`.
- No singletons — use dependency injection via constructor.
- No global mutable state. Period.

---

## Kotlin (Generated Output)

The generated Kotlin code must look **hand-written**. A developer inspecting the
output for the first time should not be able to tell it was generated (other than
from the hash comment header).

### Language version
- **Kotlin 2.0+** targeting JVM 21.
- Compose Multiplatform 1.7+.

### Naming

Follow the [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html) exactly:

| Entity | Convention | Example |
|---|---|---|
| Package | lowercase, dot-separated | `com.example.myapp.viewmodels` |
| File | `PascalCase.kt` (match the primary declaration) | `CustomerListViewModel.kt` |
| Class / interface | `PascalCase` | `CustomerRepository` |
| Function | `camelCase` | `fetchCustomers()` |
| Composable function | `PascalCase` | `@Composable fun CustomerList(...)` |
| Property | `camelCase` | `isLoading` |
| Constant | `SCREAMING_SNAKE_CASE` (top-level `const val`) | `const val MAX_RETRIES = 3` |

### File structure
- **One primary class per file.** File name matches the class.
- Package declaration first, then imports (sorted), then the class.
- Do not use wildcard imports except for Compose (`androidx.compose.material3.*`
  is fine, but explicit imports preferred).

### State and reactivity
- All state lives in `MutableStateFlow<T>` inside a ViewModel. Expose as
  `StateFlow<T>` (use `asStateFlow()`).
- Derived state uses `combine`, `map`, `stateIn` — never manual observation.
- UI consumes state via `collectAsStateWithLifecycle()` (or
  `collectAsState()` if lifecycle-aware isn't available).
- Side effects go inside `LaunchedEffect`, `DisposableEffect`, or `snapshotFlow`.
- Never call suspending functions from composables directly — wrap in `LaunchedEffect`.

### Serialization and HTTP
- JSON: `kotlinx.serialization` (`@Serializable` data classes).
- HTTP: Ktor client with the `ContentNegotiation` plugin and `Json` serializer.
- Configure one `HttpClient` per repository, not per request.
- Never block — all network calls are `suspend`.

### Coroutines
- Use structured concurrency. Every `launch` / `async` has a clear scope.
- `viewModelScope` for view-model-bound work, `CoroutineScope(Dispatchers.IO)`
  explicitly only when lifecycle doesn't match.
- Dispatcher usage: `Dispatchers.IO` for network/disk, `Dispatchers.Default` for
  CPU, `Dispatchers.Main` for UI (default for composables).

### Composables
- `@Composable` functions are `PascalCase` and return `Unit`.
- Stateful composables take a `Modifier` as the first optional parameter, default
  `Modifier`.
- Preview composables are in the same file, suffixed `Preview`, marked `@Preview`.
- Avoid passing ViewModels into composables. Hoist state: composables take
  `state: StateFlow<T>` and `onEvent: (Event) -> Unit`.

### Generated file header
Every generated file starts with:

```kotlin
// ===============================================================
// This file was generated by TabTab. Do not edit directly.
// Source: customer-manager.tt.yaml
// Generator version: 0.1.0
// Content hash: a3f8c2d1
// ===============================================================
```

If the hash doesn't match the file content on re-export, the builder warns and
asks before overwriting. Files in `handlers/` are never generated — they are
sacred user code.

---

## YAML (.tt.yaml project files)

### Indentation
- **2 spaces.** Never tabs.

### Naming

| Entity | Convention | Example |
|---|---|---|
| Signal name | `camelCase` | `selectedCustomerId` |
| Model name | `PascalCase` | `Customer` |
| Model field | `camelCase` | `firstName` |
| Screen name | `camelCase` | `customerList` |
| Component ID | `camelCase` (optional) | `saveButton` |
| Data source ID | `camelCase` | `customersApi` |

### File header
Every `.tt.yaml` starts with the schema version:

```yaml
schema: 1
```

Missing the schema field is a hard validation error.

### Binding syntax
- `value: "literal"` — static string.
- `value: 42` — static number.
- `value: => signalName` — reactive binding to a signal.
- `value: => signalA + signalB` — reactive binding to an inline expression (kept simple).
- `onClick: handlerName` — reference to a Kotlin function in `handlers/`.

**Rules:**
- Every `=>` binding must reference a defined signal. Referencing an undefined
  signal is a hard validation error.
- Inline expressions are limited to arithmetic, comparison, boolean, and string
  concatenation. Anything more complex belongs in a `Computed` signal or a handler.

### Validation rules (authoritative: `docs/architecture/yaml-schema.md`)
- `schema` required.
- `project.name` and `project.version` required.
- Every `screens.*.root` must be a known component.
- Every component must satisfy its schema (from the component library).
- Every `=>` binding must resolve.
- No circular signal dependencies.

### What not to put in `.tt.yaml`
- **Credentials.** Never. Put them in `.tt.secrets` (gitignored, referenced by
  `${secret:name}`).
- **Business logic.** Goes in Kotlin handler files.
- **Platform-specific code.** Use conditional theme or screen variants instead.

---

## Git conventions

### Branching
- `main` — protected. Direct pushes forbidden.
- `feature/<name>` — new features. Name matches the feature spec's kebab-case name.
- `fix/<issue-number>-<short-desc>` — bug fixes. Reference the issue number.
- `release/<version>` — short-lived release branches when cutting a release.
- `docs/<topic>` — doc-only changes.

### Commit messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short summary

Optional longer body explaining the *why* (not the what — the diff shows that).

Refs: BLD-007, #42
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `ci`, `build`.

**Scopes (common):** `builder`, `codegen`, `output`, `signal`, `yaml`, `docs`, `ci`.

Examples:
- `feat(signal): add batched propagation tick`
- `fix(codegen): escape quotes in generated string literals`
- `docs(standards): expand Kotlin naming table`

Rules:
- Subject line ≤ 72 characters.
- Subject line imperative mood ("add", not "added" or "adds").
- Body explains motivation and trade-offs, not implementation.
- Reference story IDs and issue numbers in a `Refs:` footer.

### Pull requests
- Title matches the conventional commit format.
- Description must include:
  - Link to the story or feature spec
  - Summary (1-3 bullets)
  - Test plan (bulleted checklist)
  - Screenshots / YAML diffs for UI or generator changes
- At least one CI check must pass and at least one human approval.
- Squash-merge by default. Rebase-merge for series where the history matters.

### What not to do
- No `--force` pushes to any shared branch.
- No `--no-verify` or `--no-gpg-sign` unless explicitly requested.
- No merging your own PR without a review (except for pure doc typo fixes).
- No committing generated files, build artifacts, or `.env` contents.
