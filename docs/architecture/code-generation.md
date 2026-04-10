**TabTab**

Code Generation Pipeline

YAML to Kotlin/Compose Multiplatform

Version 1.0 — April 2026

*From Design to Deployable Application*

# 1. Overview

The code generation pipeline is the bridge between TabTab’s visual designer and a deployable Kotlin/Compose Multiplatform application. It reads the .tt.yaml project file and produces clean, idiomatic Kotlin source code that a developer can read, modify, maintain, and build independently of the TabTab builder. The generated code has no runtime dependency on TabTab — once exported, the developer fully owns the codebase.

## 1.1 Design Principles

- **Human-readable output: **Generated code should look as if a skilled Kotlin developer wrote it by hand. No obfuscation, no framework-specific boilerplate, no magic base classes.
- **No runtime dependency: **The exported project depends only on standard Kotlin, Compose Multiplatform, and Ktor (for HTTP). No TabTab library or runtime is required.
- **Deterministic generation: **The same YAML input always produces the same Kotlin output. No timestamps, no random IDs, no non-deterministic ordering.
- **User code is sacred: **User-written Kotlin files in the handlers/ directory are never overwritten. The generator warns before touching any file the user has modified.
- **Clean + optional comments: **Generated code is clean by default. An optional setting adds explanatory comments linking generated code back to the YAML source.
## 1.2 Two Modes of Generation

The code generator operates in two modes, optimized for different workflows:

| **Mode** | **Trigger** | **Behavior** | **Use Case** |
|---|---|---|---|
| Full Export | User clicks "Export Project" | Reads entire YAML, generates complete Kotlin project from scratch, writes all files | Final export, sharing, distribution |
| Incremental (Quick-Run) | User clicks "Run" or presses F5 | Detects changed YAML sections, regenerates only affected files, triggers incremental compilation | Iterative development, rapid feedback |

Full export always produces a complete, self-contained Gradle project. Incremental generation maintains a shadow build directory and only updates changed files, leveraging the Kotlin compiler daemon for fast recompilation.

# 2. Pipeline Architecture

The code generation pipeline consists of five sequential stages. Each stage transforms the project data from one representation to the next, culminating in a complete Kotlin/Compose Multiplatform project.

## 2.1 Pipeline Stages

| **Stage** | **Input** | **Output** | **Description** |
|---|---|---|---|
| 1. Parse | .tt.yaml file(s) | Project AST | YAML parser validates schema, resolves cross-references, builds in-memory project model |
| 2. Resolve | Project AST | Resolved Model | Resolves signal dependencies, validates bindings, type-checks model references, detects cycles |
| 3. Plan | Resolved Model | Generation Plan | Determines which files to generate, maps YAML sections to Kotlin file targets, calculates imports |
| 4. Generate | Generation Plan | Kotlin source files | Template engine produces Kotlin source code for each planned file |
| 5. Scaffold | Kotlin source files | Complete Gradle project | Wraps generated code in Gradle project structure with build.gradle.kts, dependencies, resources |

## 2.2 C++ Implementation

The entire pipeline runs in the C++ builder process. Each stage is implemented as a C++ class with a well-defined interface:

```
class CodeGenPipeline {
public:
    ExportResult exportFull(const ProjectFile& yaml, const ExportOptions& opts);
    QuickRunResult exportIncremental(const ProjectFile& yaml, const ChangeSet& changes);
```

```
private:
    ProjectAST parse(const ProjectFile& yaml);
    ResolvedModel resolve(const ProjectAST& ast);
    GenerationPlan plan(const ResolvedModel& model, const ExportOptions& opts);
    std::vector<GeneratedFile> generate(const GenerationPlan& plan);
    void scaffold(const std::vector<GeneratedFile>& files, const fs::path& outputDir);
};
```

# 3. YAML-to-Kotlin Mapping Reference

This section defines the precise mapping from each YAML section to generated Kotlin code. These mappings are the core of the code generator.

