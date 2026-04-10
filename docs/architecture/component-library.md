**TabTab**

Component Library Specification

Material Design 3 Component Set for v1

Version 1.0 — April 2026

*~30 Components — Prescriptive & Opinionated*

# 1. Overview

This document specifies the component library that ships with TabTab v1. The library provides a curated, prescriptive set of ~30 components built on Material Design 3, covering the most common desktop application UI patterns. Each component has three representations: a visual rendering in the builder (Skia/C++), a YAML schema for the project format, and a code generation template for Compose Multiplatform output.

## 1.1 Design Philosophy

- **Prescriptive over flexible: **Components ship with sensible defaults and pre-configured styles. Developers spend time building, not configuring. Override when needed, not by default.
- **Desktop-first: **Components are designed for desktop interaction patterns — hover states, keyboard navigation, right-click context menus, window resizing. Mobile patterns are deferred.
- **Data-aware: **Every component that displays data supports signal binding via the =&gt; arrow syntax. Components like DataTable and List are first-class citizens, not afterthoughts.
- **Theme-driven: **All visual properties derive from the active design system tokens. Changing the theme changes every component consistently.
- **Composable: **Components nest naturally. Layout components (Row, Column, Box, Grid) can contain any other component. Complex UIs are built by composition, not configuration.
## 1.2 Component Architecture

Every component in the library follows a consistent three-layer architecture:

| **Layer** | **Implementation** | **Role** |
|---|---|---|
| Builder Renderer | C++ / Skia | Renders the component on the design canvas with theme-aware styling, handles design-time interaction (selection, resize, property editing) |
| YAML Schema | .tt.yaml definition | Declares the component’s properties, bindings, events, layout behavior, and default values |
| Code Generator | C++ → Kotlin template | Produces the equivalent Compose Multiplatform composable with signal bindings and event handlers |

## 1.3 Design System Strategy

TabTab v1 ships with Material Design 3 as the sole built-in design system. Microsoft Fluent support will be added in Phase 4 of the roadmap. The component architecture is designed to be design-system-agnostic — each component resolves its visual properties through design tokens, so adding Fluent (or any custom design system) requires only providing new token values, not rewriting components.

| **Version** | **Design System** | **Status** |
|---|---|---|
| v1.0 (Phase 1–4) | Material Design 3 | Built-in, full coverage for all ~30 components |
| v1.x (Phase 4) | Microsoft Fluent | Added as second built-in option |
| v2.0+ | Plugin architecture | Third-party design systems via plugin API |

# 2. Component Catalog

The v1 component library consists of 30 components organized into seven categories. This section provides a complete catalog with the priority tier for each component.

| **Category** | **Components** | **Count** |
|---|---|---|
| Input | Button, IconButton, TextField, TextArea, Checkbox, RadioGroup, Switch, Slider, Dropdown, DatePicker | 10 |
| Display | Text, Image, Icon, Badge, Avatar, ProgressBar, Chip, Divider | 8 |
| Layout | Row, Column, Box, Grid, Spacer, ScrollContainer, Tabs | 7 |
| Data | DataTable, List, Pagination | 3 |
| Navigation | TopAppBar, NavigationRail, Breadcrumb | 3 |
| Feedback | Dialog, Snackbar, Tooltip, LoadingSpinner, EmptyState | 5 |
| Surfaces | Card, Sheet | 2 |

## 2.1 Implementation Priority

Components are implemented in three priority tiers aligned with the development roadmap:

| **Tier** | **Phase** | **Components** |
|---|---|---|
| Tier 1 — Core | Phase 2 (Months 4–6) | Button, TextField, Text, Row, Column, Box, Card, Image, Icon, Checkbox, Switch |
| Tier 2 — Data | Phase 3 (Months 7–9) | DataTable, List, Dropdown, Pagination, TextArea, Slider, TopAppBar, NavigationRail, Dialog, LoadingSpinner, EmptyState |
| Tier 3 — Polish | Phase 4 (Months 10–12) | Grid, Tabs, RadioGroup, DatePicker, IconButton, Badge, Avatar, ProgressBar, Chip, Divider, Breadcrumb, Snackbar, Tooltip, ScrollContainer, Spacer, Sheet |

# 3. Common Component Properties

All components share a set of common properties that control identity, visibility, layout participation, and styling. These are inherited by every component and don’t need to be redeclared in individual component schemas.

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `id` | `String?` | `null` | Optional identifier. Required only when referenced by event handlers or code. |
| `visible` | `Boolean \| Signal` | `true` | Show or hide the component. Supports signal binding for conditional rendering. |
| `enabled` | `Boolean \| Signal` | `true` | Enable or disable interaction. Disabled components are visually muted. |
| `layout` | `LayoutProps` | `{}` | Layout properties: padding, margin, flex, width, height, alignment. |
| `style` | `String \| StyleProps` | `{}` | Named style variant or inline style overrides. |
| `tooltip` | `String?` | `null` | Hover tooltip text. Displayed after a short delay on mouse hover. |
| `testId` | `String?` | `null` | Test identifier for automated testing. Exported as Modifier.testTag(). |

