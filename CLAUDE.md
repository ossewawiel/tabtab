# CLAUDE.md — Project TabTab

## Project Overview

TabTab is an open-source visual UI designer and builder for creating cross-platform
desktop applications using Compose Multiplatform. It combines a drag-and-drop visual
form designer with live data preview, a built-in code editor, and a reactive/signals-based
data flow model. Projects are stored as YAML (.tt.yaml) and exported as fully owned
Kotlin/Compose Multiplatform source code.

**Core problem:** Existing visual UI builders are bloated, subscription-based, and
disconnected from real data. TabTab lets developers see real API/database data flowing
through their UI at design time.

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Builder application | C++ | Visual designer, code editor, live preview |
| Builder rendering | Skia (BSD license) | GPU-accelerated 2D rendering |
| Builder widgets | Custom (not Qt) | Material Design 3 + Fluent components |
| Project format | YAML (.tt.yaml) | Component tree, signals, bindings, themes |
| Code editor | Scintilla (embedded) | Kotlin syntax highlighting, VB6-style toggle |
| Live data engine | C++ (libcurl, libpq) | Design-time REST/SQL/file data fetching |
| Quick-run preview | JVM subprocess | Compile + run Kotlin project (~3-5 sec) |
| Code generator | C++ → Kotlin source | YAML to idiomatic Compose Multiplatform |
| Output framework | Compose Multiplatform | Cross-platform desktop UI (Skia-based) |
| Output language | Kotlin/JVM | Generated application code |
| Build system (output) | Gradle (Kotlin DSL) | Standard Kotlin build tool |
| Build system (builder) | CMake | C++ project build |
| Testing (builder) | Google Test | C++ unit tests |
| Testing (output) | JUnit 5 + Kotlin Test | Generated code tests |

## Two-Component Architecture (CRITICAL)

The system has TWO distinct components. Never confuse them:

1. **The Builder** — A C++ desktop application (what developers use to design UIs)
2. **The Output** — Kotlin/JVM applications (what developers ship to users)

These are connected ONLY by the .tt.yaml project format and the code generation pipeline.
The Builder has NO runtime dependency in the Output. Once exported, the developer owns
the code completely.

## Reactive Signals Model (CRITICAL)

All state in TabTab flows through reactive signals. This is the core data flow model:

| Signal Type | YAML | C++ Builder | Kotlin Export |
|------------|------|-------------|---------------|
| Signal<T> | type + default | SignalNode<T> | MutableStateFlow<T> |
| Computed<T> | type + derive | ComputedNode<T> | StateFlow<T> via combine/map |
| DataSource<T> | type + source | DataSourceNode<T> | Repository + StateFlow<T> |
| Effect | effect + watch | EffectNode | LaunchedEffect / snapshotFlow |
| Resource<T> | type + source + loading | ResourceNode<T> | sealed class |

### Rules for AI Agents
1. Every piece of UI state MUST be a signal — no exceptions
2. Signal dependencies form a DAG — circular dependencies are errors
3. Changes propagate via batched updates (once per frame tick)
4. The `=>` arrow in YAML means "signal binding" — it's reactive, not static
5. Simple derivations go inline in YAML; complex logic references Kotlin handlers

## YAML Project Format (.tt.yaml)

The .tt.yaml file is the single source of truth. Key sections:
- `schema` — Version number (required)
- `project` — Name, version, targets (required)
- `theme` — Design system, palette, overrides
- `dataSources` — REST, GraphQL, SQL, file, OS API connections
- `models` — Data types (→ Kotlin data classes)
- `signals` — Reactive state (→ StateFlow in ViewModels)
- `screens` — Component trees (→ @Composable functions)
- `navigation` — Screen flow (→ Compose Navigation)
- `assets` — Images, fonts, icons

### Binding Syntax
- `value: "Hello"` → Static value
- `value: => mySignal` → Signal binding (reactive)
- `onClick: handleSave` → Event handler reference (→ Kotlin function)

