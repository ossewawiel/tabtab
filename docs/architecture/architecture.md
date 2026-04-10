**TabTab**

Architecture Document

Visual UI Designer & Builder for Compose Multiplatform

Version 1.0 — April 2026

Open Source — Community-Driven

*Status: Draft / Pre-Development*

# 1. Executive Summary

This document defines the architecture for TabTab, an open-source visual UI designer and builder that enables solo developers and small teams to create cross-platform desktop applications using a modern, VB6-inspired workflow. The tool combines a drag-and-drop visual form designer with live data preview, a built-in code editor, and a reactive/signals-based data flow model. Projects are stored as YAML and exported as fully owned Kotlin/Compose Multiplatform source code.

## 1.1 Vision Statement

TabTab is a fast, prescriptive, open-source visual UI builder that replaces bloated, subscription-based IDEs with a streamlined tool that lets developers see real data flowing through their UI at design time, switch seamlessly between visual design and code, and ship native cross-platform desktop applications built on Compose Multiplatform.

## 1.2 Key Differentiators

- **Live data preview: **Connect to REST APIs, GraphQL endpoints, SQL databases, and local files at design time to see real data rendered in your UI components, not placeholders.
- **VB6-style workflow: **Drag components onto a canvas, double-click to write event handlers in Kotlin, toggle seamlessly between visual design and code editor.
- **Prescriptive design systems: **Built-in Material Design and Fluent component libraries with pre-configured themes, layouts, and styles. Start productive immediately.
- **You own your code: **Export generates clean, idiomatic Kotlin/Compose Multiplatform source code with a standard Gradle build. No vendor lock-in, no runtime dependency on the builder.
- **Open source, community-driven: **Free to use, free to contribute. No subscriptions, no feature-gating.
## 1.3 Target Users

- **Solo developers **building their own desktop applications who want rapid UI prototyping with real data without the overhead of full IDE setups.
- **Small teams (developer + designer) **where the designer can work visually while the developer handles business logic, sharing the same YAML project format.
# 2. System Overview

The system consists of two distinct components: the Builder (the IDE/designer tool) and the Output (the applications users create with it). These are intentionally decoupled — the Builder is a C++ application, while the Output is Kotlin/JVM, connected only by the YAML project format and the code generation pipeline.

## 2.1 High-Level Architecture

| **Component** | **Technology** | **Role** |
|---|---|---|
| Builder Application | C++ with Skia | Visual designer, code editor, live preview engine, project management |
| Rendering Engine | Skia (BSD license) | Hardware-accelerated 2D rendering for the builder UI and design canvas |
| Project Format | YAML (strict schema) | Serialization of component tree, layout, styles, bindings, event references |
| Code Editor | Scintilla (embedded) | Kotlin syntax highlighting, basic completion, VB6-style toggle with designer |
| Live Data Engine | C++ (libcurl, libpq, etc.) | REST, GraphQL, SQL, file, and OS API connectors for design-time data preview |
| Quick-Run Preview | JVM subprocess | Compiles and runs the full Kotlin project for logic testing (~3–5 second cycle) |
| Code Generator | C++ → Kotlin source | Translates YAML project into idiomatic Compose Multiplatform Kotlin code |
| Output Framework | Compose Multiplatform | Kotlin/Skia-based cross-platform UI framework for generated applications |
| Build System | Gradle (Kotlin DSL) | Standard Kotlin ecosystem build tool for exported projects |

# 3. Builder Application Architecture

The builder is a native desktop application written in C++ using Skia for all rendering. It implements a custom widget set (not Qt, to avoid GPL licensing constraints) that supports Material Design and Fluent design systems. The builder runs on Windows, macOS, and Linux.

## 3.1 Rendering Layer — Skia

Skia is the 2D graphics library used by Chrome, Flutter, and Android. It provides hardware-accelerated rendering via OpenGL, Vulkan, and Metal backends. The builder uses Skia for all UI rendering, including the component palette, property panels, design canvas, and code editor overlay.