## 3.1 Common Events

| **Event** | **Applies To** | **Description** |
|---|---|---|
| `onClick` | `All interactive` | Triggered when the component is clicked or tapped. |
| `onDoubleClick` | `All interactive` | Triggered on double-click. |
| `onRightClick` | `All interactive` | Triggered on right-click. Used for context menus. |
| `onHover` | `All` | Triggered when the mouse enters the component bounds. |
| `onHoverExit` | `All` | Triggered when the mouse leaves the component bounds. |
| `onFocus` | `All focusable` | Triggered when the component receives keyboard focus. |
| `onBlur` | `All focusable` | Triggered when the component loses keyboard focus. |
| `onKeyPress` | `All focusable` | Triggered on key press. Payload includes the key code and modifiers. |

# 4. Input Components

Input components accept user interaction and write values to mutable signals. They are the primary way users enter data into a TabTab application.

### 4.1 Button

A clickable button that triggers an action. Supports four Material 3 variants and optional leading/trailing icons.

**YAML:**

```
# Basic button
- Button: { text: "Save", onClick: handleSave }
```

```
# Variants
- Button: { text: "Primary", variant: filled, onClick: handlePrimary }
- Button: { text: "Secondary", variant: outlined, onClick: handleSecondary }
- Button: { text: "Subtle", variant: text, onClick: handleSubtle }
- Button: { text: "Elevated", variant: elevated, onClick: handleElevated }
```

```
# With icon
- Button: { text: "Add Customer", icon: add, variant: filled, onClick: handleAdd }
```

```
# Signal-bound enabled state
- Button: { text: "Submit", enabled: => formValid, onClick: handleSubmit }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `text` | `String \| Signal` | "" | Button label text. |
| `variant` | `String` | filled | Visual variant: filled \| outlined \| text \| elevated. |
| `icon` | `String?` | null | Leading icon name from the active icon set. |
| `size` | `String` | medium | Button size: small \| medium \| large. |
| `fullWidth` | `Boolean` | false | Stretch to fill parent width. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onClick` | `()` | Triggered when the button is clicked. |

**Compose export: **Material3 Button, OutlinedButton, TextButton, or ElevatedButton composable.

### 4.2 IconButton

A compact button containing only an icon. Used in toolbars, action rows, and compact UI areas.

**YAML:**

```
- IconButton: { icon: delete, onClick: handleDelete }
- IconButton: { icon: edit, variant: outlined, tooltip: "Edit customer", onClick: handleEdit }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `icon` | `String` | (required) | Icon name from the active icon set. |
| `variant` | `String` | standard | Visual variant: standard \| outlined \| filled \| filledTonal. |
| `size` | `String` | medium | Icon button size: small \| medium \| large. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onClick` | `()` | Triggered when the icon button is clicked. |

**Compose export: **Material3 IconButton composable.

### 4.3 TextField

A single-line text input field. Writes user input to a bound mutable signal. Supports validation, icons, and helper text.

**YAML:**

```
# Basic
- TextField: { value: => searchQuery, hint: "Search..." }
```

```
# With validation and helper text
- TextField:
    id: emailField
    value: => email
    hint: "email@example.com"
    label: "Email Address"
    icon: mail
    helperText: => emailError
    isError: => emailInvalid
    onValueChanged: validateEmail
    onSubmit: handleSubmit
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `Signal<String>` | (required) | Two-way binding to a mutable String signal. |
| `hint` | `String?` | null | Placeholder text shown when empty. |
| `label` | `String?` | null | Floating label above the field. |
| `icon` | `String?` | null | Leading icon. |
| `trailingIcon` | `String?` | null | Trailing icon (e.g., clear button). |
| `helperText` | `String \| Signal?` | null | Helper or error message below the field. |
| `isError` | `Boolean \| Signal` | false | Show error styling. |
| `inputType` | `String` | text | Input type: text \| email \| number \| password \| url. |
| `maxLength` | `Int?` | null | Maximum character count. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onValueChanged` | `(String)` | Fired on every keystroke with the new value. |
| `onSubmit` | `(String)` | Fired when the user presses Enter. |

**Compose export: **Material3 OutlinedTextField composable with Modifier.onKeyEvent for onSubmit.

### 4.4 TextArea

A multi-line text input for longer content. Behaves like TextField but supports multiple lines, auto-grow, and character counting.

**YAML:**

```
- TextArea:
    value: => description
    hint: "Enter a description..."
    minLines: 3
    maxLines: 10
    maxLength: 500
    showCount: true
    onValueChanged: updateDescription
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `Signal<String>` | (required) | Two-way binding to a mutable String signal. |
| `minLines` | `Int` | 3 | Minimum visible lines. |
| `maxLines` | `Int` | 10 | Maximum visible lines before scroll. |
| `maxLength` | `Int?` | null | Maximum character count. |
| `showCount` | `Boolean` | false | Show character count below the field. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onValueChanged` | `(String)` | Fired on every change with the new value. |

