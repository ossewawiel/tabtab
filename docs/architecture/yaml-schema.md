**TabTab**

YAML Schema Specification

Project Format for Visual UI Designer & Builder

Schema Version: 1.0

```
File Extension: .tt.yaml
```

*April 2026 — Draft*

# 1. Overview

The .tt.yaml file format is the central project artifact in TabTab. It captures the complete definition of an application’s UI, data bindings, theme selection, reactive signals, and references to Kotlin source files containing business logic. The format is designed to be human-readable, version-control friendly, and parseable by both the TabTab builder (C++) and the code generation pipeline.

## 1.1 Design Principles

- **Human-readable: **A developer should be able to read and hand-edit the YAML without the builder. The format favors clarity over compactness.
- **Declarative: **YAML describes what the UI looks like and how data flows. Complex logic lives in Kotlin files, referenced by name.
- **Single source of truth: **The .tt.yaml file is the canonical representation. The visual designer reads and writes it. The code generator reads it. No shadow state.
- **Version-control friendly: **Clean diffs, mergeable structure, no binary blobs.
- **Schema versioned: **Every file declares its schema version. TabTab provides automated migration between schema versions.
## 1.2 File Organization

TabTab supports two project structures, automatically managed by the builder:

**Single-file mode **(small projects, ≤3 screens):

```
project-name/
  project.tt.yaml        ← Everything in one file
  handlers/              ← User-written Kotlin logic
  assets/                ← Images, fonts, icons
  .tt.secrets            ← Credentials (gitignored)
```

**Multi-file mode **(larger projects, auto-split by builder):

```
project-name/
  project.tt.yaml        ← Project metadata, theme, dataSources, signals
  screens/
    customerList.tt.yaml ← Per-screen component trees
    dashboard.tt.yaml
    settings.tt.yaml
  navigation.tt.yaml     ← Navigation graph
  handlers/              ← User-written Kotlin logic
  assets/                ← Images, fonts, icons
  .tt.secrets            ← Credentials (gitignored)
```

The builder automatically splits a single-file project into multi-file when the project exceeds 3 screens. All cross-references use the same naming conventions regardless of mode.

# 2. Top-Level Schema

Every .tt.yaml file begins with a schema version declaration followed by top-level sections. All sections are optional except schema and project.

| **Section** | **Required** | **Description** |
|---|---|---|
| schema | Yes | Schema version for migration support |
| project | Yes | Project metadata: name, version, description, targets |
| theme | No | Design system selection, palette, typography, token overrides |
| dataSources | No | External data connections: REST, GraphQL, SQL, files, OS APIs |
| signals | No | Reactive state: signals, computed values, data source bindings |
| models | No | Data model type definitions used by signals and components |
| screens | No\* | UI screen definitions with component trees (\*required in single-file mode) |
| navigation | No | Navigation graph between screens |
| assets | No | Static resource references: images, fonts, icon sets |

## 2.1 Minimal Valid Project

```
schema: 1
```

```
project:
  name: my-app
  version: 0.1.0
```

```
screens:
  main:
    root: Column
    children:
      - Text: { value: "Hello, TabTab!" }
```

# 3. Project Section

Defines project-level metadata used by the builder and the code generator.

```
project:
  name: customer-manager
  version: 1.0.0
  description: "Customer relationship management tool"
  kotlin: 2.0.0
  compose: 1.6.10
  targets: [windows, macos, linux]
  package: com.example.customermanager
```

| **Field** | **Type** | **Required** | **Description** |
|---|---|---|---|
| `name` | `String` | Yes | Project identifier, used as Gradle project name. Lowercase, hyphens allowed. |
| `version` | `SemVer` | Yes | Project version following semantic versioning. |
| `description` | `String` | No | Human-readable project description. |
| `kotlin` | `String` | No | Kotlin version to use. Defaults to latest stable. |
| `compose` | `String` | No | Compose Multiplatform version. Defaults to latest stable. |
| `targets` | `List<String>` | No | Target platforms: windows, macos, linux. Defaults to all three. |
| `package` | `String` | No | Kotlin package name for generated code. Derived from name if omitted. |

# 4. Theme Section

Defines the visual design system, color palette, typography, and spacing tokens. The theme section controls how all components render in both the builder and the exported application.

