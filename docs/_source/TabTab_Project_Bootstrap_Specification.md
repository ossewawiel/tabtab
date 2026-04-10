# TabTab — Project Bootstrap Specification

## Purpose

This document is the complete blueprint for scaffolding the TabTab project repository. It contains everything a Claude Code agent needs to create the project structure, CLAUDE.md, slash commands, CI/CD pipelines, standards, templates, and documentation infrastructure. The agent should follow this document sequentially to build the full project scaffold.

## References

The following architecture documents define TabTab's technical design. These must be converted to markdown and placed in `docs/architecture/`:

1. **Architecture Document** — System overview, builder architecture, rendering, layout engine, design canvas, code editor
2. **YAML Schema Specification** — The .tt.yaml project format, all sections, binding syntax, validation rules
3. **Reactive Signal System** — Signal primitives, dependency graph, batched propagation, expression evaluator, code generation mapping
4. **Component Library Specification** — All 30 components with YAML schemas, properties, events, Compose export mappings
5. **Code Generation Pipeline** — Five-stage pipeline, YAML-to-Kotlin mapping, project structure, incremental builds, validation

---

## 1. Project Structure

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

---

## 2. CLAUDE.md

The CLAUDE.md file is the single most important file in the project. Every Claude Code agent reads it first. It must contain:

### 2.1 Content Structure

```markdown
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
4. The => arrow in YAML means "signal binding" — it's reactive, not static
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
2. Every => binding must reference a defined signal
3. Component IDs are optional — only add when referenced by handlers
4. Event handlers are inline on the component (onClick: handleX)
5. Credentials go in .tt.secrets, NEVER in .tt.yaml

## Code Generation

The generator produces idiomatic Kotlin/Compose Multiplatform code:
- Models → data class / enum class in models/
- Signals → MutableStateFlow / combine in viewmodels/
- DataSources → Repository classes in repositories/
- Screens → @Composable functions in screens/
- Navigation → NavHost in navigation/
- Handlers → User-written files in handlers/ (NEVER overwritten)

### Rules for AI Agents
1. Generated code must look human-written — no obfuscation
2. User handler files are SACRED — never overwrite
3. Same YAML input must always produce same Kotlin output (deterministic)
4. Embedded hash comment tracks modifications for re-export detection

## Project Structure

[Include the full directory tree from Section 1 above]

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
| BLD-xxx | Builder (C++/Skia) | builder/ |
| GEN-xxx | Code Generator | builder/src/codegen/ |
| OUT-xxx | Output Framework | output-template/ |
| INF-xxx | Infrastructure/CI | .github/, infra/ |
| DOC-xxx | Documentation | docs/ |
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
- GitHub CLI (gh)

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
- File naming: snake_case.cpp / snake_case.h
- Class naming: PascalCase
- Member variables: trailing underscore (value_, isDirty_)
- Smart pointers: std::unique_ptr for ownership, raw pointers for non-owning references
- Include guards: #pragma once
- Formatting: clang-format with project .clang-format

### Kotlin (Generated Output)
- Package: derived from project.package in .tt.yaml
- File naming: PascalCase.kt (one class per file)
- Generated files: hash comment header for modification detection
- Serialization: kotlinx.serialization
- HTTP: Ktor client
- Async: Kotlin coroutines + Flow

### YAML (.tt.yaml)
- Indent: 2 spaces
- Signal names: camelCase
- Model names: PascalCase
- Screen names: camelCase
- Component IDs: camelCase
```

---

## 3. Claude Code Commands (.claude/commands/)

Each command below is a complete slash command specification. The agent should create each as a separate .md file in `.claude/commands/`.

### 3.1 /plan-feature

**File:** `.claude/commands/plan-feature.md`

**Purpose:** Analyze a feature description, decompose into platform stories (BLD/GEN/OUT/INF), create GitHub issues with milestones.

**Adapted from:** geelkruiwa's `/beplan-funksionaliteit`

**Key differences from geelkruiwa:**
- Platform prefixes are BLD/GEN/OUT/INF instead of API/UI/DB
- Stories map to builder (C++), code generator, output framework, or infrastructure
- Sprint numbering follows TabTab's 5-phase roadmap
- Spec files go in `docs/specs/features/{feature-name}/`

