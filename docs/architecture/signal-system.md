**TabTab**

Reactive Signal System

Technical Specification

Version 1.0 — April 2026

*Core Data Flow Architecture*

# 1. Overview & Design Philosophy

The reactive signal system is the core data flow architecture of TabTab. It governs how state is defined, how changes propagate through the application, how external data enters the system, and how the visual designer renders live data at design time. The signal system bridges two worlds: the C++ builder (where signals drive the design canvas) and the Kotlin/Compose Multiplatform output (where signals map to StateFlow and Compose state).

## 1.1 Core Principles

- **Reactive by default: **Every piece of state in a TabTab application is a signal. When a signal changes, all dependent signals and UI components update automatically. There is no manual refresh, no imperative setState call.
- **Declarative dependencies: **The developer declares what depends on what. The system determines when and how to update. This is declared in YAML for simple derivations and in Kotlin for complex logic.
- **Batched propagation: **Changes are collected and propagated once per frame tick, avoiding cascading re-renders and ensuring the UI always reflects a consistent state snapshot.
- **Dual-runtime: **The same signal graph runs in both the C++ builder (for live design-time preview) and the Kotlin output (for the shipped application), with deterministic behavior in both.
- **Acyclic by enforcement: **The signal dependency graph is a DAG (directed acyclic graph). Circular dependencies are detected and reported with visual diagnostics. They must be resolved before export.
## 1.2 Conceptual Model

A signal is a named, typed container for a value that can change over time. Signals are the universal abstraction for all state in TabTab:

- User input (text fields, sliders, toggles) writes to mutable signals.
- External data (API responses, database queries, file contents) flows into data source signals.
- Derived values (filtered lists, computed totals, formatted strings) are computed signals.
- UI components bind their properties to signals and re-render when those signals change.
- Side effects (navigation, logging, analytics) are triggered by effect signals.
Together, these form a directed acyclic graph where data flows from sources (user input, APIs, databases) through transformations (computed signals) to sinks (UI components, side effects).

# 2. Signal Primitives

TabTab defines five signal primitives. Each has a specific role, a YAML declaration syntax, a C++ implementation in the builder, and a Kotlin export mapping.

| **Primitive** | **Role** | **YAML Declaration** | **C++ Builder** | **Kotlin Export** |
|---|---|---|---|---|
| Signal&lt;T&gt; | Mutable state | type + default | SignalNode&lt;T&gt; | MutableStateFlow&lt;T&gt; |
| Computed&lt;T&gt; | Derived state | type + derive | ComputedNode&lt;T&gt; | StateFlow&lt;T&gt; via combine/map |
| DataSource&lt;T&gt; | External data | type + source | DataSourceNode&lt;T&gt; | Repository + StateFlow&lt;T&gt; |
| Effect | Side effects | effect + watch | EffectNode | LaunchedEffect / snapshotFlow |
| Resource&lt;T&gt; | Async with lifecycle | type + source + loading | ResourceNode&lt;T&gt; | sealed class (Loading/Success/Error) |

## 2.1 Signal&lt;T&gt; — Mutable State

The most basic primitive. Holds a value that can be read and written. UI input components write to mutable signals. Other signals and components can read from them.

**YAML declaration:**

```
signals:
  searchQuery:
    type: String
    default: ""
```

```
  selectedIndex:
    type: Int
    default: 0
    constraints: { min: 0, max: 100 }
```

```
  isDarkMode:
    type: Boolean
    default: false
    persist: true          # Survives app restart (stored in local prefs)
```

**C++ builder implementation:**

```
template<typename T>
class SignalNode : public GraphNode {
    T value_;
    T defaultValue_;
    std::optional<Constraints<T>> constraints_;
```

```
public:
    const T& get() const { return value_; }
```

```
    void set(const T& newValue) {
        T constrained = constraints_
            ? constraints_->apply(newValue)
            : newValue;
        if (constrained != value_) {
            value_ = constrained;
            graph_.markDirty(this);  // Queue for batch propagation
        }
    }
```

```
    void reset() { set(defaultValue_); }
};
```

**Kotlin export:**

```
// Generated in ViewModel
private val _searchQuery = MutableStateFlow("")
val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
```

```
fun updateSearchQuery(value: String) {
    _searchQuery.value = value
}
```