**Compose export: **Material3 OutlinedTextField with minLines/maxLines parameters.

### 4.5 Checkbox

A toggle control for boolean values. Can be used standalone or in groups.

**YAML:**

```
- Checkbox: { checked: => agreeToTerms, label: "I agree to the terms" }
- Checkbox: { checked: => darkMode, label: "Dark mode", onChanged: toggleTheme }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `checked` | `Signal<Boolean>` | (required) | Two-way binding to a mutable Boolean signal. |
| `label` | `String?` | null | Text label displayed next to the checkbox. |
| `indeterminate` | `Boolean \| Signal` | false | Show indeterminate (dash) state. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(Boolean)` | Fired when the checked state changes. |

**Compose export: **Material3 Checkbox composable with optional Text label in a Row.

### 4.6 RadioGroup

A group of mutually exclusive options. Binds to a signal representing the selected value.

**YAML:**

```
- RadioGroup:
    selected: => sortOrder
    options:
      - { value: "name", label: "Sort by Name" }
      - { value: "date", label: "Sort by Date" }
      - { value: "status", label: "Sort by Status" }
    orientation: vertical
    onChanged: updateSort
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `selected` | `Signal<String>` | (required) | Two-way binding to the selected option value. |
| `options` | `List<{value, label}>` | (required) | Available options with value and display label. |
| `orientation` | `String` | vertical | Layout direction: vertical \| horizontal. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(String)` | Fired when the selection changes with the new value. |

**Compose export: **Column/Row of Material3 RadioButton composables with shared selectedState.

### 4.7 Switch

A toggle switch for on/off states. Visually distinct from Checkbox — used for settings and preferences.

**YAML:**

```
- Switch: { checked: => notifications, label: "Enable notifications" }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `checked` | `Signal<Boolean>` | (required) | Two-way binding to a mutable Boolean signal. |
| `label` | `String?` | null | Text label displayed next to the switch. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(Boolean)` | Fired when the switch state changes. |

**Compose export: **Material3 Switch composable.

### 4.8 Slider

A continuous or discrete value selector. Used for numeric ranges like volume, price filters, or opacity.

**YAML:**

```
- Slider:
    value: => priceRange
    min: 0
    max: 1000
    step: 10
    label: "Max Price: {priceRange}"
    onChanged: updatePriceFilter
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `Signal<Double>` | (required) | Two-way binding to a mutable numeric signal. |
| `min` | `Double` | 0 | Minimum value. |
| `max` | `Double` | 100 | Maximum value. |
| `step` | `Double?` | null | Discrete step size. Null for continuous. |
| `label` | `String?` | null | Label with optional {signal} interpolation. |
| `showValue` | `Boolean` | true | Show current value tooltip on drag. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(Double)` | Fired continuously during drag with the current value. |
| `onChangeFinished` | `(Double)` | Fired once when the user releases the slider. |

**Compose export: **Material3 Slider composable with optional steps parameter.

### 4.9 Dropdown

A dropdown selector for choosing from a list of options. Supports search filtering for long lists.

**YAML:**

```
# Simple
- Dropdown: { selected: => country, options: => countryList, label: "Country" }
```

```
# Searchable with custom display
- Dropdown:
    selected: => selectedCustomer
    options: => customerList
    displayField: name
    searchable: true
    label: "Customer"
    onChanged: handleCustomerSelect
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `selected` | `Signal<T>` | (required) | Two-way binding to the selected value. |
| `options` | `Signal<List<T>>` | (required) | List of available options. |
| `displayField` | `String?` | null | Field name to display for complex objects. Uses toString() if null. |
| `label` | `String?` | null | Label above the dropdown. |
| `searchable` | `Boolean` | false | Enable type-to-search filtering within the dropdown. |
| `hint` | `String?` | null | Placeholder when nothing is selected. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(T)` | Fired when the selection changes. |

**Compose export: **Material3 ExposedDropdownMenuBox with DropdownMenuItem composables.

### 4.10 DatePicker

A date selection component with calendar popup. Supports date ranges and min/max constraints.

**YAML:**

```
- DatePicker:
    value: => startDate
    label: "Start Date"
    min: "2024-01-01"
    max: "2026-12-31"
    format: "dd/MM/yyyy"
    onChanged: handleDateChange
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `Signal<Date?>` | (required) | Two-way binding to a Date signal. |
| `label` | `String?` | null | Label above the field. |
| `format` | `String` | yyyy-MM-dd | Display format pattern. |
| `min` | `Date?` | null | Earliest selectable date. |
| `max` | `Date?` | null | Latest selectable date. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onChanged` | `(Date?)` | Fired when a date is selected. |

**Compose export: **Material3 DatePicker composable with DatePickerDialog.

# 5. Display Components

Display components render read-only content. They bind to signals for reactive data display but don’t accept direct user input.

### 5.1 Text

Renders text content with theme-aware typography. The most fundamental display component.

**YAML:**

```
# Simple
- Text: { value: "Hello, TabTab!" }
```