**Process:**
1. Read existing stories from `docs/specs/requirements/{platform}.md` for ID numbering
2. Analyze feature description → extract platforms, capabilities, data involved
3. Decompose into atomic stories per platform
4. Present stories for approval
5. On approval: create stories in specs, create GitHub milestone, create GitHub issues with labels
6. Create feature spec in `docs/specs/features/{name}/spec.md`

**Labels:** `type:feature`, `type:bug`, `comp:builder`, `comp:codegen`, `comp:output`, `comp:infra`, `status:new`, `status:investigating`, `status:ready`, `status:in-progress`, `status:review`, `status:done`, `source:ai-agent`, `phase-1` through `phase-5`

**Hard constraints:**
- MAY NOT create handover documents (that's /process-feature)
- MAY NOT write code
- MAY NOT overwrite existing stories
- MUST get approval before creating anything

### 3.2 /process-feature

**File:** `.claude/commands/process-feature.md`

**Purpose:** Generate implementation plans and platform-specific handover documents for a planned feature.

**Adapted from:** geelkruiwa's `/verwerk-funksionaliteit`

**Process:**
1. Read feature spec from `docs/specs/features/{name}/spec.md`
2. Read architecture docs for context
3. Determine implementation order (typically: infrastructure → builder core → codegen → output)
4. Create implementation plan: `docs/specs/features/{name}/implementation-plan.md`
5. Create per-platform handover documents:
   - `builder-handover.md` — C++/Skia implementation details
   - `codegen-handover.md` — Code generation templates and mappings
   - `output-handover.md` — Kotlin/Compose output structure
   - `infra-handover.md` — CI/CD, build system changes
6. Update GitHub issues with handover references

**Handover document structure:**
```markdown
# {Platform} Handover: {Feature Name}

**Feature:** {name}
**Stories:** {list of story IDs}
**Status:** pending
**Dependencies:** {list}

## Context
{What the agent needs to know from architecture docs}

## Tasks
| # | Task | Story ID | Status |
|---|------|----------|--------|
| 1 | {task} | BLD-xxx | ⬜ Pending |

## Files to Create/Modify
{Specific file paths and what to do}

## Tests Required
{Specific test cases with TDD approach}

## Acceptance Criteria
{From GitHub issue}

## Definition of Done
- [ ] All tasks complete
- [ ] Tests pass
- [ ] Code follows standards
- [ ] Documentation updated
```

### 3.3 /implement-story

**File:** `.claude/commands/implement-story.md`

**Purpose:** Implement a story using TDD, with mandatory review checkpoint and auto-tracking.

**Adapted from:** geelkruiwa's `/implimenteer-storie`

**Process:**
1. Resolve story reference (GitHub issue number or story ID)
2. Find feature handover document
3. Extract story-specific context from handover
4. Update GitHub issue status → `status:in-progress`
5. Present implementation plan
6. Implement with TDD:
   a. Write test FIRST
   b. Verify test fails (Red)
   c. Implement minimal code to pass (Green)
   d. Refactor while tests stay green
7. **MANDATORY REVIEW CHECKPOINT** (MUST STOP HERE):
   - Present summary of implementation
   - Show verification instructions
   - Ask developer: "Is the story acceptable? Yes / No"
   - **DO NOT proceed to step 8 without explicit "Yes"**
8. Post-implementation tracking:
   a. Update `docs/specs/requirements/{platform}.md` — mark story as ✅ Done
   b. Update handover document — mark tasks as ✅ Complete
   c. Update implementation plan — mark story as ✅ Complete
   d. Comment on GitHub issue with implementation summary
   e. Update GitHub issue label → `status:done`
9. Report milestone progress and suggest next story

**Platform detection:**
- BLD-* → Builder (C++, builder/ directory)
- GEN-* → Code Generator (C++, builder/src/codegen/)
- OUT-* → Output Framework (Kotlin, output-template/)
- INF-* → Infrastructure (.github/, build configs)
- TT-* → Cross-cutting (check all platforms)

**Hard constraints:**
- MAY NOT decompose stories (that's /plan-feature)
- MAY NOT create handover documents (that's /process-feature)
- MAY NOT modify other stories' code
- MUST follow TDD for domain and service layer (see tdd-guidelines.md)
- MUST STOP at review checkpoint and WAIT for developer response
- MAY NOT update docs or GitHub before developer approval

### 3.4 /process-issue

**File:** `.claude/commands/process-issue.md`

**Purpose:** Investigate an externally-created GitHub issue, diagnose, and create handover documents.

**Adapted from:** geelkruiwa's `/verwerk-issue`

**Process:**
1. Fetch issue details from GitHub
2. Classify (bug, feature, improvement, maintenance)
3. Identify affected platforms
4. Update issue status → `status:investigating`
5. Investigate: read relevant code, trace data flow, identify root cause
6. Create investigation document: `docs/specs/features/issue-{n}/investigation.md`
7. If single platform → create single handover
8. If multi-platform → create implementation plan + per-platform handovers
9. Update GitHub issue with findings and handover references

### 3.5 /create-release

**File:** `.claude/commands/create-release.md`

**Purpose:** Tag a release, generate changelog, update version numbers.

**Process:**
1. Determine version from parameter or calculate next semantic version
2. Update version in CMakeLists.txt (builder) and relevant configs
3. Generate changelog from GitHub issues closed since last release
4. Create git tag
5. Push tag (triggers release workflow)

### 3.6 /update-readme

**File:** `.claude/commands/update-readme.md`

**Purpose:** Regenerate README.md from current project state.

---

## 4. CI/CD Workflows (.github/workflows/)

### 4.1 ci-builder.yml — Builder C++ CI

```yaml
name: Builder CI

on:
  pull_request:
    branches: [main]
    paths:
      - 'builder/**'
      - '.github/workflows/ci-builder.yml'

permissions:
  contents: read

jobs:
  build-test:
    name: Build & Test (C++)
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y cmake ninja-build libgl-dev libx11-dev

      - name: Cache Skia
        uses: actions/cache@v4
        with:
          path: builder/third_party/skia
          key: skia-${{ runner.os }}-${{ hashFiles('builder/scripts/fetch-skia.sh') }}

      - name: Fetch Skia (if not cached)
        run: cd builder && bash scripts/fetch-skia.sh

      - name: Configure CMake
        run: cd builder && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug

      - name: Build
        run: cd builder && cmake --build build --parallel

      - name: Run tests
        run: cd builder/build && ctest --output-on-failure

      - name: clang-tidy
        run: cd builder && cmake --build build --target clang-tidy

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: builder-test-results
          path: builder/build/test-results/
          retention-days: 14
```

### 4.2 ci-codegen.yml — Code Generator Tests

```yaml
name: CodeGen CI

on:
  pull_request:
    branches: [main]
    paths:
      - 'builder/src/codegen/**'
      - 'tests/codegen/**'
      - '.github/workflows/ci-codegen.yml'

permissions:
  contents: read

jobs:
  codegen-test:
    name: Code Generation Tests
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install pyyaml

      - name: Run codegen fixture tests
        run: cd tests/codegen && python run_tests.py

      - name: Verify generated projects compile
        run: |
          for dir in tests/codegen/output/*/; do
            echo "Building $dir..."
            cd "$dir" && ./gradlew build -x test && cd -
          done
```

### 4.3 ci-output.yml — Output Project CI

```yaml
name: Output CI

on:
  pull_request:
    branches: [main]
    paths:
      - 'output-template/**'
      - 'examples/**'
      - '.github/workflows/ci-output.yml'

permissions:
  contents: read

jobs:
  output-build:
    name: Build Example Projects
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Java 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('examples/**/*.gradle.kts') }}

      - name: Build hello-world example
        run: cd examples/hello-world/exported && ./gradlew build

      - name: Build customer-manager example
        run: cd examples/customer-manager/exported && ./gradlew build test
```

---

## 5. Standards Documents

### 5.1 docs/standards/coding-standards.md

Must cover:
- **C++ standards:** C++20, clang-format config, naming conventions (namespace tabtab::, PascalCase classes, snake_case files, trailing_ members), include ordering, smart pointer usage, error handling (Result<T> pattern, no exceptions in hot paths)
- **Kotlin standards:** Package naming, file structure, kotlinx.serialization, Ktor patterns, StateFlow conventions, Compose composable naming
- **YAML standards:** .tt.yaml schema rules, naming patterns (camelCase signals, PascalCase models), validation rules
- **Git conventions:** Branch naming (feature/{name}, fix/{name}, release/{version}), commit messages (conventional commits), PR templates

### 5.2 docs/standards/tdd-guidelines.md

Must cover:
- **Red-Green-Refactor cycle** — Write failing test → implement → refactor
- **What requires TDD:**
  - Signal graph engine (all graph operations)
  - YAML parser (all parsing and validation)
  - Code generator (all YAML → Kotlin mappings)
  - Layout engine (all flexbox calculations)
  - Expression evaluator (all supported operations)
- **What doesn't require TDD:**
  - Skia rendering (visual, tested manually)
  - UI interaction (design canvas events)
- **Test naming:** `test_[unit]_[scenario]_[expected]` for C++, backtick descriptions for Kotlin
- **Fixture-based testing for code generator:** .tt.yaml input → expected .kt output comparison
- **Coverage targets:** 80% for core (signal, parser, codegen), 60% for UI layer

### 5.3 docs/standards/cicd-quality.md

Must cover:
- **Quality gates per component:**
  - Builder (C++): compile, Google Test, clang-tidy, clang-format check
  - Code generator: fixture tests (YAML → Kotlin comparison), generated project compilation
  - Output projects: Gradle build, JUnit tests, ktlint
- **PR requirements:** All CI checks pass, at least one review
- **Branch protection:** main branch protected, require PR, require CI pass
- **Release process:** Semantic versioning, changelog generation, GitHub releases

---

## 6. Templates

### 6.1 docs/specs/templates/handover.md

```markdown
---
feature: {feature-name}
platform: {builder|codegen|output|infra}
stories: [{story-ids}]
status: pending  # pending | in_progress | complete
dependencies: [{dependency-list}]
created: {date}
---

# {Platform} Handover: {Feature Name}

## Context

{Background from architecture docs. What the implementing agent needs to know.}

## Tasks

| # | Task | Story ID | Status | Files |
|---|------|----------|--------|-------|
| 1 | {task description} | {ID} | ⬜ Pending | {files} |

## Files to Create/Modify

### New Files
- `{path}` — {purpose}

### Modified Files
- `{path}` — {what changes}

## TDD Test Plan

| Test | Tests What | Priority |
|------|-----------|----------|
| `test_{name}` | {description} | Must have |

## Acceptance Criteria

{From GitHub issue — checkbox list}

## Definition of Done
- [ ] All tasks marked ✅ Complete
- [ ] All tests pass
- [ ] Code follows docs/standards/coding-standards.md
- [ ] No compiler warnings
- [ ] Documentation updated if needed
```

### 6.2 docs/specs/templates/investigation.md

```markdown
# Investigation: {Issue Title}

**Issue:** #{number}
**Date:** {date}
**Type:** {bug|improvement}
**Platforms:** {affected platforms}

## Problem Statement
{Issue description summarized}

## Investigation Steps
1. {What was checked}
2. {What was found}

## Root Cause / Analysis
{Detailed findings}

## Affected Components
### Builder (C++)
- {files/modules}

### Code Generator
- {files/modules}

### Output Framework
- {files/modules}

## Proposed Fix
{High-level approach}
```

---

## 7. GitHub Infrastructure

### 7.1 Issue Templates

**bug-report.yml:**
- Fields: description, steps to reproduce, expected behavior, actual behavior, platform (builder/output), version, screenshots
- Default labels: `type:bug`, `status:new`

**feature-request.yml:**
- Fields: description, motivation, proposed solution, alternatives considered
- Default labels: `type:feature`, `status:new`

**sprint-task.yml:**
- Fields: story ID, description, platform, acceptance criteria, sprint
- Default labels: `status:new`, `source:ai-agent`

### 7.2 Labels

Create these labels on repository initialization:

**Type:** `type:feature`, `type:bug`, `type:improvement`, `type:maintenance`, `type:docs`
**Component:** `comp:builder`, `comp:codegen`, `comp:output`, `comp:infra`, `comp:docs`
**Status:** `status:new`, `status:investigating`, `status:ready`, `status:in-progress`, `status:review`, `status:done`
**Priority:** `prior:critical`, `prior:high`, `prior:medium`, `prior:low`
**Phase:** `phase-1`, `phase-2`, `phase-3`, `phase-4`, `phase-5`
**Source:** `source:ai-agent`, `source:community`, `source:maintainer`

### 7.3 Milestones

Create milestones aligned with the 5-phase roadmap:
1. `Phase 1: Foundation` — C++ app with Skia, basic widgets, layout engine, YAML parser
2. `Phase 2: Designer Core` — Drag-drop, property editing, Material 3 components, theming
3. `Phase 3: Data & Signals` — Signal graph, REST/SQL connectors, live data preview
4. `Phase 4: Code Gen & Export` — Kotlin generator, Gradle scaffold, quick-run, Fluent
5. `Phase 5: Polish & Community` — Plugin API, navigation editor, undo/redo, docs

---

## 8. Example .tt.yaml Projects

### 8.1 examples/hello-world/project.tt.yaml

A minimal project that proves the pipeline works:

```yaml
schema: 1

project:
  name: hello-world
  version: 0.1.0

screens:
  main:
    root: Column
    layout: { padding: 24, spacing: 16, alignment: center, justify: center }
    children:
      - Text: { value: "Hello, TabTab!", style: { variant: headlineLarge } }
      - Button: { text: "Click Me", variant: filled, onClick: handleClick }
```

### 8.2 examples/customer-manager/project.tt.yaml

The reference project used throughout the architecture docs — a full customer management app with live API data, search filtering, and navigation. This is the "golden path" example that every test and document references.

---

## 9. Initial Bootstrap Steps

When a Claude Code agent receives the instruction to bootstrap TabTab, it should execute these steps in order:

1. Create the directory structure from Section 1
2. Write CLAUDE.md from Section 2
3. Write all slash commands from Section 3
4. Write CI/CD workflows from Section 4
5. Write standards documents from Section 5
6. Write templates from Section 6
7. Initialize GitHub infrastructure from Section 7
8. Write example .tt.yaml projects from Section 8
9. Convert the 5 architecture .docx documents to markdown in docs/architecture/
10. Create initial CMakeLists.txt with Skia dependency
11. Create initial .gitignore, LICENSE (choose license), README.md
12. Initialize git repository
13. Create GitHub repository
14. Push initial scaffold
15. Create Phase 1 milestone and initial stories via /plan-feature

---

## 10. Development Process Flow

The standard development cycle for TabTab follows this flow:

```
Feature Idea
    │
    ▼
/plan-feature "description"
    │ → Decomposes into stories
    │ → Creates GitHub issues + milestone
    ▼
/process-feature feature="{name}"
    │ → Reads architecture docs
    │ → Creates implementation plan
    │ → Creates per-platform handover docs
    ▼
/implement-story story="{ID}"
    │ → Reads handover document
    │ → TDD implementation (Red → Green → Refactor)
    │ → MANDATORY review checkpoint
    │ → Auto-updates docs + GitHub
    ▼
[Repeat for each story in the feature]
    │
    ▼
/close-handover feature="{name}"
    │ → Verifies all stories complete
    │ → Closes GitHub milestone
    │ → Archives handover docs
    ▼
/create-release version="{x.y.z}"
    │ → Tags release
    │ → Generates changelog
    │ → Triggers release CI
```

For bugs and external issues, the flow branches:

```
GitHub Issue (external)
    │
    ▼
/process-issue issue={number}
    │ → Investigates root cause
    │ → Creates investigation doc
    │ → Creates handover(s)
    ▼
/implement-story story={number}
    │ → Standard TDD implementation
    ▼
Done
```
