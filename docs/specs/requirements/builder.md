# Builder (C++) — Story Backlog

Stories for the C++ builder application (the desktop tool developers use to
design UIs). Use prefix `BLD-` for all IDs.

Platform: **builder** — directory: `builder/`.

See `docs/standards/coding-standards.md` §C++ for conventions.

## Status legend
- 📋 Planned
- 🔄 In progress
- 👀 In review
- ✅ Done
- ❌ Cancelled

---

<!-- New stories go here. /plan-feature appends to this file. -->

### BLD-001 — `Result<T, Error>` type in `tabtab/result.h`
**Feature:** core-result-type
**Phase:** 1
**Status:** 📋 Planned

Header-only `Result<T, Error>` for every fallible operation in the builder's
core subsystems. No exceptions in hot paths — per the coding standards. This
is deliberately the first real code story: no third-party dependencies, pure
TDD, proves the toolchain and test harness are wired correctly.

**Acceptance criteria:**
- [ ] Header-only at `builder/include/tabtab/result.h`
- [ ] `Result::ok(value)` and `Result::err(error)` constructors
- [ ] `isOk()` / `isErr()` predicates
- [ ] `value()` / `error()` accessors (assert on wrong state)
- [ ] `valueOr(default)` convenience accessor
- [ ] `andThen(fn)` monadic chaining where `fn: T -> Result<U, Error>`
- [ ] `map(fn)` where `fn: T -> U`
- [ ] `Error` struct with `code` enum and `message` string
- [ ] Unit tests cover every public method (Red → Green → Refactor)
- [ ] Passes `clang-format-check` and `clang-tidy` (once INF-001/INF-002 land)

---

### BLD-002 — `SignalNode<T>` class with value and observer list
**Feature:** signal-graph-foundations
**Phase:** 1
**Status:** 📋 Planned

First piece of the signal graph: a single reactive node. Holds a value,
exposes `get()`/`set()`, and maintains an observer list that fires on change.
No graph semantics yet — just the node and its observers.

**Acceptance criteria:**
- [ ] `SignalNode<T>` template class in `builder/src/core/signal_node.h`
- [ ] Default-initialised value of type `T`
- [ ] `get()` returns the current value
- [ ] `set(value)` updates the value and notifies observers
- [ ] `addObserver(callback)` returns a handle
- [ ] `removeObserver(handle)` unregisters
- [ ] Observer notification is synchronous on `set()` (batching comes in BLD-005)
- [ ] Unit tests: add/remove observer, notify on set, no notify on same-value set

---

### BLD-003 — `SignalGraph` with addNode / removeNode / connect / disconnect
**Feature:** signal-graph-foundations
**Phase:** 1
**Status:** 📋 Planned

Container that holds a set of `SignalNode`s keyed by string ID and tracks
directed edges between them. Provides basic CRUD on nodes and edges. No cycle
detection in this story — that's BLD-004. No propagation — that's BLD-005.

**Acceptance criteria:**
- [ ] `SignalGraph` class in `builder/src/core/signal_graph.{h,cpp}`
- [ ] `addNode(id, node)` → `Result<void, Error>` (fails on duplicate ID)
- [ ] `removeNode(id)` → `Result<void, Error>` (fails if node has incident edges)
- [ ] `connect(sourceId, targetId)` → `Result<void, Error>`
- [ ] `disconnect(sourceId, targetId)` → `Result<void, Error>`
- [ ] `hasNode(id)` / `hasEdge(source, target)` predicates
- [ ] Unit tests cover success + every failure path

---

### BLD-004 — Cycle detection in `SignalGraph::connect`
**Feature:** signal-graph-foundations
**Phase:** 1
**Status:** 📋 Planned

Extend `connect` to reject any edge that would create a cycle. Uses iterative
DFS from the target, looking for a path back to the source. Returns
`Error{code: CycleDetected, message: ...}` on rejection.

**Acceptance criteria:**
- [ ] `connect` rejects self-loops
- [ ] `connect` rejects A → B → A
- [ ] `connect` rejects A → B → C → A
- [ ] `connect` accepts any valid DAG edge
- [ ] Implementation is iterative DFS (no recursion depth limit)
- [ ] `Error::code` enum gains a `CycleDetected` variant
- [ ] Unit tests for every case above
- [ ] Existing BLD-003 tests still pass

---

### BLD-005 — Batched propagation tick
**Feature:** signal-graph-foundations
**Phase:** 1
**Status:** 📋 Planned

`SignalGraph::tick()` walks all dirty nodes in topological order, visiting
each exactly once even if multiple inputs changed. After `tick()` returns, no
node is dirty. Observer notifications fire during the tick in dependency
order.

**Acceptance criteria:**
- [ ] `SignalGraph::tick()` processes all dirty nodes since the last tick
- [ ] Nodes visited in topological order (sources before dependents)
- [ ] Each dirty node visited exactly once per tick
- [ ] After `tick()`, no node is dirty
- [ ] Observer callbacks fire during the tick, not during `set()` once a graph is assigned
- [ ] Unit test: diamond (A → B, A → C, B → D, C → D) with A dirty visits D once
- [ ] Unit test: chain A → B → C with A dirty visits A, B, C in that order
- [ ] Unit test: two disconnected subgraphs both process
- [ ] Unit test: graph with no dirty nodes is a no-op