- **License: **BSD — no copyleft restrictions, compatible with any open-source or commercial licensing.
- **Bindings: **Native C++ API. No wrapper overhead.
- **Text rendering: **Skia’s SkParagraph API handles text layout, font fallback, and internationalization.
- **GPU acceleration: **Skia’s GrContext provides GPU-accelerated rendering on all platforms.
## 3.2 Custom Widget Set

Since Qt’s GPL license would force the entire project to be GPL, the builder implements its own widget set rendered with Skia. This widget set implements both Material Design 3 and Microsoft Fluent design tokens.

The widget set is structured in three layers:

- **Primitives: **Box, Text, Image, Canvas — the atomic rendering units built directly on Skia draw calls.
- **Components: **Button, TextField, Dropdown, Slider, Checkbox, etc. — composed from primitives with theme-aware styling.
- **Composites: **PropertyPanel, ComponentPalette, DesignCanvas, CodeEditorPane — builder-specific panels composed from components.
## 3.3 Layout Engine

The builder implements a Flexbox-inspired layout engine (similar to Yoga/Facebook’s layout engine used in React Native). This provides a consistent, well-understood layout model that maps cleanly to Compose Multiplatform’s Row/Column/Box layout system at export time.

- Row (horizontal flex), Column (vertical flex), Box (stack/overlap)
- Flex grow, shrink, basis properties for responsive layouts
- Padding, margin, alignment, spacing as first-class properties
- Constraint-based sizing (min/max width/height, aspect ratio)
- Scroll containers with configurable overflow behavior
## 3.4 Design Canvas

The central workspace where users visually assemble their UI. The canvas provides:

- **Drag-and-drop placement: **Components from the palette are dragged onto the canvas and snapped into the layout hierarchy.
- **Visual selection and manipulation: **Click to select, resize handles, alignment guides, snap-to-grid.
- **Hierarchy visualization: **Component tree panel shows parent/child relationships, allows reordering via drag.
- **Live data rendering: **Components bound to data sources show real values from API/DB connections at design time.
- **Multi-viewport preview: **Side-by-side preview at different window sizes to test responsive layouts.
## 3.5 Code Editor Integration

The builder embeds a Scintilla-based code editor that provides Kotlin syntax highlighting, basic auto-completion, and bracket matching. The editor follows the VB6 paradigm:

- Double-click a component on the canvas to jump to its default event handler in the code editor.
- Toggle between design view and code view with a single keypress or tab click.
- Event handlers are organized per-component and per-event (onClick, onValueChanged, onFocus, etc.).
- The code editor shows only the current component’s handlers by default, with a file-level view available.
- Syntax errors are highlighted inline; compilation errors appear in a bottom output panel on quick-run.
# 4. Reactive / Signals Architecture

The core data flow model is based on reactive signals, inspired by modern frameworks like Solid.js, Svelte 5 runes, and Kotlin StateFlow. Signals provide a universal abstraction that maps cleanly to Compose Multiplatform’s state management at export time.

## 4.1 Signal Primitives

| **Primitive** | **Description** | **Kotlin Export Mapping** |
|---|---|---|
| Signal&lt;T&gt; | A reactive value that notifies dependents on change | MutableStateFlow&lt;T&gt; |
| Computed&lt;T&gt; | Derived value that auto-recalculates when dependencies change | StateFlow&lt;T&gt; via combine/map |
| Effect | Side-effect that runs when its signal dependencies change | LaunchedEffect / snapshotFlow |
| DataSource | Signal connected to an external data source (API, DB, file) | Repository pattern + StateFlow |

## 4.2 Data Binding Model

Every component property can be bound to a signal. The binding is declared in YAML and rendered live in the designer. At export time, bindings become Compose Multiplatform state collection.

Design-time binding flow:

- User defines a DataSource signal connected to a REST endpoint (e.g., GET /api/customers).
- User binds a Table component’s “data” property to that DataSource signal.
- The builder’s C++ HTTP client fetches the real data and pushes it into the signal.
- The design canvas renders the Table with real customer data.
Export-time binding flow:

- The DataSource becomes a Kotlin repository class with a StateFlow&lt;List&lt;Customer&gt;&gt; property.
- The Table binding becomes: val customers by viewModel.customers.collectAsState().
- The Compose Multiplatform LazyColumn renders the data reactively.
## 4.3 Signal Graph

Signals form a directed acyclic graph (DAG) of dependencies. The builder maintains this graph at design time for two purposes: (1) efficiently propagating data changes through the UI during live preview, and (2) generating the correct dependency chain in the exported Kotlin code. The DAG is serialized as part of the YAML project file.

# 5. YAML Project Format

The YAML project format is the central artifact that connects the visual designer to the code generator. It captures the complete definition of an application’s UI, data bindings, theme selection, and references to Kotlin source files containing business logic.

## 5.1 Schema Overview

| **Section** | **Purpose** | **Contents** |
|---|---|---|
| project | Project metadata | Name, version, description, target platforms, Kotlin version |
| theme | Design system and styling | Active design system (Material/Fluent), color palette, typography scale, spacing tokens |
| dataSources | External data connections | REST endpoints, GraphQL schemas, SQL connection strings, file paths |
| signals | Reactive state definitions | Signal declarations with types, initial values, computed derivations, data source bindings |
| screens | UI screen definitions | Component tree per screen, layout hierarchy, property values, signal bindings, event references |
| navigation | Screen flow | Navigation graph between screens, transition animations, argument passing |
| assets | Static resources | Image references, font files, icon sets |

## 5.2 Example YAML Structure

Below is a simplified example showing the key sections of a project file defining a customer list screen with live API data:

**project:**

name: customer-manager  # Built with TabTab

version: 1.0.0

kotlin: 1.9.22

compose: 1.6.0

**theme:**

system: material3

palette: light-blue

typography: default

**dataSources:**

customersApi:

type: rest

baseUrl: https://api.example.com

endpoints:

list: GET /customers

detail: GET /customers/{id}

**signals:**

customers:

type: List&lt;Customer&gt;

source: customersApi.list

refreshInterval: 30s

searchQuery:

type: String

default: ""

filteredCustomers:

type: Computed&lt;List&lt;Customer&gt;&gt;

derive: customers.filter { it.name.contains(searchQuery) }

**screens:**

customerList:

layout: Column

children:

- TextField: { bind: searchQuery, hint: "Search..." }

- DataTable: { bind: filteredCustomers, columns: [name, email, status] }

# 6. Live Data Engine

The live data engine is the builder’s most distinctive feature. It executes data fetching at design time using native C++ networking libraries, independent of the Kotlin/JVM runtime. This means the designer shows real data without needing to compile or run the user’s project.

## 6.1 Supported Data Sources

| **Source Type** | **C++ Library** | **Capabilities** |
|---|---|---|
| REST APIs | libcurl | GET/POST/PUT/DELETE, auth headers, JSON parsing, pagination |
| GraphQL | libcurl + custom parser | Query execution, variable substitution, schema introspection |
| SQL Databases | libpq / SQLite / ODBC | PostgreSQL, SQLite, MySQL/MariaDB via ODBC, query execution, result mapping |
| NoSQL | MongoDB C driver / Redis | Document queries, key-value lookups |
| Local Files | std::filesystem | JSON, CSV, XML file reading and watching for changes |
| OS APIs | Platform-specific | File system browsing, environment variables, system info |

## 6.2 Data Flow at Design Time

When a user configures a DataSource signal, the builder immediately attempts to connect and fetch data. The results are transformed into the signal’s declared type using a lightweight C++ JSON-to-type mapper. The data then flows through the signal graph, populating all bound components on the design canvas.