```
# Signal-bound with styling
- Text: { value: => customerName, style: { variant: headlineMedium, color: => primary } }
```

```
# With string interpolation
- Text: { value: "Total: {orderCount} orders", style: { variant: bodyLarge } }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `String \| Signal` | (required) | Text content. Supports signal binding and {signal} interpolation. |
| `selectable` | `Boolean` | false | Allow text selection and copy. |
| `maxLines` | `Int?` | null | Maximum lines before truncation with ellipsis. |
| `overflow` | `String` | ellipsis | Overflow behavior: ellipsis \| clip \| visible. |

**Compose export: **Material3 Text composable with MaterialTheme.typography styles.

### 5.2 Image

Displays an image from assets, URLs, or signal-bound sources.

**YAML:**

```
- Image: { src: "logo", width: 120, height: 40 }       # Asset reference
- Image: { src: => product.imageUrl, height: 200, fit: cover }  # URL from signal
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `src` | `String \| Signal` | (required) | Asset name, URL string, or signal-bound URL. |
| `width` | `Int \| String?` | auto | Image width in dp or percentage. |
| `height` | `Int \| String?` | auto | Image height in dp or percentage. |
| `fit` | `String` | contain | Scaling: contain \| cover \| fill \| none. |
| `alt` | `String?` | null | Accessibility description. |
| `placeholder` | `String?` | null | Asset name shown while loading. |

**Compose export: **Compose Image composable with AsyncImage for URLs, painterResource for assets.

### 5.3 Icon

Renders an icon from the active icon set (Material Icons Outlined by default).

**YAML:**

```
- Icon: { name: "search", size: 24, color: => primary }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `name` | `String` | (required) | Icon name from the active icon set. |
| `size` | `Int` | 24 | Icon size in dp. |
| `color` | `String \| Signal?` | null | Icon color. Defaults to theme onSurface. |

**Compose export: **Material3 Icon composable with ImageVector from material-icons-extended.

### 5.4 Badge

A small status indicator, typically overlaid on another component (e.g., notification count on an icon).

**YAML:**

```
- Badge: { count: => unreadCount }
- Badge: { dot: true, visible: => hasNotifications }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `count` | `Int \| Signal?` | null | Numeric badge content. |
| `dot` | `Boolean` | false | Show as a simple dot indicator instead of number. |
| `maxCount` | `Int` | 99 | Maximum displayed count (shows 99+ beyond this). |

**Compose export: **Material3 Badge or BadgedBox composable.

### 5.5 Avatar

A circular or rounded-square image for user/entity representation. Falls back to initials if no image is provided.

**YAML:**

```
- Avatar: { src: => customer.photoUrl, name: => customer.name, size: 40 }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `src` | `String \| Signal?` | null | Image URL. Falls back to initials if null or load fails. |
| `name` | `String \| Signal` | (required) | Full name used for initials fallback and accessibility. |
| `size` | `Int` | 40 | Avatar diameter in dp. |
| `shape` | `String` | circle | Shape: circle \| rounded. |

**Compose export: **Custom composable: Box with clip(CircleShape), AsyncImage, and Text fallback.

### 5.6 ProgressBar

A linear or circular progress indicator for showing completion or indeterminate loading.

**YAML:**

```
- ProgressBar: { value: => uploadProgress, max: 100 }
- ProgressBar: { indeterminate: true }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `value` | `Double \| Signal?` | null | Current progress value. |
| `max` | `Double` | 100 | Maximum progress value. |
| `indeterminate` | `Boolean` | false | Show indeterminate animation instead of specific progress. |
| `variant` | `String` | linear | Visual variant: linear \| circular. |

**Compose export: **Material3 LinearProgressIndicator or CircularProgressIndicator.

### 5.7 Chip

A compact element for filters, tags, or selections. Supports selectable and dismissible modes.

**YAML:**

```
- Chip: { label: "Active", selected: => activeFilter, onClick: toggleActive }
- Chip: { label: => tag.name, dismissible: true, onDismiss: removeTag }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `label` | `String \| Signal` | (required) | Chip text content. |
| `selected` | `Boolean \| Signal` | false | Selected state for filter chips. |
| `icon` | `String?` | null | Leading icon. |
| `dismissible` | `Boolean` | false | Show dismiss (X) button. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onClick` | `()` | Triggered when the chip is clicked. |
| `onDismiss` | `()` | Triggered when the dismiss button is clicked. |

**Compose export: **Material3 FilterChip, InputChip, or AssistChip composable.

### 5.8 Divider

A thin horizontal or vertical line for visual separation.

**YAML:**