## 2.2 Computed&lt;T&gt; — Derived State

A read-only signal whose value is automatically derived from other signals. Computed signals re-evaluate only when their dependencies change (lazy evaluation with caching). They support two declaration modes: inline expressions for simple derivations and Kotlin handler references for complex logic.

**YAML declaration — inline:**

```
  filteredCustomers:
    type: Computed<List<Customer>>
    derive: "customers.filter { it.name.contains(searchQuery, ignoreCase = true) }"
```

```
  totalRevenue:
    type: Computed<Double>
    derive: "orders.sumOf { it.amount }"
```

```
  isFormValid:
    type: Computed<Boolean>
    derive: "name.isNotBlank() && email.contains('@')"
```

**YAML declaration — handler reference:**

```
  creditScore:
    type: Computed<CreditScore>
    handler: calculateCreditScore
    dependsOn: [currentCustomer, transactionHistory, marketData]
```

**C++ builder implementation:**

```
template<typename T>
class ComputedNode : public GraphNode {
    std::function<T()> computeFn_;
    T cachedValue_;
    bool isDirty_ = true;
    std::vector<GraphNode*> dependencies_;
```

```
public:
    const T& get() {
        if (isDirty_) {
            cachedValue_ = computeFn_();
            isDirty_ = false;
        }
        return cachedValue_;
    }
```

```
    void markDirty() override {
        isDirty_ = true;
        graph_.markDirty(this);
    }
};
```

**Kotlin export:**

```
// Inline derivation → Flow combine/map
val filteredCustomers: StateFlow<List<Customer>> =
    combine(customers, searchQuery) { list, query ->
        list.filter { it.name.contains(query, ignoreCase = true) }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(), emptyList())
```

```
// Handler reference → function call in combine
val creditScore: StateFlow<CreditScore> =
    combine(currentCustomer, transactionHistory, marketData) { cust, txns, mkt ->
        calculateCreditScore(cust, txns, mkt)  // User-written function
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(), CreditScore.empty())
```

## 2.3 DataSource&lt;T&gt; — External Data

Connects a signal to an external data source (REST API, GraphQL, SQL, file, OS API). The builder’s C++ data engine fetches real data at design time. The code generator produces a repository class with coroutine-based fetching for the Kotlin output.

**YAML declaration:**

```
  customers:
    type: List<Customer>
    source: customersApi.list
    refreshInterval: 30s
    loading: spinner            # spinner | skeleton | stale | custom
    onError: fallback
    fallback: []
```

```
  currentCustomer:
    type: Customer?
    source: customersApi.detail
    params: { id: => selectedCustomerId }
    refreshOn: selectedCustomerId
    loading: skeleton
    onError: lastValue
```

**Loading strategies:**

| **Strategy** | **YAML Value** | **Behavior** | **Best For** |
|---|---|---|---|
| Spinner | spinner | Show LoadingSpinner overlay on bound components | Initial loads, short fetches |
| Skeleton | skeleton | Show placeholder shapes matching component layout | Lists, cards, data-heavy screens |
| Stale (optimistic) | stale | Show previous data, update when fresh data arrives | Refresh cycles, background polling |
| Custom | custom | Developer provides a loading component reference | Complex loading states |

**Error handling strategies:**

| **Strategy** | **YAML Value** | **Behavior** |
|---|---|---|
| Empty | empty | Reset to type default (empty list, null, zero) |
| Last Value | lastValue | Keep showing the last successfully fetched value |
| Fallback | fallback | Use the declared fallback value |
| Error State | error | Set signal to error state, bound components show ErrorBoundary |

**C++ builder implementation:**

```
template<typename T>
class DataSourceNode : public GraphNode {
    std::unique_ptr<DataConnector> connector_;
    T currentValue_;
    T fallbackValue_;
    LoadingState loadingState_ = LoadingState::Idle;
    std::chrono::seconds refreshInterval_;
    ErrorStrategy errorStrategy_;
```

```
    void fetch() {
        loadingState_ = LoadingState::Loading;
        graph_.notifyLoadingChange(this);
```

```
        connector_->fetchAsync([this](Result<T> result) {
            if (result.isOk()) {
                currentValue_ = result.value();
                loadingState_ = LoadingState::Ready;
            } else {
                handleError(result.error());
            }
            graph_.markDirty(this);
        });
    }
};
```

