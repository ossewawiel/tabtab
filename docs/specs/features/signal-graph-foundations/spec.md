---
feature: signal-graph-foundations
phase: 1
status: planned
created: 2026-04-10
stories: [BLD-002, BLD-003, BLD-004, BLD-005]
---

# Signal Graph Foundations

## Summary

Implement the minimum viable signal graph: individual `SignalNode<T>` with
observers, a `SignalGraph` that holds nodes and edges, cycle detection on
connect, and a batched propagation tick that processes dirty nodes in
topological order exactly once per tick.

This is the core data flow model for the entire builder. Everything else —
YAML bindings, computed signals, data sources, code generation — builds on
this.

## Motivation

Per `docs/architecture/signal-system.md`, all state in TabTab flows through
reactive signals. Before any component can bind a `value: => signalName`,
before the YAML parser can resolve bindings, before the code generator can
emit `MutableStateFlow`, we need the in-memory graph.

Landing this as four small stories lets us TDD each piece in isolation:
- BLD-002 — just the node and its observer list
- BLD-003 — just the graph container (add/remove/connect/disconnect)
- BLD-004 — just cycle detection
- BLD-005 — just propagation

Each story must stay in its lane. No story may touch the YAML parser, code
generator, or UI. That's later features.

## Stories

| ID | Platform | Title | Status |
|---|---|---|---|
| BLD-002 | builder | `SignalNode<T>` class with value and observer list | 📋 Planned |
| BLD-003 | builder | `SignalGraph` with addNode / removeNode / connect / disconnect | 📋 Planned |
| BLD-004 | builder | Cycle detection in `SignalGraph::connect` | 📋 Planned |
| BLD-005 | builder | Batched propagation tick | 📋 Planned |

## Acceptance criteria

### BLD-002 — SignalNode
- [ ] `SignalNode<T>` template class in `builder/src/core/signal_node.h`
- [ ] Holds a value of type `T` (default-initialised)
- [ ] `get()` returns the current value
- [ ] `set(value)` updates the value and marks the node dirty
- [ ] `addObserver(callback)` registers an observer
- [ ] `removeObserver(handle)` unregisters an observer
- [ ] Observer callbacks fire when the node's value changes (via `set`)
- [ ] Unit tests cover each of the above

### BLD-003 — SignalGraph container
- [ ] `SignalGraph` class in `builder/src/core/signal_graph.{h,cpp}`
- [ ] `addNode(id, node)` returns `Result<void, Error>` (fails on duplicate ID)
- [ ] `removeNode(id)` returns `Result<void, Error>` (fails if node has edges)
- [ ] `connect(sourceId, targetId)` returns `Result<void, Error>`
- [ ] `disconnect(sourceId, targetId)` returns `Result<void, Error>`
- [ ] Graph stores nodes keyed by string ID
- [ ] Unit tests cover success and failure cases for each operation

### BLD-004 — Cycle detection
- [ ] `SignalGraph::connect` rejects any edge that would create a cycle
- [ ] Returns `Error{code: CycleDetected, message: "..."}` on rejection
- [ ] Unit test: self-loop rejected
- [ ] Unit test: A → B → A rejected
- [ ] Unit test: A → B → C → A rejected
- [ ] Unit test: DAG with no cycles accepts all edges
- [ ] Implementation uses iterative DFS (no recursion depth limit)

### BLD-005 — Batched propagation tick
- [ ] `SignalGraph::tick()` processes all dirty nodes since the last tick
- [ ] Nodes are visited in topological order (sources before dependents)
- [ ] Each dirty node is visited **exactly once** per tick, even if multiple
      inputs changed
- [ ] After `tick()` returns, no node is dirty
- [ ] Unit test: diamond-shaped graph (A → B, A → C, B → D, C → D) visits D once
- [ ] Unit test: chain A → B → C with A dirty visits A, B, C in order
- [ ] Unit test: disconnected subgraphs both process

## Dependencies

- `core-result-type` (BLD-003, BLD-004, BLD-005 return `Result<T, Error>`)
- `infra-bootstrap` (formatting/linting applied to every new file)

## Out of scope

- Computed signals (`ComputedNode<T>`) — separate later feature
- DataSource signals (`DataSourceNode<T>`) — separate later feature
- Effect nodes — separate later feature
- Expression evaluator integration — separate later feature
- YAML binding resolution — separate later feature
- Code generation for StateFlow emission — separate later feature

The goal of this feature is **only** the in-memory graph plumbing. Every
higher-level capability builds on top of it.