```
- Divider: {}
- Divider: { orientation: vertical, thickness: 2, color: => outlineVariant }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `orientation` | `String` | horizontal | Direction: horizontal \| vertical. |
| `thickness` | `Int` | 1 | Line thickness in dp. |
| `color` | `String \| Signal?` | null | Line color. Defaults to theme outlineVariant. |
| `indent` | `Int` | 0 | Inset from start edge in dp. |

**Compose export: **Material3 Divider or VerticalDivider composable.

# 6. Layout Components

Layout components arrange child components spatially. They don’t render visible content themselves but control positioning, spacing, and responsiveness. These map directly to Compose Multiplatform’s layout primitives.

### 6.1 Row

Arranges children horizontally in a flex row. The primary horizontal layout container.

**YAML:**

```
- Row:
    layout: { spacing: 8, alignment: center, justify: spaceBetween }
    children:
      - Text: { value: "Title" }
      - Button: { text: "Action", onClick: handleAction }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `spacing` | `Int` | 0 | Gap between children in dp. |
| `alignment` | `String` | start | Cross-axis (vertical): start \| center \| end \| stretch. |
| `justify` | `String` | start | Main-axis (horizontal): start \| center \| end \| spaceBetween \| spaceAround \| spaceEvenly. |
| `wrap` | `Boolean` | false | Wrap children to next line when they overflow. |

**Compose export: **Compose Row composable with Arrangement and Alignment parameters.

### 6.2 Column

Arranges children vertically in a flex column. The primary vertical layout container and the default root layout for screens.

**YAML:**

```
- Column:
    layout: { spacing: 12, padding: 16 }
    children:
      - Text: { value: "Section Title", style: { variant: titleLarge } }
      - Text: { value: "Section content goes here." }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `spacing` | `Int` | 0 | Gap between children in dp. |
| `alignment` | `String` | start | Cross-axis (horizontal): start \| center \| end \| stretch. |
| `justify` | `String` | start | Main-axis (vertical): start \| center \| end \| spaceBetween \| spaceAround. |

**Compose export: **Compose Column composable with Arrangement and Alignment parameters.

### 6.3 Box

A stacking container where children overlap. Used for overlays, badges, floating action buttons, and layered compositions.

**YAML:**

```
- Box:
    layout: { width: 200, height: 200 }
    children:
      - Image: { src: => photo, fit: cover }
      - Badge: { count: => unread, style: { alignment: topEnd } }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `contentAlignment` | `String` | topStart | Default alignment for children: topStart \| topCenter \| topEnd \| centerStart \| center \| centerEnd \| bottomStart \| bottomCenter \| bottomEnd. |

**Compose export: **Compose Box composable with contentAlignment parameter.

### 6.4 Grid

A grid layout that arranges children in rows and columns. Supports both fixed column counts and responsive breakpoints.

**YAML:**

```
- Grid:
    layout: { columns: 3, spacing: 16 }
    data: => products
    template:
      - Card:
          children:
            - Image: { src: => item.image, height: 150 }
            - Text: { value: => item.name }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `columns` | `Int` | 2 | Number of columns. |
| `spacing` | `Int` | 0 | Gap between grid cells in dp. |
| `data` | `Signal<List<T>>?` | null | Data source for repeated template rendering. |

**Compose export: **Compose LazyVerticalGrid composable with GridCells.Fixed.

### 6.5 Spacer

An invisible component that occupies space. Used to push siblings apart or add fixed gaps in layouts.

**YAML:**

```
- Spacer: { height: 24 }
- Spacer: { flex: 1 }    # Fills remaining space
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `width` | `Int?` | null | Fixed width in dp. |
| `height` | `Int?` | null | Fixed height in dp. |
| `flex` | `Int?` | null | Flex grow factor. Fills available space proportionally. |

**Compose export: **Compose Spacer composable with Modifier.size or Modifier.weight.

### 6.6 ScrollContainer

Wraps content in a scrollable area. Used when content may exceed the available space.

**YAML:**

```
- ScrollContainer:
    scroll: vertical
    layout: { maxHeight: 400 }
    children:
      - ...content that may overflow
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `scroll` | `String` | vertical | Scroll direction: vertical \| horizontal \| both. |
| `showScrollbar` | `String` | auto | Scrollbar visibility: auto \| always \| never. |

**Compose export: **Compose Modifier.verticalScroll or Modifier.horizontalScroll with rememberScrollState.

### 6.7 Tabs

A tabbed container that shows one panel at a time based on the selected tab.

**YAML:**

```
- Tabs:
    selected: => activeTab
    tabs:
      - { label: "Overview", icon: dashboard }
      - { label: "Details", icon: info }
      - { label: "History", icon: history }
    panels:
      - Column: { children: [...overview content] }
      - Column: { children: [...details content] }
      - Column: { children: [...history content] }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `selected` | `Signal<Int>` | (required) | Two-way binding to the active tab index. |