**Kotlin export:**

```
// Generated Repository
class CustomersRepository(private val api: CustomersApi) {
    private val _customers = MutableStateFlow<Resource<List<Customer>>>(Resource.Loading)
    val customers: StateFlow<Resource<List<Customer>>> = _customers.asStateFlow()
```

```
    suspend fun refresh() {
        _customers.value = Resource.Loading
        try {
            val data = api.list()
            _customers.value = Resource.Success(data)
        } catch (e: Exception) {
            _customers.value = Resource.Error(e, _customers.value.dataOrNull())
        }
    }
}
```

```
// Generated sealed class
sealed class Resource<T> {
    class Loading<T> : Resource<T>()
    data class Success<T>(val data: T) : Resource<T>()
    data class Error<T>(val error: Throwable, val staleData: T?) : Resource<T>()
}
```

## 2.4 Effect — Side Effects

Effects run imperative code in response to signal changes. They don’t produce a value — they perform side effects like navigation, logging, analytics, or triggering external actions. Effects are declared in YAML and reference Kotlin handler functions.

**YAML declaration:**

```
effects:
  logSearch:
    watch: [searchQuery]
    handler: logSearchAnalytics
    debounce: 500ms
```

```
  navigateOnSelect:
    watch: [selectedCustomerId]
    handler: navigateToDetail
    condition: "selectedCustomerId != null"
```

```
  autoSave:
    watch: [formData]
    handler: saveToLocalStorage
    debounce: 2s
    skipInitial: true         # Don't run on first load
```

| **Property** | **Type** | **Description** |
|---|---|---|
| watch | List&lt;SignalName&gt; | Signals that trigger this effect when they change |
| handler | String | Kotlin function name in handlers/ directory |
| debounce | Duration | Minimum time between executions (e.g., 500ms, 2s) |
| throttle | Duration | Maximum execution frequency |
| condition | String | Inline expression that must be true for the effect to run |
| skipInitial | Boolean | If true, don’t run when the signal is first initialized |

**Kotlin export:**

```
// Generated in ViewModel
init {
    viewModelScope.launch {
        searchQuery
            .debounce(500)
            .collect { query ->
                logSearchAnalytics(query)  // User-written handler
            }
    }
}
```

## 2.5 Resource&lt;T&gt; — Async with Lifecycle

Resource is a higher-level wrapper around DataSource that explicitly models the loading lifecycle. Components bound to a Resource signal can react to loading, success, and error states individually. This is the primary way TabTab handles the three data states users configure per signal.

**State machine:**

| **State** | **Description** | **Component Behavior** |
|---|---|---|
| Idle | No fetch initiated yet | Show nothing or placeholder |
| Loading | Fetch in progress | Show spinner, skeleton, or stale data based on loading strategy |
| Success(data) | Data received successfully | Render data normally |
| Error(error, staleData?) | Fetch failed | Apply error strategy: empty, lastValue, fallback, or error UI |
| Refreshing(currentData) | Polling refresh in progress | Show current data (optimistic) with optional refresh indicator |

**YAML declaration:**

```
  customers:
    type: List<Customer>
    source: customersApi.list
    refreshInterval: 30s
    loading: skeleton
    onError: lastValue
```

```
# Components react to the resource lifecycle:
- LoadingSpinner: { visible: => customers.isLoading }
- DataTable: { visible: => customers.isReady, data: => customers }
- ErrorBoundary: { visible: => customers.isError, message: => customers.errorMessage }
```

The builder’s design canvas shows the appropriate state based on whether the data connection succeeds. If the API is unreachable, the designer shows the error state UI. If data is loading, the designer shows the configured loading strategy. This allows developers to design and test all three states visually.

# 3. Signal Dependency Graph

Signals form a directed acyclic graph (DAG) of dependencies. The graph is the central data structure that drives both design-time preview in the builder and runtime reactivity in the exported application.

## 3.1 Graph Structure

Each signal is a node in the graph. Edges represent dependencies — an edge from A to B means "B depends on A" (or equivalently, "when A changes, B needs to update"). The graph has three types of nodes:

- **Source nodes: **Mutable signals and DataSource signals. These have no incoming edges — they are the origins of data flow. User input and external data enter the graph through source nodes.
- **Transform nodes: **Computed signals. These have both incoming edges (dependencies) and outgoing edges (dependents). They transform data as it flows through the graph.
- **Sink nodes: **Component bindings and effects. These have only incoming edges — they consume data from the graph and produce visual output or side effects.
## 3.2 Graph Construction

The builder constructs the dependency graph when a project is loaded or when signals/bindings are modified. Construction follows these steps:

- Parse all signal declarations from the YAML project file.
- For each computed signal, analyze the derive expression to extract referenced signal names.
- For each component binding (=&gt; arrow), record the dependency from signal to component.
- For each effect, record dependencies on its watched signals.
- Perform topological sort to determine update order.
- Run cycle detection. If cycles are found, report with full dependency chain.
## 3.3 Cycle Detection & Diagnostics

Circular dependencies are detected during graph construction using Kahn’s algorithm (BFS-based topological sort). When a cycle is detected, the builder provides visual diagnostics:

- The offending signals are highlighted in red in the signal panel.
- A diagnostic message shows the full dependency chain: "searchQuery → filteredList → selectedItem → searchQuery"
- The cycle is drawn as a highlighted path in the signal graph visualization panel.
- The project cannot be exported until all cycles are resolved.
- The builder suggests fixes: "Break this cycle by converting one of these signals to a mutable signal with a handler."
**C++ implementation:**

```
struct CycleDetectionResult {
    bool hasCycle;
    std::vector<std::string> cyclePath;  // e.g., ["A", "B", "C", "A"]
    std::string suggestion;
};
```

```
CycleDetectionResult SignalGraph::detectCycles() {
    // Kahn's algorithm: BFS-based topological sort
    std::unordered_map<GraphNode*, int> inDegree;
    std::queue<GraphNode*> zeroInDegree;
    int processedCount = 0;
```

```
    // Calculate in-degrees
    for (auto& node : nodes_) {
        inDegree[node.get()] = node->dependencies().size();
        if (inDegree[node.get()] == 0)
            zeroInDegree.push(node.get());
    }
```

```
    // Process nodes with zero in-degree
    while (!zeroInDegree.empty()) {
        auto* current = zeroInDegree.front();
        zeroInDegree.pop();
        processedCount++;
        for (auto* dependent : current->dependents()) {
            if (--inDegree[dependent] == 0)
                zeroInDegree.push(dependent);
        }
    }
```

```
    if (processedCount == nodes_.size())
        return { false, {}, "" };
```

```
    // Cycle exists — trace it with DFS
    return { true, traceCycle(), generateSuggestion() };
}
```

# 4. Batched Propagation Engine

TabTab uses batched propagation to ensure efficient, glitch-free updates. When signals change, updates are collected and applied in a single pass at the end of the current frame tick.

## 4.1 Why Batched?

Consider a form submission that updates three signals simultaneously:

```
// User clicks "Save" — three signals change at once
customerName.set("Alice")
customerEmail.set("alice@example.com")
customerStatus.set(CustomerStatus.Active)
```

With synchronous propagation, a computed signal like displayLabel (which depends on all three) would recompute three times, and the UI would re-render three times with intermediate, inconsistent states. With batched propagation:

- All three set() calls queue dirty flags on the graph.
- At the end of the frame tick, the engine flushes the queue.
- Dirty nodes are sorted in topological order.
- Each node is evaluated exactly once with the final values of all its dependencies.
- The UI renders once with the fully consistent state.
## 4.2 Propagation Algorithm

**C++ implementation:**

```
class SignalGraph {
    std::vector<GraphNode*> dirtyNodes_;
    bool isFlushing_ = false;
```

```
public:
    void markDirty(GraphNode* node) {
        dirtyNodes_.push_back(node);
        // Also mark all transitive dependents as dirty
        for (auto* dep : node->dependents())
            markDirty(dep);
    }
```

```
    void flush() {
        if (isFlushing_ || dirtyNodes_.empty()) return;
        isFlushing_ = true;
```

```
        // Deduplicate and topologically sort
        auto sorted = topologicalSort(deduplicate(dirtyNodes_));
```

```
        // Evaluate each node in dependency order
        for (auto* node : sorted) {
            node->evaluate();  // Recompute value from dependencies
        }
```

```
        // Notify bound UI components
        for (auto* node : sorted) {
            for (auto* binding : node->uiBindings())
                binding->invalidate();  // Queue UI repaint
        }
```

