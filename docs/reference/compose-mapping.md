# TabTab → Compose Widget Mapping

> Stub — the authoritative mapping lives in
> `docs/architecture/component-library.md`. This file will become a
> quick-reference table once the component library stabilises.

## Purpose

Each TabTab component in the component library compiles down to a specific
Compose Multiplatform composable (or composition of composables) in the
generated output. This document lists those mappings for quick lookup.

## Mapping table (placeholder)

| TabTab component | Compose target | Notes |
|---|---|---|
| `Text` | `androidx.compose.material3.Text` | Variant maps to Typography |
| `Button` | `Button` / `OutlinedButton` / `TextButton` | `variant` selects |
| `Column` | `androidx.compose.foundation.layout.Column` | |
| `Row` | `Row` | |
| `TextField` | `OutlinedTextField` | |
| _(more to come)_ | | |

See `docs/architecture/component-library.md` for the full list with all 30 components.
