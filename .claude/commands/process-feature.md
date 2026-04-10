---
description: Generate an implementation plan and per-platform handover documents for a planned feature.
argument-hint: "feature=<name>"
---

# /process-feature

You are turning a planned feature into concrete implementation handovers. Your job is
to **read**, **plan**, and **write handover docs** — not to implement.

## Inputs

Arguments: **$ARGUMENTS** (expects `feature=<name>`)

## Hard constraints

- You **MAY NOT** decompose the feature further or invent new stories (that's `/plan-feature`).
- You **MAY NOT** write source code (that's `/implement-story`).
- You **MAY NOT** skip reading the architecture docs.
- You **MUST** create a handover document for **every** platform the feature touches.

## Process

### 1. Load the feature spec

Read `docs/specs/features/{feature-name}/spec.md`. If it doesn't exist, stop and
tell the user to run `/plan-feature` first.

Extract: story list, platforms involved, phase, dependencies.

### 2. Load architecture context

Read in parallel (only the docs relevant to the affected platforms):
- `docs/architecture/architecture.md` — always
- `docs/architecture/yaml-schema.md` — if feature touches YAML or codegen
- `docs/architecture/signal-system.md` — if feature touches signals
- `docs/architecture/component-library.md` — if feature adds/changes components
- `docs/architecture/code-generation.md` — if feature touches codegen or output
- `docs/standards/coding-standards.md` — always
- `docs/standards/tdd-guidelines.md` — always

### 3. Determine implementation order

Standard order unless spec says otherwise:

1. **infra** (CI, build config, tooling — must land first so downstream can use it)
2. **builder core** (data structures, parsing, signal graph)
3. **codegen** (maps builder state to Kotlin)
4. **output** (runtime templates and generated project changes)

Cross-platform dependencies may override this — call them out.

### 4. Write the implementation plan

Write `docs/specs/features/{feature-name}/implementation-plan.md`:

```markdown
---
feature: {name}
created: {YYYY-MM-DD}
status: ready
---

# Implementation Plan: {Feature Title}

## Order
1. {platform} — stories {list}
2. ...

## Rationale
{Why this order}

## Critical path
{Which stories block which}

## Risks
- ...

## Handover documents
- [Builder handover](./builder-handover.md)
- [Codegen handover](./codegen-handover.md)
- ...
```

### 5. Write per-platform handovers

For **each** platform the feature touches, write
`docs/specs/features/{feature-name}/{platform}-handover.md` using the template
at `docs/specs/templates/handover.md`. Fill in every section:

- **Context** — distilled from the architecture docs. What does an agent with zero
  prior context need to know to start this work? Include key class names, file paths,
  and data-flow diagrams if helpful. No more than ~300 words.
- **Tasks** — one row per story, linked to its ID, with a 1-line task description.
- **Files to create/modify** — concrete paths. New files get a purpose. Modified
  files get a 1-line "what changes" note.
- **TDD test plan** — specific test cases per the TDD guidelines. Name each test
  `test_<unit>_<scenario>_<expected>`.
- **Acceptance criteria** — copied verbatim from the GitHub issue.
- **Definition of done** — from the template.

### 6. Update GitHub issues

For each story issue:

```bash
gh issue comment {number} --body "Handover ready: docs/specs/features/{name}/{platform}-handover.md"
gh issue edit {number} --add-label "status:ready" --remove-label "status:new"
```

### 7. Summary

Report:
- Implementation plan path
- List of handover files created
- Which story to start with (typically the first in the critical path)
- Suggested next command: `/implement-story story=<first-ID>`