| `tabs` | `List<{label, icon?}>` | (required) | Tab definitions with labels and optional icons. |
| `panels` | `List<Component>` | (required) | Content panels corresponding to each tab. |
| `variant` | `String` | primary | Tab style: primary \| secondary. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onTabChanged` | `(Int)` | Fired when the active tab changes. |

**Compose export: **Material3 TabRow with Tab composables and indexed content panels.

# 7. Data Components

Data components are purpose-built for displaying collections of data. They are the primary consumers of DataSource signals and support sorting, filtering, selection, and pagination.

### 7.1 DataTable

A full-featured data table with sortable columns, row selection, and configurable column formatting. The most important data display component in TabTab.

**YAML:**

```
- DataTable:
    id: customerTable
    data: => filteredCustomers
    columns:
      - { field: name, header: "Name", width: "30%", sortable: true }
      - { field: email, header: "Email", width: "30%" }
      - { field: status, header: "Status", width: "20%", format: chip }
      - { field: createdAt, header: "Created", width: "20%", format: date }
    selectable: single
    striped: true
    onRowClick: selectCustomer
    onSort: handleSort
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `data` | `Signal<List<T>>` | (required) | Signal-bound list of data objects to display. |
| `columns` | `List<ColumnDef>` | (required) | Column definitions with field, header, width, format, sortable. |
| `selectable` | `String` | none | Row selection: none \| single \| multiple. |
| `striped` | `Boolean` | false | Alternate row background colors. |
| `stickyHeader` | `Boolean` | true | Keep header row visible when scrolling. |
| `emptyMessage` | `String` | "No data" | Message shown when data list is empty. |
| `rowHeight` | `Int` | 48 | Row height in dp. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onRowClick` | `(T)` | Fired when a row is clicked. Payload is the data object. |
| `onRowSelect` | `(List<T>)` | Fired when selection changes. Payload is selected items. |
| `onSort` | `(String, Boolean)` | Fired when a column header is clicked. Payload: column field and ascending flag. |

**Compose export: **Custom composable using LazyColumn with Row-based headers and cells, Modifier.clickable for selection.

### 7.2 List

A vertical list of items rendered from a data signal. More flexible than DataTable — each item is rendered using a customizable template.

**YAML:**

```
- List:
    data: => customers
    template:
      - Row:
          layout: { spacing: 12, alignment: center, padding: 8 }
          children:
            - Avatar: { name: => item.name, size: 36 }
            - Column:
                children:
                  - Text: { value: => item.name, style: { variant: bodyLarge } }
                  - Text: { value: => item.email, style: { variant: bodySmall, color: => onSurfaceVariant } }
    divider: true
    onItemClick: selectCustomer
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `data` | `Signal<List<T>>` | (required) | Signal-bound list of data objects. |
| `template` | `List<Component>` | (required) | Component tree template for each item. Use =&gt; item.field for data access. |
| `divider` | `Boolean` | false | Show dividers between items. |
| `emptyMessage` | `String` | "No items" | Message shown when list is empty. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onItemClick` | `(T)` | Fired when an item is clicked. |

**Compose export: **Compose LazyColumn with items() and the template rendered per item.

### 7.3 Pagination

A pagination control for navigating paged data. Typically paired with DataTable or List.

**YAML:**

```
- Pagination:
    total: => totalCustomers
    pageSize: 25
    currentPage: => currentPage
    onPageChange: loadPage
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `total` | `Int \| Signal` | (required) | Total number of items across all pages. |
| `pageSize` | `Int` | 25 | Items per page. |
| `currentPage` | `Signal<Int>` | (required) | Two-way binding to current page number. |
| `showFirstLast` | `Boolean` | true | Show first/last page buttons. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onPageChange` | `(Int)` | Fired when the page changes. Payload is the new page number. |

**Compose export: **Custom composable: Row of IconButtons with page number Text elements.

# 8. Navigation Components

Navigation components provide application-level navigation structure — app bars, side rails, and breadcrumb trails.

### 8.1 TopAppBar

A top-level application bar with title, navigation icon, and action buttons. The standard header for desktop applications.

**YAML:**

```
- TopAppBar:
    title: => currentScreenTitle
    navigationIcon: menu
    onNavigationClick: toggleDrawer
    actions:
      - { icon: search, onClick: openSearch }
      - { icon: settings, onClick: openSettings }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `title` | `String \| Signal` | (required) | App bar title text. |