## 4.1 Basic Theme Selection

```
theme:
  system: material3       # material3 | fluent | custom
  palette: light-blue     # Pre-built palette name
  mode: light             # light | dark | system
  typography: default     # default | compact | comfortable
  density: standard       # standard | comfortable | compact
```

## 4.2 Token Overrides

Individual design tokens can be overridden while keeping the rest of the system coherent:

```
theme:
  system: material3
  palette: light-blue
  overrides:
    colors:
      primary: "#1A73E8"
      secondary: "#34A853"
      background: "#FAFAFA"
      surface: "#FFFFFF"
      error: "#D93025"
      onPrimary: "#FFFFFF"
    typography:
      heading:
        fontFamily: "Inter"
        fontWeight: 700
      body:
        fontFamily: "Inter"
        fontSize: 14
    spacing:
      unit: 4              # Base grid unit in dp
      containerPadding: 16
      componentGap: 8
    shape:
      small: 4             # Corner radius in dp
      medium: 8
      large: 16
```

## 4.3 Custom Design System

For fully custom design systems, provide a design system definition file:

```
theme:
  system: custom
  definition: ./themes/corporate-brand.tt-theme.yaml
```

The .tt-theme.yaml file defines a complete token set that the builder loads as an additional design system option. See the Design System Plugin specification for the full schema.

# 5. Data Sources Section

Defines external data connections that the builder uses for live data preview at design time and the code generator uses to produce repository classes at export time.

## 5.1 REST API

```
dataSources:
  customersApi:
    type: rest
    baseUrl: https://api.example.com/v1
    auth:
      type: bearer                  # bearer | basic | apiKey | oauth2
      tokenRef: CUSTOMERS_API_KEY   # References .tt.secrets
    headers:
      Accept: application/json
      X-Client: TabTab
    endpoints:
      list:
        method: GET
        path: /customers
        params: { page: 1, limit: 50 }
        response: List<Customer>
      detail:
        method: GET
        path: /customers/{id}
        response: Customer
      create:
        method: POST
        path: /customers
        body: CustomerCreateRequest
        response: Customer
```

## 5.2 GraphQL

```
  analyticsApi:
    type: graphql
    url: https://api.example.com/graphql
    auth:
      type: bearer
      tokenRef: ANALYTICS_KEY
    queries:
      revenueByMonth:
        query: |
          query RevenueByMonth($year: Int!) {
            revenue(year: $year) { month amount }
          }
        variables: { year: 2026 }
        response: List<MonthlyRevenue>
```

## 5.3 SQL Database

```
  localDb:
    type: sql
    driver: sqlite                  # sqlite | postgresql | mysql
    connectionRef: LOCAL_DB_PATH    # References .tt.secrets
    queries:
      allProducts:
        sql: "SELECT * FROM products WHERE active = 1"
        response: List<Product>
      productById:
        sql: "SELECT * FROM products WHERE id = :id"
        params: { id: Int }
        response: Product
```

## 5.4 Local Files

```
  configFile:
    type: file
    path: ./data/config.json
    format: json                    # json | csv | xml
    watch: true                     # Auto-reload on file change
    response: AppConfig
```

## 5.5 OS APIs

```
  fileSystem:
    type: os
    api: fileSystem                 # fileSystem | environment | systemInfo
    config:
      rootPath: ~/Documents
      filters: ["*.pdf", "*.docx"]
      recursive: false
```

# 6. Secrets File (.tt.secrets)

Credentials and sensitive configuration are stored in a separate .tt.secrets file that must be gitignored. Data source definitions in .tt.yaml reference secrets by key name using the tokenRef and connectionRef fields.

```
# .tt.secrets — NEVER commit this file
CUSTOMERS_API_KEY: sk-live-abc123def456
ANALYTICS_KEY: gql-token-xyz789
LOCAL_DB_PATH: /Users/dev/data/app.sqlite
PG_CONNECTION: postgresql://user:pass@localhost:5432/mydb
```

The builder reads this file at startup and stores values in an in-memory encrypted store. Values are never written to the YAML project file or included in code generation output. Exported Kotlin projects reference credentials via environment variables or a configuration file that the developer manages independently.

# 7. Models Section

