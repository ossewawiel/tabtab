# TDD Guidelines

Test-driven development is mandatory for specific layers of TabTab. This document
defines **where** TDD applies, **how** the cycle works, and **what counts as "done"**.

## The Red-Green-Refactor cycle

TDD is a three-beat loop. Skipping beats (or fusing them) defeats the purpose.

### Red — write a failing test

1. Pick **one** behaviour from the story's TDD test plan.
2. Write the test **first**. No production code yet.
3. Run the full suite. The new test must fail, **for the reason you expect**.
   - If it passes, your test is wrong (probably testing nothing).
   - If it fails for a different reason (e.g., compile error in unrelated code),
     fix that first.

### Green — minimal implementation

4. Write the **smallest amount of production code** that makes the test pass.
   "Smallest" is literal. Hard-coded returns are fine if only one test exists.
5. Run the full suite. Every test must be green.
6. Do not refactor yet.

### Refactor — clean up with a safety net

7. With a green suite, improve the code:
   - Extract duplication
   - Rename for clarity
   - Replace hard-coded values with logic only as further tests force the change
8. After **every** small refactor, re-run the suite. Never refactor blind.

### Rules
- **One test at a time.** Never write three failing tests and then implement all three.
- **Never skip Red.** If you "know" the test will pass, write it anyway.
- **Never commit in the Red state.** Commit at Green, and again after Refactor.

---

## What requires TDD

These subsystems are strict TDD. Every new feature, every bug fix, every edge
case gets a test first.

### Builder — signal graph engine
`builder/src/core/signal_graph.*`, `builder/src/core/signal_node.*`,
`builder/src/core/dependency_resolver.*`, and friends.

- All graph operations: add, remove, connect, disconnect, cycle detection
- Propagation: single-node update, cascading update, batched tick
- Edge cases: empty graph, single node, disconnected subgraphs, self-reference rejection

### Builder — YAML parser
`builder/src/core/yaml_parser.*`, `builder/src/core/yaml_validator.*`.

- Every field in the schema gets a test (valid + invalid cases)
- Every validation rule gets a test (positive + negative)
- Every error message has a test asserting its wording
- Every binding expression type gets a test

### Builder — layout engine
`builder/src/core/layout_engine.*`.

- Every flexbox rule (grow, shrink, basis, alignment, justify)
- Every container type (Row, Column, Stack, Grid)
- Edge cases: empty container, single child, overflow, infinite constraints

### Builder — expression evaluator
`builder/src/core/expression_evaluator.*`.

- Every supported operator (arithmetic, comparison, boolean, string concat)
- Type coercion rules (if any)
- Error cases: type mismatch, division by zero, undefined reference

### Code generator
`builder/src/codegen/**`.

TDD is **fixture-based** for the generator (see below) rather than unit-test-based
for individual transforms. Each fixture is a mini TDD cycle.

### Output framework
Not applicable — output is generated, not hand-written. Coverage happens at the
generator level (fixture tests ensure specific YAML inputs produce specific
Kotlin outputs, and those outputs are compiled and tested in CI).

---

## What does not require TDD

These areas are tested manually or at integration/E2E level, not via unit TDD:

### Skia rendering
`builder/src/rendering/**`.

Visual output is hard to unit-test meaningfully. Use:
- **Golden image tests** for regression (reference screenshots, pixel diff)
- **Manual review** during development
- **Smoke tests** that the rendering code doesn't crash

### UI interaction
`builder/src/designer/**`.

Drag-drop, click handling, selection state — test via E2E where possible,
otherwise manual.

### Scintilla integration
`builder/src/editor/**`.

Wrapper around a third-party component. Test at integration level.

**Important:** "Not required" is not "not allowed." Writing tests for these areas
is always welcome, just not mandatory.

---

## Test naming

### C++ (Google Test)
Pattern: `TEST(<ClassName>, <unit>_<scenario>_<expected>)`

Examples:
```cpp
TEST(SignalGraph, addNode_withNoDependencies_succeeds);
TEST(SignalGraph, connect_createsCircularDependency_returnsError);
TEST(YamlParser, parse_missingSchemaField_returnsValidationError);
TEST(LayoutEngine, flexGrow_twoChildrenEqualGrow_splitsSpaceEvenly);
```

Parameterised tests use `TEST_P` with a descriptive param suffix.

### Kotlin (JUnit 5 + Kotlin Test)
Pattern: backtick-quoted sentence describing the behaviour.

Examples:
```kotlin
@Test fun `customer list loads and displays 10 customers from the repository`() { ... }
@Test fun `save button is disabled while form is invalid`() { ... }
```

---

## Fixture-based testing for the code generator

The generator is tested with input/output fixture pairs under `tests/codegen/`:

```
tests/codegen/
├── fixtures/
│   ├── empty-project/
│   │   └── project.tt.yaml
│   ├── single-button/
│   │   └── project.tt.yaml
│   ├── customer-manager/
│   │   └── project.tt.yaml
│   └── ...
├── expected/
│   ├── empty-project/
│   │   └── src/main/kotlin/.../Main.kt
│   ├── single-button/
│   │   └── ...
│   └── ...
└── run_tests.py
```

**How it works:**

1. `run_tests.py` walks every directory in `fixtures/`.
2. For each, it runs the generator on `project.tt.yaml`.
3. It compares the generated output tree against `expected/<name>/` file-by-file.
4. Any diff fails the test.
5. CI also runs `./gradlew build -x test` on every generated project to verify
   it compiles.

**Adding a new generator feature:**

1. Create the fixture YAML (`fixtures/<name>/project.tt.yaml`).
2. Run the generator and capture output to `expected/<name>/`.
3. **Manually review** the expected output. Every file. This is the spec.
4. Commit both `fixtures/` and `expected/`.
5. Any change to the generator that modifies output requires updating
   `expected/` with a justification in the commit message.

**Updating fixtures:**

If a generator change is intentional and breaks expected output, regenerate with:
```bash
cd tests/codegen && python run_tests.py --update
```
Then **read the diff** before committing. If you can't explain every line, don't commit.

---

## Coverage targets

| Component | Target | Enforced by |
|---|---|---|
| `builder/src/core/` (signal, parser, layout, expression) | **80%** line coverage | `gcov` in CI, fails build below |
| `builder/src/codegen/` | **100%** fixture coverage (every YAML feature has a fixture) | Manual review |
| `builder/src/rendering/` | No numeric target — golden image tests | CI |
| `builder/src/designer/` | **60%** line coverage | `gcov` in CI |
| `builder/src/data/` | **80%** line coverage | `gcov` in CI |
| Output templates | Via fixture-generated project compilation + tests | CI |

Coverage is measured but **not** the goal. The goal is **confidence**. A 90%-covered
file with trivial tests is worse than a 70%-covered file with meaningful ones.

---

## When you find a bug

Even outside TDD areas, bug fixes follow the Red phase:

1. **Write a failing test** that reproduces the bug.
2. Run the suite. Confirm the test fails.
3. **Fix the code.**
4. Run the suite. Confirm the test passes.
5. Commit both together.

Never commit a fix without a regression test. The bug will come back.

---

## When TDD gets in the way

Sometimes TDD feels like friction: spike work, prototyping, exploring an API you
don't understand yet. When that happens:

1. **Spike freely** in a scratch branch or directory. No tests.
2. Once you understand the solution, **throw the spike away**.
3. Start over on the real branch with TDD. Red → Green → Refactor.

The spike was learning. The real code comes from tests.

This rule has no exceptions for AI agents.