| `navigationIcon` | `String?` | null | Leading icon (typically menu or back arrow). |
| `actions` | `List<{icon, onClick}>` | [] | Trailing action buttons. |
| `variant` | `String` | small | App bar size: small \| medium \| large. |
| `scrollBehavior` | `String` | pinned | Scroll response: pinned \| enterAlways \| exitUntilCollapsed. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onNavigationClick` | `()` | Fired when the navigation icon is clicked. |

**Compose export: **Material3 TopAppBar, MediumTopAppBar, or LargeTopAppBar composable.

### 8.2 NavigationRail

A vertical navigation bar for the left edge of the application. The primary navigation pattern for desktop apps.

**YAML:**

```
- NavigationRail:
    selected: => currentScreen
    items:
      - { icon: dashboard, label: "Dashboard", value: "dashboard" }
      - { icon: people, label: "Customers", value: "customers" }
      - { icon: inventory, label: "Products", value: "products" }
      - { icon: analytics, label: "Reports", value: "reports" }
    onItemSelected: navigateToScreen
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `selected` | `Signal<String>` | (required) | Currently selected item value. |
| `items` | `List<{icon, label, value}>` | (required) | Navigation items with icon, label, and route value. |
| `header` | `Component?` | null | Optional header component (e.g., logo or FAB). |
| `showLabels` | `String` | always | Label visibility: always \| selected \| never. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onItemSelected` | `(String)` | Fired when a navigation item is selected. |

**Compose export: **Material3 NavigationRail composable with NavigationRailItem.

### 8.3 Breadcrumb

A horizontal breadcrumb trail showing the current navigation path. Useful for hierarchical navigation.

**YAML:**

```
- Breadcrumb:
    items: => navigationPath
    onItemClick: navigateToLevel
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `items` | `Signal<List<{label, value}>>` | (required) | Ordered breadcrumb items from root to current. |
| `separator` | `String` | / | Separator character between items. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onItemClick` | `(String)` | Fired when a breadcrumb item is clicked. Payload is the item value. |

**Compose export: **Custom composable: Row of TextButton with separator Text elements.

# 9. Feedback Components

Feedback components communicate application state to the user — loading indicators, empty states, errors, confirmations, and contextual information.

### 9.1 Dialog

A modal dialog that overlays the application content. Used for confirmations, forms, and critical information.

**YAML:**

```
- Dialog:
    visible: => showDeleteConfirm
    title: "Delete Customer"
    content: "Are you sure? This action cannot be undone."
    confirmText: "Delete"
    confirmVariant: error
    cancelText: "Cancel"
    onConfirm: deleteCustomer
    onCancel: closeDialog
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `visible` | `Signal<Boolean>` | (required) | Controls dialog visibility via signal binding. |
| `title` | `String?` | null | Dialog title. |
| `content` | `String \| Component` | (required) | Dialog body — text string or component tree. |
| `confirmText` | `String` | "OK" | Confirm button text. |
| `confirmVariant` | `String` | primary | Confirm button color: primary \| error. |
| `cancelText` | `String?` | "Cancel" | Cancel button text. Null to hide cancel button. |
| `dismissible` | `Boolean` | true | Allow dismissing by clicking outside or pressing Escape. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onConfirm` | `()` | Fired when the confirm button is clicked. |
| `onCancel` | `()` | Fired when the cancel button is clicked or dialog is dismissed. |

**Compose export: **Material3 AlertDialog composable.

### 9.2 Snackbar

A brief message shown at the bottom of the screen. Used for non-critical notifications and action confirmations.

**YAML:**

```
- Snackbar:
    message: => snackbarMessage
    visible: => showSnackbar
    action: "Undo"
    onAction: undoDelete
    duration: 4s
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `message` | `String \| Signal` | (required) | Snackbar message text. |
| `visible` | `Signal<Boolean>` | (required) | Controls visibility. |
| `action` | `String?` | null | Optional action button text. |
| `duration` | `Duration` | 4s | Auto-dismiss duration: 2s \| 4s \| 10s \| indefinite. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onAction` | `()` | Fired when the action button is clicked. |
| `onDismiss` | `()` | Fired when the snackbar is dismissed. |

**Compose export: **Material3 Snackbar with SnackbarHost composable.

### 9.3 Tooltip

A contextual popup that appears on hover. Provides additional information about a component.

**YAML:**

```
- Button: { text: "Export", tooltip: "Export data as CSV", onClick: handleExport }
```

```
# Rich tooltip with custom content
- Tooltip:
    target: exportBtn
    content:
      - Column:
          children:
            - Text: { value: "Export Options", style: { variant: labelLarge } }
            - Text: { value: "Click to export as CSV. Hold Shift for PDF." }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `target` | `String?` | null | Component ID to attach the tooltip to. For rich tooltips. |
| `content` | `String \| Component` | (required) | Tooltip content — text or component tree. |
| `position` | `String` | bottom | Tooltip position: top \| bottom \| start \| end. |
| `delay` | `Duration` | 500ms | Hover delay before showing tooltip. |

**Compose export: **Material3 TooltipBox with PlainTooltip or RichTooltip composable.

### 9.4 LoadingSpinner

An indeterminate loading indicator shown while data is being fetched. Typically bound to a Resource signal’s loading state.

**YAML:**