```
        dirtyNodes_.clear();
        isFlushing_ = false;
    }
};
```

## 4.3 Frame Tick Integration

In the C++ builder, flush() is called at the end of each Skia render frame (typically 60fps). In the Kotlin export, the equivalent is the coroutine dispatcher — StateFlow already batches emissions within the same coroutine scope.

| **Runtime** | **Tick Mechanism** | **Flush Point** |
|---|---|---|
| C++ Builder | Skia render loop (16ms at 60fps) | After processing all input events, before canvas render |
| Kotlin Export | Coroutine dispatcher | StateFlow’s conflation automatically batches within scope |
| Quick-Run Preview | JVM event loop | Compose recomposition batches state reads automatically |

## 4.4 Glitch-Free Guarantee

The topological sort ensures that no computed signal is evaluated before all of its dependencies have been updated. This prevents "glitches" — momentary states where a computed signal has an inconsistent value because some but not all of its dependencies have been updated.

Example without glitch prevention:

```
// Signals: firstName = "Alice", lastName = "Smith"
// Computed: fullName = firstName + " " + lastName
// Computed: greeting = "Hello, " + fullName
```

```
// User changes firstName to "Bob"
// BAD (synchronous): greeting briefly shows "Hello, Bob Smith"
//   before lastName updates — but this IS correct in this case.
```

```
// The real glitch: two computed signals with shared dependencies
// Computed: initials = firstName[0] + lastName[0]
// If initials updates before fullName, the UI shows
//   mismatched initials and name for one frame.
```

```
// GOOD (batched + topological): all computeds evaluate in order,
//   UI renders once with consistent state.
```

# 5. Design-Time vs Runtime Behavior

The signal graph runs in two distinct environments: the C++ builder (design time) and the Kotlin/Compose Multiplatform output (runtime). The behavior is intentionally identical in terms of data flow, but the implementations differ.

## 5.1 Design-Time (C++ Builder)

At design time, the builder executes the signal graph to provide live data preview:

- Mutable signals are populated with their default values. The designer allows overriding values via the property inspector for testing.
- DataSource signals fetch real data using the builder’s C++ networking libraries (libcurl, libpq, etc.). Connections use credentials from the .tt.secrets file.
- Computed signals with inline derive expressions are evaluated by a lightweight expression evaluator in C++ that understands Kotlin collection operations (filter, map, count, sumOf, etc.).
- Computed signals with handler references show placeholder values marked with a code icon, indicating that full evaluation requires the quick-run preview.
- Effects are not executed at design time (they are side effects). They are shown as wired-up indicators in the signal graph panel.
- Resource signals display their current lifecycle state. If the API returns data, the designer shows the Success state. If the API is unreachable, the designer shows the Error state with the configured error strategy.
## 5.2 Runtime (Kotlin/Compose)

At runtime in the exported application, the signal graph is implemented using Kotlin StateFlow and Compose state:

| **Signal Primitive** | **Kotlin Implementation** | **Compose Integration** |
|---|---|---|
| Signal&lt;T&gt; | MutableStateFlow&lt;T&gt; in ViewModel | collectAsState() in composable |
| Computed&lt;T&gt; | combine/map operators on StateFlow | Automatic recomposition on change |
| DataSource&lt;T&gt; | Repository + suspend fun + StateFlow | LaunchedEffect triggers fetch |
| Effect | viewModelScope.launch + Flow.collect | Runs in ViewModel lifecycle |
| Resource&lt;T&gt; | sealed class Resource&lt;T&gt; in StateFlow | when (resource) { is Loading, is Success, is Error } |

# 6. Design-Time Expression Evaluator

The C++ builder includes a lightweight expression evaluator that can execute inline derive expressions at design time without compiling Kotlin. This evaluator understands a subset of Kotlin syntax focused on collection operations and simple transformations.

## 6.1 Supported Operations