Defines data model types used by signals, data sources, and component bindings. Models are lightweight type definitions that the builder uses for design-time type checking and the code generator uses to produce Kotlin data classes.

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

```
  CustomerStatus:
    type: enum
    values: [active, inactive, pending]
```

```
  MonthlyRevenue:
    fields:
      month: String
      amount: Double
```

```
  CustomerCreateRequest:
    fields:
      name: String
      email: String
```

## 7.1 Supported Types

| **Type** | **Kotlin Mapping** | **Description** |
|---|---|---|
| String | String | Text value |
| Int | Int | 32-bit integer |
| Long | Long | 64-bit integer |
| Double | Double | 64-bit floating point |
| Boolean | Boolean | true/false |
| DateTime | kotlinx.datetime.Instant | ISO 8601 timestamp |
| Date | kotlinx.datetime.LocalDate | Date without time |
| List&lt;T&gt; | List&lt;T&gt; | Ordered collection of type T |
| Map&lt;K,V&gt; | Map&lt;K,V&gt; | Key-value mapping |
| T? | T? | Nullable version of any type |
| enum | enum class | Enumerated type with named values |

# 8. Signals Section

Defines the reactive state layer. Signals are named, typed values that components bind to. When a signal changes, all bound components update automatically. This is the core of TabTab’s reactive data flow model.

## 8.1 Signal Types

| **Signal Type** | **YAML Keyword** | **Description** | **Kotlin Export** |
|---|---|---|---|
| Mutable Signal | type + default | User-editable reactive value | MutableStateFlow&lt;T&gt; |
| DataSource Signal | type + source | Value populated from external data source | Repository + StateFlow&lt;T&gt; |
| Computed Signal | type + derive | Derived value from other signals | combine/map on StateFlow |

## 8.2 Mutable Signals

Mutable signals hold user-editable state. UI components that accept input (TextField, Slider, Checkbox, etc.) write to mutable signals.

```
signals:
  searchQuery:
    type: String
    default: ""
```

```
  selectedTab:
    type: Int
    default: 0
```

```
  darkMode:
    type: Boolean
    default: false
```

```
  priceRange:
    type: Double
    default: 100.0
    constraints: { min: 0, max: 1000 }
```

## 8.3 DataSource Signals

DataSource signals are populated by external data connections defined in the dataSources section. The builder fetches data at design time and pushes it into these signals for live preview.

```
  customers:
    type: List<Customer>
    source: customersApi.list
    refreshInterval: 30s
    onError: empty                  # empty | lastValue | fallback
    fallback: []
```

```
  currentCustomer:
    type: Customer?
    source: customersApi.detail
    params: { id: => selectedCustomerId }
    refreshOn: selectedCustomerId   # Re-fetch when this signal changes
```

## 8.4 Computed Signals

Computed signals derive their value from other signals using inline expressions. Simple, single-expression derivations (filters, maps, sorts, field access) can be inline. Complex logic should reference a Kotlin function.

```
  # Inline derivation — simple filter
  filteredCustomers:
    type: Computed<List<Customer>>
    derive: "customers.filter { it.name.contains(searchQuery) }"
```

```
  # Inline derivation — simple count
  activeCount:
    type: Computed<Int>
    derive: "customers.count { it.status == CustomerStatus.active }"
```

```
  # Inline derivation — simple transform
  customerNames:
    type: Computed<List<String>>
    derive: "customers.map { it.name }"
```

```
  # Complex logic — reference to Kotlin handler
  creditReport:
    type: Computed<CreditReport>
    handler: generateCreditReport   # → handlers/CreditReportHandler.kt
    dependsOn: [currentCustomer, priceRange]
```

# 9. Screens Section

Defines the UI for each screen as a hierarchical component tree. Each screen has a root layout component and nested children. Component properties can be static values or signal bindings using the =&gt; arrow syntax.

## 9.1 Screen Structure

```
screens:
  customerList:
    title: "Customers"
    root: Column
    layout: { padding: 16, spacing: 8 }
    children:
      - ...components
```

| **Field** | **Type** | **Required** | **Description** |
|---|---|---|---|
| `title` | `String` | No | Screen title, shown in navigation and window title bar |
| `root` | `LayoutType` | Yes | Root layout component: Column, Row, Box, or Grid |
| `layout` | `LayoutProps` | No | Layout properties for the root container |
| `children` | `List<Component>` | Yes | Ordered list of child components |