### Rules for AI Agents
1. YAML is declarative — complex logic belongs in Kotlin handler files
2. Every `=>` binding must reference a defined signal
3. Component IDs are optional — only add when referenced by handlers
4. Event handlers are inline on the component (`onClick: handleX`)
5. Credentials go in `.tt.secrets`, NEVER in `.tt.yaml`

## Code Generation

The generator produces idiomatic Kotlin/Compose Multiplatform code:
- Models → `data class` / `enum class` in `models/`
- Signals → `MutableStateFlow` / `combine` in `viewmodels/`
- DataSources → Repository classes in `repositories/`
- Screens → `@Composable` functions in `screens/`
- Navigation → `NavHost` in `navigation/`
- Handlers → User-written files in `handlers/` (NEVER overwritten)

### Rules for AI Agents
1. Generated code must look human-written — no obfuscation
2. User handler files are SACRED — never overwrite
3. Same YAML input must always produce same Kotlin output (deterministic)
4. Embedded hash comment tracks modifications for re-export detection

## Project Structure

```
tabtab/
├── .claude/
│   ├── commands/                    # Claude Code slash commands
│   │   ├── plan-feature.md          # Decompose feature into stories + GitHub issues
│   │   ├── process-feature.md       # Generate implementation plans + handover docs
│   │   ├── implement-story.md       # TDD implementation with auto-tracking
│   │   ├── process-issue.md         # Investigate external issues, create handovers
│   │   ├── fix-story.md             # Fix issues found during review
│   │   ├── close-handover.md        # Close completed feature handovers
│   │   ├── create-issue.md          # Create GitHub issue from description
│   │   ├── sync-github.md           # Sync local docs with GitHub state
│   │   ├── create-release.md        # Tag release, generate changelog
│   │   └── update-readme.md         # Regenerate README from current state
│   ├── settings.json
│   └── settings.local.json
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug-report.yml           # Bug report form
│   │   ├── feature-request.yml      # Feature request form
│   │   └── sprint-task.yml          # Sprint task form
│   └── workflows/
│       ├── ci-builder.yml           # C++ builder CI (CMake + Skia)
│       ├── ci-codegen.yml           # Code generator tests
│       ├── ci-output.yml            # Generated Kotlin project CI (Gradle)
│       └── release.yml              # Release pipeline
├── builder/                         # C++ builder application
│   ├── CMakeLists.txt
│   ├── src/
│   │   ├── main.cpp
│   │   ├── core/                    # Signal graph, YAML parser, layout engine
│   │   ├── rendering/               # Skia rendering, widget set
│   │   ├── designer/                # Design canvas, drag-drop, property panel
│   │   ├── data/                    # Live data engine (REST, SQL, file connectors)
│   │   ├── codegen/                 # Code generation pipeline
│   │   └── editor/                  # Scintilla integration
│   ├── include/
│   ├── tests/                       # C++ unit tests (Google Test)
│   └── third_party/                 # Skia, Scintilla, libcurl, etc.
├── output-template/                 # Template for generated Kotlin projects
│   ├── build.gradle.kts.template
│   ├── settings.gradle.kts.template
│   └── src/
├── tests/                           # Integration tests
│   ├── codegen/                     # YAML → Kotlin generation tests
│   │   ├── fixtures/                # .tt.yaml test fixtures
│   │   └── expected/                # Expected Kotlin output
│   └── e2e/                         # End-to-end tests
├── docs/
│   ├── architecture/                # Technical architecture (from .docx specs)
│   │   ├── architecture.md
│   │   ├── yaml-schema.md
│   │   ├── signal-system.md
│   │   ├── component-library.md
│   │   └── code-generation.md
│   ├── standards/
│   │   ├── coding-standards.md      # C++ and Kotlin coding standards
│   │   ├── tdd-guidelines.md        # Test-driven development process
│   │   └── cicd-quality.md          # CI/CD and quality gates
│   ├── specs/
│   │   ├── requirements/
│   │   │   ├── builder.md           # Builder (C++) stories
│   │   │   ├── codegen.md           # Code generator stories
│   │   │   ├── output.md            # Output framework stories
│   │   │   └── infra.md             # Infrastructure stories
│   │   ├── features/                # Per-feature specs and handovers
│   │   └── templates/
│   │       ├── handover.md          # Handover document template
│   │       ├── investigation.md     # Bug investigation template
│   │       └── story.md             # Story template
│   └── reference/
│       ├── skia-guide.md            # Skia API quick reference
│       ├── compose-mapping.md       # TabTab → Compose widget mapping
│       └── yaml-examples.md         # Example .tt.yaml projects
├── examples/                        # Example TabTab projects
│   ├── hello-world/
│   │   └── project.tt.yaml
│   ├── customer-manager/
│   │   ├── project.tt.yaml
│   │   └── handlers/
│   └── todo-app/
│       └── project.tt.yaml
├── CLAUDE.md                        # Master context for Claude Code agents
├── README.md
├── LICENSE
├── .gitignore
├── .env.example
└── setup.sh                         # One-command dev environment setup
```

