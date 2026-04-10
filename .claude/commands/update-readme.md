---
description: Regenerate README.md from the current project state (phase progress, features, examples).
---

# /update-readme

You are regenerating `README.md` to reflect the current state of the project.
This is a **derivative** file — nothing authoritative lives here. The sources of
truth are `CLAUDE.md`, `docs/specs/requirements/*.md`, and the GitHub milestones.

## Hard constraints

- You **MAY NOT** invent features or progress. Only report what the source files show.
- You **MAY NOT** change the project's goals, tech stack, or philosophy sections —
  those come from `CLAUDE.md`.
- You **MAY NOT** remove existing badges or external links without the user asking.

## Process

### 1. Load sources

- `CLAUDE.md` — project overview, tech stack
- `docs/specs/requirements/builder.md`
- `docs/specs/requirements/codegen.md`
- `docs/specs/requirements/output.md`
- `docs/specs/requirements/infra.md`
- `examples/` directory listing
- Current git tag: `git describe --tags --abbrev=0 2>/dev/null`
- Milestone progress: `gh api repos/:owner/:repo/milestones --jq '.[] | {title, state, open_issues, closed_issues}'`

### 2. Compute phase progress

For each of the 5 phases, count done / total stories from the requirements files.
Produce a progress table:

```markdown
| Phase | Progress | Status |
|---|---|---|
| Phase 1: Foundation | 12/18 | 🔄 In progress |
| Phase 2: Designer Core | 0/15 | 📋 Planned |
| ... |
```

### 3. Build the new README

Sections (in order):

1. **Title + tagline** (preserved from current README)
2. **Status badge** — reflect the current version and active phase
3. **What is TabTab?** (preserved from current README)
4. **Why it exists** (preserved)
5. **Architecture at a glance** — pull from CLAUDE.md's tech stack table
6. **Phase progress** — the table from step 2
7. **Repository layout** — reference `CLAUDE.md` for the full tree
8. **Getting started** — build commands
9. **Examples** — list each directory in `examples/` with a 1-line description
   from its `project.tt.yaml`'s `project.name` or a comment header
10. **Development workflow** — the slash command flow
11. **License** — MIT

### 4. Diff review

Show the user a diff between the current README and the proposed one. Ask:
**"Apply this update? (yes / edit / cancel)"**

### 5. Write and report

On approval, write the new README and report the changes.
