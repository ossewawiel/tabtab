---
description: Investigate an externally-created GitHub issue, diagnose root cause, and produce handover documents.
argument-hint: "issue=<number>"
---

# /process-issue

You are triaging an externally-created GitHub issue. Your job is to **investigate**,
**diagnose**, and **produce handover documents** — not to implement.

## Inputs

Arguments: **$ARGUMENTS** (expects `issue=<number>`)

## Hard constraints

- You **MAY NOT** fix the issue directly. Always go through handovers → `/implement-story`.
- You **MAY NOT** skip the investigation doc, even for trivial issues.
- You **MAY NOT** close the issue — it remains open until its implementation story closes.

## Process

### 1. Fetch the issue

```bash
gh issue view {number} --json number,title,body,labels,author,createdAt,comments
```

### 2. Classify

Pick one:
- `type:bug` — something broken
- `type:feature` — new capability
- `type:improvement` — refine existing capability
- `type:maintenance` — refactor, dep update, cleanup
- `type:docs` — documentation only

Pick affected platforms: `comp:builder` / `comp:codegen` / `comp:output` / `comp:infra` / `comp:docs`.

### 3. Update status

```bash
gh issue edit {number} \
  --add-label "status:investigating,type:{type},comp:{comp}" \
  --remove-label "status:new"
```

### 4. Investigate

Based on the classification:

- **Bug:** reproduce mentally from the description, read the relevant code, trace
  data flow, identify the root cause and the specific code that must change.
- **Feature/improvement:** map to the architecture docs, identify which components
  must change and whether new stories are needed.
- **Docs:** identify the file(s) that need updating and what's wrong.
- **Maintenance:** identify the scope and impact.

### 5. Write the investigation document

Write `docs/specs/features/issue-{number}/investigation.md` using the template at
`docs/specs/templates/investigation.md`. Fill in every section honestly — if you
don't know the root cause, say so and list what you ruled out.

### 6. Create handovers

- **Single-platform issue:** write one handover document
  `docs/specs/features/issue-{number}/{platform}-handover.md`
  with a single story. Assign a new story ID from the next available number.

- **Multi-platform issue:** write an `implementation-plan.md` plus per-platform
  handover docs, exactly as `/process-feature` would.

Every handover must follow `docs/specs/templates/handover.md`.

### 7. Link back to the issue

```bash
gh issue comment {number} --body "$(cat <<'EOF'
Investigation complete.

**Root cause:** {1-line summary}

**Investigation:** docs/specs/features/issue-{number}/investigation.md

**Handover(s):**
- docs/specs/features/issue-{number}/{platform}-handover.md

**Stories created:** {list of IDs}

**Next step:** `/implement-story story=<first-ID>`
EOF
)"

gh issue edit {number} --add-label "status:ready" --remove-label "status:investigating"
```

### 8. Summary

Report to the user:
- Classification
- Root cause (if bug) or scope (if feature)
- Handover file paths
- New story IDs
- Next command