```
- LoadingSpinner: { visible: => customers.isLoading }
- LoadingSpinner: { visible: => isSubmitting, size: small, label: "Saving..." }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `size` | `String` | medium | Spinner size: small \| medium \| large. |
| `label` | `String?` | null | Text shown below the spinner. |
| `overlay` | `Boolean` | false | Show as a semi-transparent overlay on the parent. |

**Compose export: **Material3 CircularProgressIndicator with optional Text label.

### 9.5 EmptyState

A placeholder shown when a data collection is empty. Provides visual feedback and an optional call-to-action.

**YAML:**

```
- EmptyState:
    visible: => isEmpty
    icon: inbox
    title: "No customers yet"
    description: "Add your first customer to get started."
    actionText: "Add Customer"
    onAction: navigateToCreate
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `icon` | `String?` | null | Large icon shown above the title. |
| `title` | `String` | (required) | Primary empty state message. |
| `description` | `String?` | null | Secondary descriptive text. |
| `actionText` | `String?` | null | Call-to-action button text. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onAction` | `()` | Fired when the action button is clicked. |

**Compose export: **Custom composable: Column with Icon, Text elements, and optional Button.

# 10. Surface Components

Surface components provide elevated or bordered containers that group related content visually.

### 10.1 Card

An elevated container for grouping related content. The primary surface component for content cards, list items, and information panels.

**YAML:**

```
- Card:
    variant: elevated
    layout: { padding: 16 }
    onClick: selectItem
    children:
      - Text: { value: => item.title, style: { variant: titleMedium } }
      - Text: { value: => item.description, style: { variant: bodyMedium } }
      - Row:
          layout: { justify: end, spacing: 8 }
          children:
            - Button: { text: "Cancel", variant: text, onClick: handleCancel }
            - Button: { text: "Save", variant: filled, onClick: handleSave }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `variant` | `String` | elevated | Card style: elevated \| filled \| outlined. |
| `elevation` | `Int?` | null | Custom elevation override in dp. |
| `clickable` | `Boolean` | false | Show hover/press feedback and enable onClick. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onClick` | `()` | Fired when the card is clicked (only if clickable is true). |

**Compose export: **Material3 Card, ElevatedCard, or OutlinedCard composable.

### 10.2 Sheet

A slide-in panel from the edge of the screen. Used for secondary content, filters, or detail views.

**YAML:**

```
- Sheet:
    visible: => showFilters
    side: end
    width: 320
    children:
      - Text: { value: "Filters", style: { variant: titleLarge } }
      - Dropdown: { selected: => statusFilter, options: => statusOptions, label: "Status" }
      - Button: { text: "Apply", variant: filled, onClick: applyFilters }
```

**Properties:**

| **Property** | **Type** | **Default** | **Description** |
|---|---|---|---|
| `visible` | `Signal<Boolean>` | (required) | Controls sheet visibility. |
| `side` | `String` | end | Which edge the sheet slides from: start \| end \| bottom. |
| `width` | `Int` | 320 | Sheet width in dp (for start/end) or height (for bottom). |
| `modal` | `Boolean` | true | Show scrim overlay and block interaction with background. |

**Events:**

| **Event** | **Payload** | **Description** |
|---|---|---|
| `onDismiss` | `()` | Fired when the sheet is dismissed. |

**Compose export: **Material3 ModalDrawerSheet or custom AnimatedVisibility panel.

# 11. DataTable Column Formats

DataTable columns support a format property that controls how values are rendered. Built-in formats handle the most common data display patterns.

| **Format** | **Description** | **Example Output** |
|---|---|---|
| text (default) | Plain text rendering | "John Smith" |
| number | Locale-formatted number | "1,234.56" |
| currency | Currency with locale symbol | "$1,234.56" |
| date | Formatted date string | "Apr 10, 2026" |
| datetime | Formatted date and time | "Apr 10, 2026 2:30 PM" |
| boolean | Checkmark or X icon | ✓ or ✗ |
| chip | Colored chip based on value (maps enum values to colors) | Active (green chip) |
| avatar | Avatar image + text in a row | [avatar] John Smith |
| link | Clickable link styled text | john@example.com (underlined) |
| progress | Inline progress bar | [========  ] 80% |
| custom | Developer-defined template | Any component tree via template property |

**Custom column template:**

```
columns:
  - field: status
    header: "Status"
    format: custom
    template:
      - Chip:
          label: => item.status
          style: => statusStyle(item.status)
```

# 12. Future: Fluent Design System & Plugin Architecture

## 12.1 Microsoft Fluent (Phase 4)

All 30 components will receive Fluent design system variants in Phase 4. The Fluent implementation provides the same YAML API — only the visual rendering changes. Developers switch between Material 3 and Fluent by changing a single line in the theme section:

```
theme:
  system: fluent    # Switch from material3 to fluent
  palette: blue     # Fluent accent color
  mode: system
```

Key visual differences between Material 3 and Fluent:

- Elevation: Material uses tonal surface elevation; Fluent uses shadow-based depth.
- Shape: Material has a rounded corner scale; Fluent uses a subtler corner radius system.
- Typography: Material uses its own type scale; Fluent uses the Segoe-based type ramp.
- Motion: Material uses spring-based easing; Fluent uses its own curve definitions.
- Color: Material uses dynamic color roles; Fluent uses an accent color system.
## 12.2 Plugin Architecture (v2.0+)

In v2, third-party components will be supported via a plugin system. A component plugin consists of three files:

- **component.yaml: **Schema definition with properties, events, and default values.
- **renderer.cpp: **Skia-based builder renderer for design-time preview (compiled as a shared library).
- **template.kt: **Kotlin/Compose code generation template.
The plugin system is deferred from v1 to keep the initial scope manageable. The component architecture is designed with extensibility in mind — all 30 built-in components follow the same three-file pattern internally, so the plugin system is a natural extension of the existing architecture.
