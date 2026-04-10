# TabTab

> Visual UI designer and builder for Compose Multiplatform — YAML-driven, reactive, owned Kotlin source output.

**Status:** 🏗️ Early scaffolding. No functional builder yet.

## What is TabTab?

TabTab is an open-source visual UI designer for building cross-platform desktop
applications with [Compose Multiplatform](https://www.jetbrains.com/lp/compose-multiplatform/).
You design your UI in a drag-and-drop canvas, see **real** API and database data flowing
through it at design time, and export the result as **fully owned** Kotlin/Compose source
code — no runtime dependency on TabTab.

### Why it exists

Existing visual UI builders are bloated, subscription-based, and disconnected from real
data. TabTab is built on three principles:

1. **Your data is the design.** Live REST, SQL, and file connectors feed the designer
   at design time.
2. **You own the output.** Exported Kotlin projects are clean, idiomatic, and TabTab-free.
3. **Reactive by construction.** All state flows through a signal graph
   (`Signal<T>` / `Computed<T>` / `DataSource<T>` / `Effect`) that compiles 1:1 to
   `StateFlow` in the generated output.

## Architecture at a glance

| Layer | Technology |
|---|---|
| Builder app | C++ 20, Skia (BSD), Scintilla, libcurl, libpq |
| Project format | YAML (`.tt.yaml`) |
| Code generator | C++ → Kotlin source |
| Output | Kotlin / Compose Multiplatform, Gradle (Kotlin DSL) |

Full architecture docs: [`docs/architecture/`](docs/architecture/)

## Repository layout

See [`CLAUDE.md`](CLAUDE.md) for the full directory tree and conventions.

- `builder/` — C++ builder application
- `output-template/` — Template for generated Kotlin projects
- `docs/` — Architecture, standards, requirements, and templates
- `examples/` — Example `.tt.yaml` projects
- `.claude/commands/` — Claude Code slash commands for the development workflow
- `.github/` — CI/CD workflows and issue templates

## Getting started

Prerequisites: C++20 toolchain, CMake 3.28+, Python 3.10+, Java 21+, Gradle 8.10+, Git, `gh`.

```bash
# Build the builder
cd builder && cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel

# Run tests
cd build && ctest --output-on-failure
```

See [`docs/standards/coding-standards.md`](docs/standards/coding-standards.md) and
[`docs/standards/tdd-guidelines.md`](docs/standards/tdd-guidelines.md) before contributing.

## Development workflow

TabTab is developed with a Claude Code agent pipeline. The standard cycle:

```
/plan-feature  →  /process-feature  →  /implement-story  →  /create-release
```

See [`.claude/commands/`](.claude/commands/) for the full command set.

## License

MIT — see [`LICENSE`](LICENSE).