| **YAML Section** | **Generated Kotlin** | **Pattern** |
|---|---|---|
| project | build.gradle.kts, settings.gradle.kts | Standard Gradle Kotlin DSL project configuration |
| models | data class / enum class per model | One file per model in models/ package |
| theme | Theme.kt with MaterialTheme wrapper | Compose theming with color scheme + typography |
| dataSources (REST) | Repository class + Ktor HttpClient | Repository pattern with suspend functions |
| dataSources (SQL) | Repository class + JDBC | Repository pattern with coroutine-wrapped queries |
| signals (mutable) | MutableStateFlow&lt;T&gt; in ViewModel | Private mutable, public read-only exposure |
| signals (computed) | combine() / map() on StateFlow | Derived state via Kotlin Flow operators |
| signals (dataSource) | Repository injection + StateFlow | ViewModel observes Repository StateFlow |
| effects | viewModelScope.launch + Flow.collect | Debounced/throttled collectors in ViewModel init |
| screens + children | @Composable functions | One file per screen with component hierarchy |
| component bindings (=&gt;) | collectAsState() + state reads | Compose state collection in composable scope |
| event handlers | ViewModel function references | Lambda passed from composable to ViewModel |
| navigation | NavHost with composable routes | Compose Navigation with typed arguments |
| assets | src/main/resources/ + painterResource | Standard Compose resource loading |

# 4. Generated Project Structure

The full export produces a standard Kotlin/Compose Multiplatform project that can be opened in IntelliJ IDEA or built from the command line with Gradle.

## 4.1 Directory Layout

```
customer-manager/
  build.gradle.kts                    # Generated
  settings.gradle.kts                 # Generated
  gradle.properties                   # Generated
  src/main/kotlin/
    com/example/customers/
      App.kt                           # Generated — entry point + NavHost
      theme/
        Theme.kt                       # Generated — MaterialTheme wrapper
      models/
        Customer.kt                    # Generated — data class
        CustomerStatus.kt              # Generated — enum class
        Resource.kt                    # Generated — sealed class for async
      screens/
        CustomerListScreen.kt          # Generated — @Composable
      viewmodels/
        CustomerListViewModel.kt       # Generated — signals + logic
      repositories/
        ApiRepository.kt               # Generated — data access
      navigation/
        NavGraph.kt                    # Generated — navigation routes
      handlers/                        # USER-WRITTEN — never overwritten
        SearchHandler.kt
        ExportHandler.kt
  src/main/resources/
    fonts/
    images/
```

## 4.2 File Ownership Rules

Every file in the exported project has a clear ownership designation:

| **Directory** | **Ownership** | **On Re-Export** |
|---|---|---|
| build.gradle.kts | Generated | Regenerated. User customizations via build.extra.gradle.kts include. |
| models/ | Generated | Regenerated from YAML models section. Warns if user has modified. |
| theme/ | Generated | Regenerated from YAML theme section. |
| screens/ | Generated | Regenerated from YAML screens section. Warns if user has modified. |
| viewmodels/ | Generated | Regenerated from YAML signals section. Warns if user has modified. |
| repositories/ | Generated | Regenerated from YAML dataSources section. Warns if user has modified. |
| navigation/ | Generated | Regenerated from YAML navigation section. |
| handlers/ | User-owned | NEVER overwritten. New handler stubs added but existing files untouched. |
| resources/ | Mixed | Assets from YAML are copied. User-added resources are preserved. |

## 4.3 User Modification Detection

The generator embeds a hash comment at the top of every generated file:

```
// Generated by TabTab v1.0 — hash:a3f8c2d1
// Modifications to this file will be detected on re-export.
```

```
package com.example.customers.viewmodels
...
```

On re-export, the generator computes the expected hash. If the file’s actual hash differs, the user has modified the file. The builder presents a dialog with options to Overwrite, Skip, or Diff.

# 5. Model Generation

The models section generates Kotlin data classes and enum classes.

## 5.1 Data Class Generation

**Input (YAML):**

```
models:
  Customer:
    fields:
      id: Int
      name: String
      email: String
      status: CustomerStatus
      createdAt: DateTime
```

**Output (Kotlin):**

```
package com.example.customers.models
```

```
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
```

```
@Serializable
data class Customer(
    val id: Int,
    val name: String,
    val email: String,
    val status: CustomerStatus,
    val createdAt: Instant
)
```

## 5.2 Enum Class Generation

**Input (YAML):**

```
  CustomerStatus:
    type: enum
    values: [active, inactive, pending]
```

**Output (Kotlin):**

```
package com.example.customers.models
```

```
import kotlinx.serialization.Serializable
```

```
@Serializable
enum class CustomerStatus {
    ACTIVE,
    INACTIVE,
    PENDING
}
```

# 6. Theme Generation

The theme section generates a Compose MaterialTheme wrapper that configures colors, typography, and shapes.

**Input (YAML):**