## 9.2 Component Syntax

Components are declared as YAML map entries where the key is the component type and the value is a map of properties. Component IDs are optional and only required when the component is referenced by event handlers or code.

```
# Simple component — static properties
- Text: { value: "Welcome to TabTab" }
```

```
# Component with signal binding (=> arrow syntax)
- TextField: { value: => searchQuery, hint: "Search customers..." }
```

```
# Component with ID (needed for event handler reference)
- Button:
    id: searchBtn
    text: "Search"
    variant: filled              # filled | outlined | text | elevated
    onClick: handleSearch
```

```
# Component with multiple event handlers
- TextField:
    id: nameField
    value: => customerName
    hint: "Enter name"
    onValueChanged: validateName
    onFocus: showNameHelp
    onSubmit: saveCustomer
```

## 9.3 Binding Syntax: The =&gt; Arrow

The =&gt; prefix indicates a signal binding. Any component property can be bound to a signal. Static values have no prefix. This distinction tells the builder and code generator which properties are reactive.

| **Syntax** | **Meaning** | **Example** |
|---|---|---|
| value: "Hello" | Static string value | Text: { value: "Hello" } |
| value: =&gt; mySignal | Bound to signal named mySignal | Text: { value: =&gt; customerName } |
| visible: =&gt; isLoggedIn | Conditionally visible based on signal | Panel: { visible: =&gt; isLoggedIn } |
| data: =&gt; filteredList | Data source for list/table | DataTable: { data: =&gt; filteredCustomers } |
| enabled: =&gt; canSubmit | Enabled/disabled based on signal | Button: { enabled: =&gt; formValid } |

## 9.4 Layout Properties

Layout properties control how a component is arranged within its parent. These map directly to Compose Multiplatform’s layout system at export time.

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `padding` | `Int \| {top,right,bottom,left}` | `0` | Internal padding in dp. Single value or per-side object. |
| `margin` | `Int \| {top,right,bottom,left}` | `0` | External margin in dp. Single value or per-side object. |
| `spacing` | `Int` | `0` | Gap between children in dp (Column/Row only). |
| `alignment` | `String` | `start` | Cross-axis alignment: start, center, end, stretch. |
| `justify` | `String` | `start` | Main-axis alignment: start, center, end, spaceBetween, spaceAround. |
| `flex` | `Int` | `0` | Flex grow factor. 0 means size-to-content. |
| `width` | `Int \| String` | `auto` | Fixed dp, percentage string ("50%"), or auto. |
| `height` | `Int \| String` | `auto` | Fixed dp, percentage string ("50%"), or auto. |
| `minWidth` | `Int` | `none` | Minimum width constraint in dp. |
| `maxWidth` | `Int` | `none` | Maximum width constraint in dp. |
| `scroll` | `String` | `none` | Scroll behavior: none, vertical, horizontal, both. |

## 9.5 Full Screen Example

```
screens:
  customerList:
    title: "Customer Management"
    root: Column
    layout: { padding: 16, spacing: 12 }
    children:
```

```
      # Header bar
      - Row:
          layout: { justify: spaceBetween, alignment: center }
          children:
            - Text:
                value: "Customers"
                style: { variant: headlineMedium }
            - Button:
                text: "Add Customer"
                icon: add
                variant: filled
                onClick: navigateToCreate
```

```
      # Search bar
      - TextField:
          value: => searchQuery
          hint: "Search by name or email..."
          icon: search
          onValueChanged: updateSearch
```

```
      # Status filter chips
      - Row:
          layout: { spacing: 8 }
          children:
            - Chip: { label: "All", selected: => allSelected, onClick: filterAll }
            - Chip: { label: "Active", selected: => activeSelected, onClick: filterActive }
            - Chip: { label: "Pending", selected: => pendingSelected, onClick: filterPending }
```

```
      # Data table
      - DataTable:
          id: customerTable
          data: => filteredCustomers
          columns:
            - { field: name, header: "Name", width: "30%" }
            - { field: email, header: "Email", width: "30%" }
            - { field: status, header: "Status", width: "20%" }
            - { field: createdAt, header: "Created", width: "20%", format: date }
          onRowClick: selectCustomer
          onSort: handleSort
```

