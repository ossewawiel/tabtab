---
description: Decompose a feature description into platform stories and create GitHub issues with milestones.
argument-hint: "<feature description>"
---

# /plan-feature

You are planning a new TabTab feature. Your job is to **decompose**, **propose**, and
(after approval) **record** — not to implement.

## Inputs

The user's feature description appears as: **$ARGUMENTS**

## Hard constraints

- You **MAY NOT** create handover documents. That belongs to `/process-feature`.
- You **MAY NOT** write any source code.
- You **MAY NOT** overwrite existing stories or feature specs.
- You **MUST** present the decomposition and **wait for explicit approval** before
  creating anything in the repo or on GitHub.

## Process

### 1. Load context

Read in parallel:
- `CLAUDE.md` (project overview, signal model, platform prefixes)
- `docs/specs/requirements/builder.md`
- `docs/specs/requirements/codegen.md`
- `docs/specs/requirements/output.md`
- `docs/specs/requirements/infra.md`

From the requirement files, determine the **next available story ID** per platform
(e.g. if `builder.md` has stories up to BLD-014, the next is BLD-015).

### 2. Analyse the feature

Extract:
- **Affected platforms** — builder / codegen / output / infra (any combination)
- **Capabilities** — what the user will be able to do when this ships
- **Data involved** — new signals, models, data sources
- **Dependencies** — stories or features that must land first

### 3. Decompose into atomic stories

Rules:
- One story = one platform. Never cross platforms inside a story.
- Each story must be independently testable.
- Prefer vertical slices where possible (e.g. "render button + click event")
  over horizontal layers ("add all events framework").
- Every story needs a 1-line title, 2-3 sentence description, and acceptance criteria.
- Assign IDs using the next available number per platform prefix (BLD/GEN/OUT/INF).

### 4. Determine phase and milestone

Map the feature to one of the 5 roadmap phases:

1. **Phase 1: Foundation** — C++ app, Skia, basic widgets, layout, YAML parser
2. **Phase 2: Designer Core** — Drag-drop, property editing, Material 3, theming
3. **Phase 3: Data & Signals** — Signal graph, REST/SQL, live data preview
4. **Phase 4: Code Gen & Export** — Kotlin generator, Gradle scaffold, quick-run, Fluent
5. **Phase 5: Polish & Community** — Plugin API, navigation editor, undo/redo, docs

### 5. Present for approval

Show the user:
- Feature name (kebab-case, derived from description)
- Target phase and GitHub milestone
- Full story list, grouped by platform
- Acceptance criteria per story
- Dependency notes

**Stop and ask:** *"Approve this plan? Reply `yes` to create spec files and GitHub issues, or tell me what to change."*

### 6. On approval — record everything

Only after explicit `yes`:

**a. Create the feature spec**

Write `docs/specs/features/{feature-name}/spec.md`:

```markdown
---
feature: {feature-name}
phase: {1-5}
status: planned
created: {YYYY-MM-DD}
stories: [{IDs}]
---

# {Feature Title}

## Summary
{2-3 sentences}

## Motivation
{Why this matters}

## Stories
| ID | Platform | Title | Status |
|---|---|---|---|
| BLD-xxx | builder | ... | planned |

## Acceptance criteria
- [ ] ...

## Dependencies
- ...
```

**b. Append stories to requirement files**

For each story, append an entry to the appropriate
`docs/specs/requirements/{platform}.md`:

```markdown
### {ID} — {Title}
**Feature:** {feature-name}
**Phase:** {n}
**Status:** 📋 Planned

{Description}

**Acceptance criteria:**
- [ ] ...
```

**c. GitHub**

If the GitHub milestone for the phase doesn't exist yet, create it:
```bash
gh api repos/:owner/:repo/milestones -f title="Phase N: ..." -f description="..."
```

For each story, create a GitHub issue:
```bash
gh issue create \
  --title "[{ID}] {Title}" \
  --body-file /tmp/story-body.md \
  --label "type:feature,comp:{platform},status:new,source:ai-agent,phase-N" \
  --milestone "Phase N: ..."
```

**d. Summary**

Report:
- Spec file path
- Number of stories created (per platform)
- GitHub milestone URL
- List of issue URLs
- Suggested next command: `/process-feature feature={feature-name}`

## Labels reference

- Type: `type:feature`, `type:bug`, `type:improvement`, `type:maintenance`, `type:docs`
- Component: `comp:builder`, `comp:codegen`, `comp:output`, `comp:infra`, `comp:docs`
- Status: `status:new`, `status:investigating`, `status:ready`, `status:in-progress`, `status:review`, `status:done`
- Priority: `prior:critical`, `prior:high`, `prior:medium`, `prior:low`
- Phase: `phase-1` through `phase-5`
- Source: `source:ai-agent`, `source:community`, `source:maintainer`