| **Category** | **Operations** | **Example** |
|---|---|---|
| Collection filtering | filter, filterNot, filterNotNull | customers.filter { it.status == active } |
| Collection mapping | map, mapNotNull, flatMap | customers.map { it.name } |
| Collection aggregation | count, sumOf, average, minOf, maxOf | orders.sumOf { it.amount } |
| Collection sorting | sortedBy, sortedByDescending | customers.sortedBy { it.name } |
| Collection slicing | take, drop, first, last, distinctBy | customers.take(10) |
| String operations | contains, startsWith, endsWith, uppercase, lowercase, trim | name.contains(query, ignoreCase = true) |
| Boolean logic | &&, \|\|, !, ==, !=, &lt;, &gt;, &lt;=, &gt;= | age &gt;= 18 && status == active |
| Null handling | ?., ?:, !!,  != null | customer?.email ?: "N/A" |
| Field access | dot notation on model fields | customer.name, order.items.size |
| Arithmetic | +, -, \*, /, % | price \* quantity |

## 6.2 Limitations

The design-time evaluator intentionally does not support:

- Multi-statement expressions (if/else blocks, when expressions, variable declarations)
- Custom function calls (anything not in the supported operations list)
- Coroutines, suspend functions, or async operations
- Type casting, generics, or reflection
- Mutable state modification (expressions are pure — no side effects)
Expressions that exceed the evaluator’s capabilities must be declared as handler references. The builder detects unsupported syntax during YAML parsing and prompts the developer to move the logic to a Kotlin file.

# 7. Signal Graph Visualization

The builder includes a visual signal graph panel that displays the dependency graph as an interactive node diagram. This panel serves as both a debugging tool and a design tool for understanding data flow.

## 7.1 Visual Elements

| **Element** | **Appearance** | **Interaction** |
|---|---|---|
| Mutable Signal | Blue circle with pencil icon | Click to inspect value, edit default |
| DataSource Signal | Green circle with cloud icon | Click to inspect fetched data, refresh manually |
| Computed Signal | Orange circle with function icon | Click to see derive expression, inspect cached value |
| Effect | Purple diamond | Click to see watched signals and handler reference |
| Component Binding | Gray square with component name | Click to navigate to component on canvas |
| Dependency Edge | Directional arrow (source → dependent) | Hover to highlight full dependency chain |
| Cycle Error | Red pulsing edge with warning icon | Click to see suggested fix |
| Data Flow Animation | Animated dots along edges | Shows live data flowing through the graph |

## 7.2 Graph Layout

The graph is laid out using a layered (Sugiyama) algorithm that positions source nodes on the left, transform nodes in the middle, and sink nodes on the right. This left-to-right flow matches the mental model of data flowing from sources through transformations to the UI.

- The layout auto-adjusts as signals are added or removed.
- Users can manually reposition nodes and the layout persists in the YAML project file.
- Zoom and pan controls allow navigating large graphs.
- A minimap shows the full graph with the current viewport highlighted.
- Filtering controls let users show/hide signal types (e.g., show only DataSource signals and their dependents).
# 8. YAML Serialization

The signal graph is fully serialized in the .tt.yaml project file. This includes signal declarations, dependency metadata, and graph layout positions for the visualization panel.

## 8.1 Complete Signals Example

```
signals:
  # ── Mutable Signals (user input) ──
  searchQuery:
    type: String
    default: ""
```

```
  statusFilter:
    type: CustomerStatus?
    default: null
```

```
  currentPage:
    type: Int
    default: 1
    constraints: { min: 1 }
```

```
  sortColumn:
    type: String
    default: "name"
```

```
  sortAscending:
    type: Boolean
    default: true
```

```
  # ── DataSource Signals (external data) ──
  customers:
    type: List<Customer>
    source: api.customers
    params: { page: => currentPage, limit: 25 }
    refreshOn: currentPage
    refreshInterval: 60s
    loading: stale
    onError: lastValue
```

```
  # ── Computed Signals (derived state) ──
  filteredCustomers:
    type: Computed<List<Customer>>
    derive: >-
      customers
        .filter { statusFilter == null || it.status == statusFilter }
        .filter { it.name.contains(searchQuery, ignoreCase = true) }
```

```
  sortedCustomers:
    type: Computed<List<Customer>>
    derive: >-
      if (sortAscending)
        filteredCustomers.sortedBy { it[sortColumn] }
      else
        filteredCustomers.sortedByDescending { it[sortColumn] }
```

```
  totalCount:
    type: Computed<Int>
    derive: "filteredCustomers.size"
```

```
  hasResults:
    type: Computed<Boolean>
    derive: "filteredCustomers.isNotEmpty()"
```