```
      # Pagination
      - Pagination:
          total: => totalCustomers
          pageSize: 25
          currentPage: => currentPage
          onPageChange: loadPage
```

# 10. Nested Components & Layout Patterns

Components can be nested to any depth. Layout components (Row, Column, Box, Grid) can contain any other component, including other layouts. This nesting produces the component tree that maps to Compose Multiplatform’s composable hierarchy.

## 10.1 Common Layout Patterns

**Sidebar layout:**

```
- Row:
    layout: { flex: 1 }
    children:
      - Column:
          layout: { width: 280, scroll: vertical }
          style: { background: => surfaceVariant }
          children:
            - NavigationRail: { items: => navItems, selected: => currentScreen }
      - Column:
          layout: { flex: 1, padding: 24 }
          children:
            - ScreenContent: { screen: => currentScreen }
```

**Card grid:**

```
- Grid:
    layout: { columns: 3, spacing: 16 }
    data: => products
    template:
      - Card:
          layout: { padding: 16 }
          children:
            - Image: { src: => item.imageUrl, height: 200 }
            - Text: { value: => item.name, style: { variant: titleMedium } }
            - Text: { value: => item.price, style: { variant: bodyLarge } }
            - Button: { text: "Add to Cart", onClick: addToCart }
```

## 10.2 Conditional Rendering

Components can be conditionally shown or hidden using the visible property bound to a signal:

```
- LoadingSpinner: { visible: => isLoading }
- ErrorBoundary: { visible: => hasError, message: => errorMessage }
- DataTable: { visible: => hasData, data: => customers }
- EmptyState: { visible: => isEmpty, message: "No customers found" }
```

# 11. Component Styling

Components can be styled inline using the style property. Styles reference design tokens from the active theme and can override specific visual properties.

## 11.1 Style Properties

```
- Text:
    value: "Important Notice"
    style:
      variant: titleLarge           # Typography variant from theme
      color: => error               # Token reference
      fontWeight: 700
      textAlign: center
```

```
- Card:
    style:
      background: => surface
      elevation: 2
      shape: medium                 # Shape token: small | medium | large
      border: { width: 1, color: => outline }
    layout: { padding: 16 }
    children:
      - Text: { value: "Card content" }
```

## 11.2 Style Variants

For reusable styles, define named variants in the theme section and reference them by name:

```
theme:
  system: material3
  palette: light-blue
  styles:
    dangerButton:
      background: => error
      color: => onError
      shape: small
    sectionHeader:
      variant: titleMedium
      color: => primary
      fontWeight: 600
```

```
# Usage in screens:
- Button: { text: "Delete", style: dangerButton, onClick: handleDelete }
- Text: { value: "Overview", style: sectionHeader }
```

# 12. Navigation Section

Defines the navigation graph between screens, including transitions, argument passing, and deep linking. The navigation section maps directly to Compose Navigation at export time.

```
navigation:
  startScreen: customerList
  routes:
    customerList:
      path: /customers
      transitions:
        - to: customerDetail
          args: { customerId: Int }
          animation: slideLeft
        - to: customerCreate
          animation: slideUp
```

```
    customerDetail:
      path: /customers/{customerId}
      transitions:
        - to: customerEdit
          args: { customerId: Int }
        - back: customerList
          animation: slideRight
```

```
    customerCreate:
      path: /customers/new
      transitions:
        - back: customerList
          animation: slideDown
```

| **Animation** | **Description** |
|---|---|
| slideLeft | New screen slides in from the right |
| slideRight | New screen slides in from the left (typically for back navigation) |
| slideUp | New screen slides in from the bottom (modal-like) |
| slideDown | New screen slides down (dismissing a modal) |
| fade | Cross-fade transition |
| none | Instant switch with no animation |

# 13. Assets Section

Declares static resources used by the project. Assets are copied to the exported project’s resources directory and referenced by components via their declared names.

```
assets:
  icons:
    set: material-icons-outlined     # Built-in icon set
    custom:
      - { name: logo, path: ./assets/logo.svg }
      - { name: appIcon, path: ./assets/app-icon.png }
```