- Connections are cached and reused. Polling intervals are configurable per source.
- Authentication credentials are stored in a local encrypted keychain, never in the YAML project file.
- Errors (network failures, auth issues, malformed responses) display inline on the affected components with clear diagnostics.
- A data inspector panel lets users browse raw API responses and map fields to signal types.
# 7. Quick-Run Preview System

While the live data engine provides real-time visual preview of data-bound UI, user-written Kotlin business logic requires compilation. The quick-run system provides a fast build-and-launch cycle for testing logic.

## 7.1 Architecture

- The builder maintains a background JVM process (lazy-started on first quick-run) to avoid cold-start overhead.
- On quick-run, the code generator produces Kotlin source files from the YAML project.
- User-written Kotlin handler files are combined with generated code.
- Incremental Kotlin compilation is invoked via the Kotlin compiler daemon (already warm from the background JVM).
- The compiled application launches in a separate window. Target: under 5 seconds from trigger to visible app.
- Console output and exceptions are captured and displayed in the builder’s output panel.
## 7.2 Future: Embedded JVM (v2+)

In a future version, the builder will optionally embed a JVM with Kotlin scripting support for true live execution of business logic at design time. This will use the Kotlin Scripting API (JSR-223) to evaluate handler functions directly within the builder process, enabling instant feedback without a full compilation cycle. This is deferred from v1 to reduce initial complexity.

# 8. Code Generation Pipeline

The code generator translates the YAML project into idiomatic, human-readable Kotlin/Compose Multiplatform source code. The generated code is intended to be read, modified, and maintained by the developer after export. It is not obfuscated or framework-dependent.

## 8.1 Generation Strategy

| **YAML Section** | **Generated Kotlin** | **Pattern** |
|---|---|---|
| screens + children | @Composable functions with Compose UI | One file per screen, components map to Compose widgets |
| signals (basic) | MutableStateFlow in ViewModel | MVVM-like ViewModel per screen |
| signals (computed) | combine() / map() on StateFlow | Derived state via Kotlin Flow operators |
| signals (dataSource) | Repository class + coroutine fetch | Repository pattern with suspend functions |
| event handlers | Function references in ViewModel | User-written Kotlin preserved verbatim |
| theme | MaterialTheme / custom Theme object | Compose theming with color scheme + typography |
| navigation | Compose Navigation graph | NavHost with typed routes |

## 8.2 Export Output Structure

The exported project follows standard Kotlin/Compose Multiplatform conventions:

**project-name/**

build.gradle.kts

settings.gradle.kts

src/main/kotlin/

App.kt                    ← Entry point

theme/Theme.kt            ← Generated theme

screens/CustomerList.kt   ← Generated composables

viewmodels/CustomerListVM.kt ← Generated ViewModels

repositories/             ← Generated data access

handlers/                 ← User-written business logic

src/main/resources/         ← Assets

# 9. Design System Architecture

The builder ships with two built-in design systems (Material Design 3 and Microsoft Fluent) and an extensible architecture that allows third-party design systems to be added as plugins.

## 9.1 Design Token Architecture

Both design systems are implemented as design token sets — abstract values for colors, typography, spacing, elevation, and shape that are resolved at render time based on the active theme.

| **Token Category** | **Material Design 3** | **Microsoft Fluent** |
|---|---|---|
| Primary color | MD3 color roles (primary, secondary, tertiary) | Fluent accent color system |
| Typography | MD3 type scale (display, headline, body, label) | Fluent type ramp (title, subtitle, body, caption) |
| Spacing | 4dp grid system | 4px grid system |
| Elevation | Surface tonal elevation (0–5) | Shadow-based depth (0–64) |
| Shape | Shape scale (none, extra-small to extra-large) | Corner radius scale (none, small, medium, large) |
| Motion | MD3 easing and duration tokens | Fluent motion curves and durations |

## 9.2 Theme Customization

Users can customize themes at three levels:

- **Palette selection: **Choose from pre-built color palettes (e.g., light-blue, forest-green, corporate-gray) that automatically generate all derived color tokens.
- **Token overrides: **Override individual tokens (e.g., change the primary color, adjust body font size) while keeping the rest of the system coherent.
- **Custom design system: **Define an entirely new token set via a YAML design system definition file, which the builder loads as an additional option.
# 10. Component Library

The builder provides a curated, prescriptive component library organized by function. Each component has a visual representation in the designer (rendered via Skia with the active theme), a YAML schema defining its properties and bindings, and a code generation template for Compose Multiplatform output.

## 10.1 Core Components

| **Category** | **Components** | **Compose Mapping** |
|---|---|---|
| Input | Button, TextField, TextArea, Checkbox, RadioGroup, Switch, Slider, DatePicker, Dropdown | Material3 equivalents |
| Display | Text, Image, Icon, Badge, Avatar, ProgressBar, Chip, Card, Divider | Material3 + custom composables |
| Layout | Row, Column, Box, Grid, Spacer, ScrollContainer, LazyList, Tabs, Accordion | Compose layout primitives |
| Navigation | TopAppBar, BottomNavBar, Drawer, NavigationRail, Breadcrumb | Compose Navigation + Material3 |
| Data | DataTable, List, TreeView, Pagination | LazyColumn/LazyVerticalGrid + custom |
| Feedback | Dialog, Snackbar, Tooltip, LoadingSpinner, EmptyState, ErrorBoundary | Material3 + custom composables |
| Surfaces | Card, Sheet, Panel, ExpansionPanel | Material3 Surface variants |

# 11. Development Roadmap

## 11.1 Phase 1 — Foundation (Months 1–3)

Objective: Buildable C++ application with Skia rendering, basic widget set, and empty design canvas.

- Set up C++ project with Skia integration (OpenGL/Vulkan backends)
- Implement core widget primitives: Box, Text, Button, TextField
- Implement Flexbox layout engine
- Create the builder’s chrome: window management, panels, palette, property inspector
- Implement YAML project serialization/deserialization
- Embed Scintilla code editor with Kotlin syntax highlighting
## 11.2 Phase 2 — Designer Core (Months 4–6)

Objective: Functional visual form designer with drag-and-drop, property editing, and basic theming.

- Implement drag-and-drop from palette to canvas
- Component selection, resize handles, alignment guides
- Property panel with type-aware editors (color picker, enum dropdown, text input)
- Material Design 3 component library (input components first)
- Theme engine with palette selection and live preview
- Component tree panel with reordering
## 11.3 Phase 3 — Data & Signals (Months 7–9)

Objective: Live data preview with reactive signal system and API/DB connectivity.

- Implement signal graph engine in C++
- REST API connector with visual configuration (URL, headers, auth, method)
- JSON response mapper — visual tool to map API fields to signal types
- Live data rendering on canvas (components show real API data)
- SQL connector (SQLite + PostgreSQL) with query builder
- Data inspector panel for browsing raw responses
## 11.4 Phase 4 — Code Gen & Export (Months 10–12)

Objective: Complete code generation pipeline producing runnable Compose Multiplatform projects.

- Kotlin code generator for screens, ViewModels, repositories
- Gradle project template generation
- VB6-style code/design toggle with event handler navigation
- Quick-run preview system (JVM subprocess with incremental compilation)
- Fluent design system addition
- First public alpha release
## 11.5 Phase 5 — Polish & Community (Months 13–18)

Objective: Production-quality tool with plugin system and community ecosystem.

- Plugin API for third-party components and design systems
- GraphQL and NoSQL connectors
- Navigation graph visual editor
- Multi-viewport responsive preview
- Undo/redo system with full history
- Accessibility auditing tools
- Documentation, tutorials, and example projects
- Community contribution guidelines and governance
# 12. Key Technical Decisions & Rationale

| **Decision** | **Choice** | **Rationale** |
|---|---|---|
| Builder language | C++ | Maximum performance for the designer, native Skia API access, no runtime dependencies |
| Builder rendering | Skia (BSD license) | Battle-tested (Chrome, Flutter), GPU-accelerated, no copyleft licensing constraints unlike Qt (GPL) |
| Output language | Kotlin/JVM | Reflection for live preview (future), mature ecosystem, excellent DX, good enough performance via JIT |
| Output UI framework | Compose Multiplatform | Skia-based (alignment with builder), reactive by design (signals map to State), cross-platform, JetBrains-backed |
| Project format | YAML | Human-readable, clean syntax, strict schema support, excellent diff/merge behavior in version control |
| Reactive model | Signals / StateFlow | Universal adapter: maps to every major UI framework’s reactivity. Future-proof for additional export targets |
| Design systems | Material 3 + Fluent + extensible | Covers 90% of use cases. Plugin architecture allows community additions |
| Live preview | C++ data fetching + visual preview (v1), embedded JVM for logic (v2+) | Ships fast (v1 covers 80% of value), full fidelity deferred to reduce complexity |
| Build system | Gradle (Kotlin DSL) | Kotlin ecosystem standard. Developer owns the build config and can customize it |
| License (builder) | Open source (TBD specific license) | Community-driven development, broad adoption, contribution ecosystem |
| Code editor | Scintilla | Mature C++ text editor component, Kotlin syntax support, lightweight, no web dependency |

# 13. Risks & Mitigations

| **Risk** | **Impact** | **Mitigation** |
|---|---|---|
| Custom widget set is a large engineering effort | High | Start with minimal component set. Prioritize the 10 most-used components. Community can contribute additional widgets. |
| Skia API changes or breaking updates | Medium | Pin to a stable Skia release. Chromium’s Skia fork provides stable branches. |
| Compose Multiplatform is still maturing | Medium | Track JetBrains releases closely. Generated code uses stable APIs only. Version pin in YAML project. |
| Signal-to-StateFlow mapping may have edge cases | Medium | Design signal primitives as a subset of StateFlow capabilities. Comprehensive test suite for code generation. |
| Quick-run JVM startup latency exceeds 5 seconds | Low | Keep JVM warm in background. Use Kotlin compiler daemon. Profile and optimize incrementally. |
| YAML format needs to evolve with new features | Low | Version the schema. Provide automated migration tools for project files. |
| Community adoption is slow | Medium | Build compelling example projects. Create video tutorials. Engage Kotlin and Compose communities. |

# 14. Future Considerations

The following features are explicitly deferred from v1 but inform architectural decisions made now to avoid closing doors:

- **Additional export targets: **The YAML IR and signal model are designed to be framework-agnostic. Future code generators could target Qt/C++, SwiftUI, Flutter/Dart, or web (React/Svelte). Each new target is a self-contained code generator module.
- **Embedded JVM for live logic preview: **The v1 architecture isolates the quick-run system as a subprocess. In v2, this can be upgraded to an embedded JVM with Kotlin scripting for instant logic evaluation without changing the builder’s core architecture.
- **Collaborative editing: **The YAML project format is text-based and version-control friendly. Real-time collaboration (Google Docs-style) would require a CRDT layer on the YAML model, which is feasible but out of scope for v1.
- **AI-assisted design: **The structured YAML format is well-suited for LLM-based generation. A future integration could allow users to describe a screen in natural language and have the builder generate the YAML component tree.
- **Mobile targets: **Compose Multiplatform supports Android and iOS (alpha). The same YAML project could target mobile platforms with a mobile-specific code generator and responsive layout adaptations.
- **Plugin marketplace: **Third-party component libraries, design systems, data connectors, and code generator targets distributed via a community marketplace.