```
theme:
  system: material3
  palette: light-blue
  mode: system
  overrides:
    colors:
      primary: "#1A73E8"
      secondary: "#34A853"
```

**Output (Kotlin):**

```
package com.example.customers.theme
```

```
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
```

```
private val LightColorScheme = lightColorScheme(
    primary = Color(0xFF1A73E8),
    secondary = Color(0xFF34A853),
    // ... remaining tokens from light-blue base
)
```

```
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        content = content
    )
}
```

# 7. Repository Generation

Each data source generates a repository class. The repository pattern encapsulates data access behind a clean StateFlow-based interface that ViewModels observe.

## 7.1 REST API Repository

**Input (YAML):**

```
dataSources:
  api:
    type: rest
    baseUrl: https://api.example.com/v1
    auth: { type: bearer, tokenRef: API_KEY }
    endpoints:
      customers:
        method: GET
        path: /customers
        response: List<Customer>
```

**Output (Kotlin):**

```
class ApiRepository(private val client: HttpClient) {
```

```
    private val baseUrl = System.getenv("API_BASE_URL")
        ?: "https://api.example.com/v1"
    private val apiKey = System.getenv("API_KEY") ?: ""
```

```
    private val _customers = MutableStateFlow<Resource<List<Customer>>>(Resource.Loading())
    val customers: StateFlow<Resource<List<Customer>>> = _customers.asStateFlow()
```

```
    suspend fun refreshCustomers() {
        _customers.value = Resource.Loading()
        try {
            val data: List<Customer> = client.get("$baseUrl/customers") {
                header("Authorization", "Bearer $apiKey")
            }.body()
            _customers.value = Resource.Success(data)
        } catch (e: Exception) {
            _customers.value = Resource.Error(e, _customers.value.dataOrNull())
        }
    }
}
```

# 8. ViewModel Generation

ViewModels are the central generated artifact. Each screen produces a ViewModel containing all signals as StateFlow properties, computed derivations, event handler wiring, and effect collectors.

## 8.1 Signal Mapping

| **YAML Signal Type** | **Generated Kotlin** | **Access Pattern** |
|---|---|---|
| Mutable (type + default) | private val \_name = MutableStateFlow(default)
val name = \_name.asStateFlow() | collectAsState() / updateName(value) |
| DataSource (type + source) | val name = repository.name | collectAsState() / refresh() |
| Computed (type + derive) | combine(...) { ... }.stateIn(...) | collectAsState(), auto-updates |
| Computed (handler) | combine(...) { handlerFn(...) }.stateIn(...) | collectAsState(), calls user function |

## 8.2 Complete ViewModel Example

**Input (YAML):**

```
signals:
  searchQuery: { type: String, default: "" }
  customers: { type: List<Customer>, source: api.customers, refreshInterval: 30s }
  filteredCustomers:
    type: Computed<List<Customer>>
    derive: "customers.filter { it.name.contains(searchQuery, ignoreCase = true) }"
```

**Output (Kotlin):**

```
class CustomerListViewModel(
    private val apiRepository: ApiRepository
) : ViewModel() {
```

```
    // Mutable Signals
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
```

```
    // DataSource Signals
    val customers: StateFlow<Resource<List<Customer>>> = apiRepository.customers
```

```
    // Computed Signals
    val filteredCustomers: StateFlow<List<Customer>> =
        combine(customers.mapSuccess(), searchQuery) { list, query ->
            list.filter { it.name.contains(query, ignoreCase = true) }
        }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```

```
    fun updateSearchQuery(value: String) { _searchQuery.value = value }
```

```
    init {
        viewModelScope.launch {
            while (isActive) {
                apiRepository.refreshCustomers()
                delay(30_000)
            }
        }
    }
}
```

# 9. Screen Generation

Each screen generates a @Composable function. The generator walks the component tree, translates each component to Compose, and wires up signal bindings and event handlers.

## 9.1 Component Translation

| **TabTab Component** | **Compose Composable** | **Key Mapping** |
|---|---|---|
| Button (filled) | Button(onClick) { Text(...) } | variant maps to Button/OutlinedButton/TextButton |
| TextField | OutlinedTextField(value, onValueChange) | =&gt; binding becomes collectAsState() |
| Text | Text(text, style = typography.X) | style.variant maps to typography scale |
| Row | Row(horizontalArrangement, verticalAlignment) | layout.justify → Arrangement |
| Column | Column(verticalArrangement, horizontalAlignment) | Same as Row, axes swapped |
| DataTable | Custom LazyColumn with Row cells | Header row + data rows + sort handlers |
| Card | Card/ElevatedCard/OutlinedCard | variant maps to Card type |
| Dialog | AlertDialog(onDismissRequest) | visible signal controls show/dismiss |
| NavigationRail | NavigationRail { NavigationRailItem(...) } | selected signal → selectedItem state |