```
  fonts:
    - { family: Inter, path: ./assets/fonts/Inter.ttf }
    - { family: JetBrainsMono, path: ./assets/fonts/JetBrainsMono.ttf }
```

```
  images:
    - { name: emptyState, path: ./assets/images/empty-state.svg }
    - { name: heroImage, path: ./assets/images/hero.png }
```

# 14. Complete Project Example

The following is a complete, working TabTab project file for a customer management application with live API data, search filtering, and navigation:

```
schema: 1
```

```
project:
  name: customer-manager
  version: 1.0.0
  description: "Customer relationship management tool"
  kotlin: 2.0.0
  compose: 1.6.10
  package: com.example.customers
```

```
theme:
  system: material3
  palette: light-blue
  mode: system
  styles:
    sectionTitle:
      variant: headlineMedium
      fontWeight: 600
```

```
models:
  Customer:
    fields:
      id: Int
      name: String
      email: String
      status: CustomerStatus
  CustomerStatus:
    type: enum
    values: [active, inactive, pending]
```

```
dataSources:
  api:
    type: rest
    baseUrl: https://api.example.com/v1
    auth: { type: bearer, tokenRef: API_KEY }
    endpoints:
      customers: { method: GET, path: /customers, response: List<Customer> }
      customer: { method: GET, path: /customers/{id}, response: Customer }
```

```
signals:
  customers:
    type: List<Customer>
    source: api.customers
    refreshInterval: 30s
  searchQuery:
    type: String
    default: ""
  filteredCustomers:
    type: Computed<List<Customer>>
    derive: "customers.filter { it.name.contains(searchQuery, ignoreCase = true) }"
  selectedCustomerId:
    type: Int?
    default: null
```

```
screens:
  customerList:
    title: "Customers"
    root: Column
    layout: { padding: 16, spacing: 12 }
    children:
      - Row:
          layout: { justify: spaceBetween, alignment: center }
          children:
            - Text: { value: "Customers", style: sectionTitle }
            - Button: { text: "Add", icon: add, variant: filled, onClick: navigateToCreate }
      - TextField:
          value: => searchQuery
          hint: "Search..."
          icon: search
      - DataTable:
          data: => filteredCustomers
          columns:
            - { field: name, header: "Name", width: "40%" }
            - { field: email, header: "Email", width: "35%" }
            - { field: status, header: "Status", width: "25%" }
          onRowClick: selectCustomer
```

```
navigation:
  startScreen: customerList
  routes:
    customerList:
      path: /customers
      transitions:
        - to: customerDetail
          args: { customerId: Int }
          animation: slideLeft
```

# 15. Schema Rules & Validation

The TabTab builder validates project files against these rules on load and on save. Validation errors are displayed inline in the builder with suggested fixes.

## 15.1 Naming Rules

- Project name: lowercase alphanumeric with hyphens. Pattern: [a-z][a-z0-9-]\*
- Signal names: camelCase. Pattern: [a-z][a-zA-Z0-9]\*
- Model names: PascalCase. Pattern: [A-Z][a-zA-Z0-9]\*
- Screen names: camelCase. Pattern: [a-z][a-zA-Z0-9]\*
- Component IDs: camelCase, unique within a screen. Pattern: [a-z][a-zA-Z0-9]\*
- Handler names: camelCase, must reference a function in the handlers/ directory.
## 15.2 Validation Rules

- Every =&gt; binding must reference a signal defined in the signals section.
- Every source reference in a DataSource signal must reference a defined dataSource and endpoint.
- Every handler reference must map to a Kotlin function file in the handlers/ directory.
- Computed derive expressions must reference only defined signal names.
- Navigation routes must reference defined screen names.
- Model types referenced in signals and dataSources must be defined in the models section or be a built-in type.
- Component IDs must be unique within their screen scope.
- The navigation.startScreen must reference a defined screen.
## 15.3 Schema Migration

When the schema version is incremented, TabTab provides automated migration. The builder detects older schema versions on project load and offers to migrate. Migrations are non-destructive — the original file is backed up before any changes.

```
# Old format (schema 1)
schema: 1
```

```
# After migration (schema 2 — hypothetical future version)
schema: 2
# ...migrated content with any structural changes
```