```
  # ── Complex Computed (Kotlin handler) ──
  exportReport:
    type: Computed<ExportData>
    handler: generateExportReport
    dependsOn: [filteredCustomers, sortColumn, sortAscending]
```

```
effects:
  trackSearch:
    watch: [searchQuery]
    handler: logSearchEvent
    debounce: 1s
    skipInitial: true
```

```
  refreshOnFilter:
    watch: [statusFilter]
    handler: resetPagination
```

# 9. Code Generation Mapping

This section defines the precise mapping from each signal primitive to generated Kotlin/Compose Multiplatform code. The code generator produces idiomatic, readable Kotlin that a developer can understand and modify after export.

## 9.1 Generated File Structure

For each screen that uses signals, the code generator produces:

```
src/main/kotlin/
  viewmodels/
    CustomerListViewModel.kt    ← Signals become StateFlow properties
  repositories/
    CustomersRepository.kt       ← DataSource signals become repository classes
  models/
    Customer.kt                  ← Data classes from models section
    Resource.kt                  ← Shared sealed class for async state
  handlers/
    SearchHandler.kt             ← User-written business logic (preserved)
    ExportHandler.kt
```

## 9.2 ViewModel Generation

**Input (YAML signals):**

```
signals:
  searchQuery: { type: String, default: "" }
  customers: { type: List<Customer>, source: api.customers }
  filtered: { type: Computed<List<Customer>>,
    derive: "customers.filter { it.name.contains(searchQuery) }" }
```

**Output (generated Kotlin):**

```
class CustomerListViewModel(
    private val customersRepository: CustomersRepository
) : ViewModel() {
```

```
    // Signal<String> → MutableStateFlow
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
```

```
    // DataSource<List<Customer>> → Repository StateFlow
    val customers: StateFlow<Resource<List<Customer>>> =
        customersRepository.customers
```

```
    // Computed<List<Customer>> → combine + stateIn
    val filtered: StateFlow<List<Customer>> =
        combine(customers.mapSuccess(), searchQuery) { list, query ->
            list.filter { it.name.contains(query, ignoreCase = true) }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```

```
    // Mutable signal setter
    fun updateSearchQuery(value: String) {
        _searchQuery.value = value
    }
```

```
    // DataSource refresh
    init {
        viewModelScope.launch {
            customersRepository.refresh()
        }
    }
}
```

## 9.3 Repository Generation

**Input (YAML dataSource):**

```
dataSources:
  api:
    type: rest
    baseUrl: https://api.example.com/v1
    auth: { type: bearer, tokenRef: API_KEY }
    endpoints:
      customers: { method: GET, path: /customers, response: List<Customer> }
```

**Output (generated Kotlin):**

```
class CustomersRepository(
    private val httpClient: HttpClient  // Ktor client
) {
    private val baseUrl = System.getenv("API_BASE_URL")
        ?: "https://api.example.com/v1"
    private val apiKey = System.getenv("API_KEY")
```

```
    private val _customers = MutableStateFlow<Resource<List<Customer>>>(Resource.Loading())
    val customers: StateFlow<Resource<List<Customer>>> = _customers.asStateFlow()
```

```
    suspend fun refresh() {
        _customers.value = when (val current = _customers.value) {
            is Resource.Success -> Resource.Refreshing(current.data)
            else -> Resource.Loading()
        }
        try {
            val response: List<Customer> = httpClient.get("$baseUrl/customers") {
                header("Authorization", "Bearer $apiKey")
            }.body()
            _customers.value = Resource.Success(response)
        } catch (e: Exception) {
            _customers.value = Resource.Error(
                error = e,
                staleData = _customers.value.dataOrNull()
            )
        }
    }
}
```

## 9.4 Composable Binding Generation

**Input (YAML screen):**

```
- TextField: { value: => searchQuery, hint: "Search...", onValueChanged: updateSearch }
- DataTable: { data: => filtered, onRowClick: selectCustomer }
```

**Output (generated Kotlin):**

```
@Composable
fun CustomerListScreen(
    viewModel: CustomerListViewModel = viewModel()
) {
    val searchQuery by viewModel.searchQuery.collectAsState()
    val filtered by viewModel.filtered.collectAsState()
```