## 9.2 Complete Screen Example

**Output (generated Kotlin):**

```
@Composable
fun CustomerListScreen(
    viewModel: CustomerListViewModel = viewModel(),
    onNavigateToCreate: () -> Unit = {},
) {
    val searchQuery by viewModel.searchQuery.collectAsState()
    val filteredCustomers by viewModel.filteredCustomers.collectAsState()
```

```
    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Customers", style = MaterialTheme.typography.headlineMedium)
            Button(onClick = onNavigateToCreate) {
                Icon(Icons.Outlined.Add, contentDescription = null)
                Spacer(Modifier.width(8.dp))
                Text("Add")
            }
        }
```

```
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { viewModel.updateSearchQuery(it) },
            placeholder = { Text("Search...") },
            leadingIcon = { Icon(Icons.Outlined.Search, null) },
            modifier = Modifier.fillMaxWidth()
        )
```

```
        CustomerDataTable(
            data = filteredCustomers,
            onRowClick = { viewModel.selectCustomer(it) }
        )
    }
}
```

# 10. Navigation Generation

The navigation section generates a Compose Navigation graph with typed routes, argument passing, and transition animations.

**Output (generated Kotlin):**

```
sealed class Route(val path: String) {
    object CustomerList : Route("/customers")
    object CustomerDetail : Route("/customers/{customerId}") {
        fun create(customerId: Int) = "/customers/$customerId"
    }
}
```

```
@Composable
fun AppNavGraph(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = Route.CustomerList.path) {
        composable(route = Route.CustomerList.path) {
            CustomerListScreen(
                onNavigateToDetail = { id ->
                    navController.navigate(Route.CustomerDetail.create(id))
                }
            )
        }
        composable(
            route = Route.CustomerDetail.path,
            arguments = listOf(navArgument("customerId") { type = NavType.IntType }),
            enterTransition = { slideInHorizontally(initialOffsetX = { it }) },
        ) { entry ->
            val id = entry.arguments?.getInt("customerId") ?: return@composable
            CustomerDetailScreen(customerId = id)
        }
    }
}
```

# 11. Gradle Project Generation

The scaffold stage wraps all generated Kotlin source files in a complete Gradle project.

## 11.1 build.gradle.kts

```
plugins {
    kotlin("jvm") version "2.0.0"
    id("org.jetbrains.compose") version "1.6.10"
    kotlin("plugin.serialization") version "2.0.0"
}
```

```
dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation("org.jetbrains.androidx.navigation:navigation-compose:2.7.7")
    implementation("org.jetbrains.androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("io.ktor:ktor-client-core:2.3.9")
    implementation("io.ktor:ktor-client-cio:2.3.9")
    implementation("io.ktor:ktor-client-content-negotiation:2.3.9")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.9")
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:0.5.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
}
```

```
compose.desktop {
    application {
        mainClass = "com.example.customers.AppKt"
        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "customer-manager"
        }
    }
}
```

```
// User customizations: build.extra.gradle.kts
if (file("build.extra.gradle.kts").exists()) {
    apply(from = "build.extra.gradle.kts")
}
```

## 11.2 App Entry Point

```
fun main() = application {
    Window(onCloseRequest = ::exitApplication, title = "Customer Manager") {
        AppTheme {
            AppNavGraph()
        }
    }
}
```

# 12. Shared Utilities

The generator produces shared utility classes used across the application.

## 12.1 Resource Sealed Class

```
sealed class Resource<out T> {
    class Loading<T> : Resource<T>()
    data class Success<T>(val data: T) : Resource<T>()
    data class Error<T>(val error: Throwable, val staleData: T? = null) : Resource<T>()
    data class Refreshing<T>(val currentData: T) : Resource<T>()
```

```
    fun dataOrNull(): T? = when (this) {
        is Success -> data
        is Refreshing -> currentData
        is Error -> staleData
        is Loading -> null
    }
}
```

# 13. Quick-Run Incremental Pipeline

The incremental pipeline is optimized for the quick-run preview cycle, minimizing time from pressing F5 to seeing the running application.