## Important Documentation

Read these documents in order before starting work:

1. `docs/architecture/architecture.md` — System overview and builder architecture
2. `docs/architecture/yaml-schema.md` — Complete .tt.yaml format specification
3. `docs/architecture/signal-system.md` — Reactive signal primitives and graph
4. `docs/architecture/component-library.md` — All 30 components with schemas
5. `docs/architecture/code-generation.md` — Generation pipeline and mappings
6. `docs/standards/coding-standards.md` — C++ and Kotlin coding conventions
7. `docs/standards/tdd-guidelines.md` — Test-driven development process

## Platform Prefixes for Stories

| Prefix | Platform | Directory |
|--------|----------|-----------|
| BLD-xxx | Builder (C++/Skia) | `builder/` |
| GEN-xxx | Code Generator | `builder/src/codegen/` |
| OUT-xxx | Output Framework | `output-template/` |
| INF-xxx | Infrastructure/CI | `.github/`, `infra/` |
| DOC-xxx | Documentation | `docs/` |
| TT-xxx | Cross-cutting | Multiple |

## Development Environment

### Prerequisites
- C++20 compiler (GCC 13+ or Clang 16+ or MSVC 2022+)
- CMake 3.28+
- Python 3.10+ (for build scripts)
- Java 21+ (for quick-run preview JVM)
- Kotlin 2.0+ (for output project testing)
- Gradle 8.10+ (for output project building)
- Git
- GitHub CLI (`gh`)

### Build Commands
```bash
# Builder (C++)
cd builder && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
cmake --build . --parallel

# Run builder tests
cd builder/build && ctest --output-on-failure

# Test code generation
cd tests/codegen && python run_tests.py

# Build example output project
cd examples/customer-manager/exported && ./gradlew build
```

## Conventions

### C++ (Builder)
- Namespace: `tabtab::`
- File naming: `snake_case.cpp` / `snake_case.h`
- Class naming: `PascalCase`
- Member variables: trailing underscore (`value_`, `isDirty_`)
- Smart pointers: `std::unique_ptr` for ownership, raw pointers for non-owning references
- Include guards: `#pragma once`
- Formatting: `clang-format` with project `.clang-format`

### Kotlin (Generated Output)
- Package: derived from `project.package` in `.tt.yaml`
- File naming: `PascalCase.kt` (one class per file)
- Generated files: hash comment header for modification detection
- Serialization: `kotlinx.serialization`
- HTTP: Ktor client
- Async: Kotlin coroutines + Flow

### YAML (.tt.yaml)
- Indent: 2 spaces
- Signal names: `camelCase`
- Model names: `PascalCase`
- Screen names: `camelCase`
- Component IDs: `camelCase`