```
    Column(modifier = Modifier.padding(16.dp)) {
        TextField(
            value = searchQuery,
            onValueChange = { viewModel.updateSearchQuery(it) },
            placeholder = { Text("Search...") }
        )
```

```
        LazyColumn {
            items(filtered) { customer ->
                CustomerRow(
                    customer = customer,
                    onClick = { viewModel.selectCustomer(customer) }
                )
            }
        }
    }
}
```

# 10. Performance Considerations

## 10.1 Builder Performance Targets

| **Metric** | **Target** | **Measurement** |
|---|---|---|
| Signal update (single) | &lt; 1ms | Time from set() to graph flush completion |
| Graph flush (100 signals) | &lt; 5ms | Time to propagate batched changes through full graph |
| Graph flush (1000 signals) | &lt; 16ms | Must complete within one frame at 60fps |
| Expression evaluation | &lt; 2ms per expression | Inline derive evaluation for computed signals |
| DataSource initial fetch | Network-dependent | Non-blocking; UI shows loading state immediately |
| Canvas re-render after flush | &lt; 8ms | Skia repaint of changed components only (dirty rectangles) |

## 10.2 Optimization Strategies

- **Lazy evaluation: **Computed signals only re-evaluate when accessed by a bound component that is currently visible. Off-screen components don’t trigger computation.
- **Value equality check: **Before propagating a change, the graph checks whether the new value actually differs from the old value. If a computed signal’s result is unchanged, its dependents are not marked dirty.
- **Dirty rectangle rendering: **When a signal change affects only specific components, only those components’ canvas regions are repainted. Skia’s clip regions make this efficient.
- **Connection pooling: **DataSource connectors reuse HTTP connections and database connections across multiple signals.
- **Expression caching: **The C++ expression evaluator caches parsed ASTs for derive expressions. Only the evaluation step runs on each update, not the parsing step.
- **Graph partitioning: **For large projects, the graph can be partitioned per screen. Signals on inactive screens are suspended and don’t consume CPU.
# 11. Testing & Debugging

## 11.1 Signal Inspector

The builder includes a signal inspector panel that provides real-time debugging of the signal graph:

- View current value of any signal (formatted by type).
- View dependency list (what this signal depends on) and dependent list (what depends on this signal).
- Manually set signal values to test different states without modifying code.
- Time-travel debugging: scrub backward through signal state history to see how values changed.
- Breakpoints: pause propagation when a signal reaches a specific value.
## 11.2 Generated Test Helpers

The code generator optionally produces test utilities for each ViewModel:

```
// Generated test helper
class CustomerListViewModelTest {
    private val testRepository = FakeCustomersRepository()
    private val viewModel = CustomerListViewModel(testRepository)
```

```
    @Test
    fun `filtering customers by search query works`() = runTest {
        testRepository.emitCustomers(listOf(
            Customer(1, "Alice", "alice@test.com", CustomerStatus.Active),
            Customer(2, "Bob", "bob@test.com", CustomerStatus.Active),
        ))
```

```
        viewModel.updateSearchQuery("Ali")
        advanceUntilIdle()
```

```
        assertEquals(1, viewModel.filtered.value.size)
        assertEquals("Alice", viewModel.filtered.value[0].name)
    }
}
```

# 12. Future Extensions

The following extensions are architecturally planned but deferred from v1:

- **Embedded JVM evaluation (v2): **Full Kotlin expression evaluation at design time using JSR-223 scripting. Eliminates the expression evaluator’s limitations and provides exact parity between design-time and runtime behavior.
- **Signal persistence layer (v2): **Signals marked with persist: true automatically serialize to local storage and restore on app restart. The builder provides a visual persistence configuration panel.
- **Cross-screen signal sharing (v1.5): **Global signals that are accessible from any screen. Currently, signals are scoped per screen. Global signals will enable shared state like user authentication, theme preferences, and app-wide settings.
- **WebSocket / SSE data sources (v2): **Real-time data streaming via WebSocket or Server-Sent Events. DataSource signals will support a streaming mode where values push into the graph as they arrive.
- **Signal recording and replay (v2): **Record all signal changes during a session and replay them for debugging. This enables deterministic reproduction of bugs and visual regression testing.
- **Multi-framework export (v3): **The signal graph’s abstract nature allows targeting other frameworks. Additional code generators could map signals to React useState/useEffect, SwiftUI @State/@Published, or Qt property bindings.