## 13.1 Change Detection

The builder tracks which YAML sections changed since the last quick-run:

| **Changed YAML Section** | **Regenerated Files** | **Unchanged Files** |
|---|---|---|
| signals (one modified) | Affected ViewModel only | All screens, repositories, models, theme |
| screens (one modified) | Affected Screen composable | All ViewModels, repositories, models |
| dataSources (endpoint added) | Affected Repository only | All screens, ViewModels, models, theme |
| models (field added) | Affected Model + dependent VMs | Screens, repositories (if types unchanged) |
| theme (color changed) | Theme.kt only | Everything else |
| navigation (route added) | NavGraph.kt + affected Screen | All ViewModels, repositories, models |

## 13.2 Build Cycle

- User modifies YAML in the visual designer or code editor.
- Builder detects changed sections via diff against last-known state.
- Incremental generator regenerates only affected Kotlin files into shadow build directory.
- Kotlin compiler daemon (already warm) incrementally compiles changed files.
- Application launches in preview window. Target: under 5 seconds end-to-end.
## 13.3 Background JVM Management

- JVM is lazy-started on first quick-run and kept alive for the session.
- Kotlin compiler daemon runs inside this JVM, staying warm between compilations.
- Memory capped at configurable limit (default 512MB). Builder monitors and restarts if needed.
- On project close, JVM is gracefully shut down.
- Builder communicates with JVM via local socket using a simple command protocol.
# 14. Handler Stub Generation

When YAML references a handler without a corresponding Kotlin file, the generator creates a stub in handlers/ with the correct signature and a TODO marker.

**Generated stub (handlers/LogSearchEventHandler.kt):**

```
package com.example.customers.handlers
```

```
/**
 * Handler: logSearchEvent
 * Triggered by: effect "trackSearch"
 * Watches: [searchQuery]
 *
 * TODO: Implement this handler.
 */
fun logSearchEvent(searchQuery: String) {
    // TODO: Implement search event logging
    println("Search query changed: $searchQuery")
}
```

Stubs are only generated when the file does not exist. Existing handler files are never overwritten.

# 15. Pre-Generation Validation

Before generating code, the pipeline runs a comprehensive validation pass. Errors prevent export and are displayed with actionable messages.

| **Category** | **Check** | **Error Message** |
|---|---|---|
| Signal bindings | Every =&gt; reference maps to a defined signal | "Unknown signal 'xyz' in TextField.value binding" |
| DataSource refs | Every source reference maps to a defined dataSource | "DataSource 'api.users' not found" |
| Model types | Every type maps to a defined model or built-in | "Unknown type 'Order' in signal 'orders'" |
| Handler refs | Every handler has a .kt file or generates a stub | "Handler 'processPayment' not found. Stub will be generated." (warning) |
| Cycle detection | Signal dependency graph is acyclic | "Circular dependency: search → filtered → highlight → search" |
| Navigation refs | All routes map to defined screens | "Screen 'settings' not defined in screens section" |
| Component IDs | IDs are unique within each screen | "Duplicate ID 'submitBtn' in screen 'customerForm'" |
| Type compatibility | Binding types match component expectations | "DataTable.data expects List&lt;T&gt; but 'customerName' is String" |

| **Severity** | **Behavior** | **Example** |
|---|---|---|
| Error | Blocks export. Must be fixed. | Circular dependency, undefined signal, type mismatch |
| Warning | Export proceeds. Shown in output panel. | Missing handler (stub generated), unused signal |
| Info | Logged for developer reference. | New stubs created, deprecated syntax detected |

# 16. Future Extensions

- **Multi-target code generation (v2+): **The pipeline architecture supports pluggable generators. The same Resolved Model could feed a React/TypeScript, SwiftUI, or Qt/C++ generator. Each target is a self-contained module.
- **GraalVM native-image (v2): **Optional native-image build configuration for minimal startup time and memory. Compiles Kotlin to a standalone native binary.
- **Embedded JVM for live generation (v2): **Feed source code directly into an embedded Kotlin scripting engine for instant preview, eliminating file I/O and compilation overhead.
- **Code formatting integration (v1.x): **Optional ktlint or ktfmt pass on output. Currently the generator produces well-formatted code directly.
- **Test generation (v1.x): **Optional unit tests for ViewModels, testing signal derivations with FakeRepository pattern.
- **Plugin API for custom generators (v2+): **Third-party plugins register custom generator modules for community-built export targets or alternative architecture styles.
