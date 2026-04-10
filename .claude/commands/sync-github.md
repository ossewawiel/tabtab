---
description: Sync local story/handover status with GitHub issue state and report drift.
---

# /sync-github

You are reconciling the local docs with GitHub state. Story status lives in two
places (`docs/specs/requirements/{platform}.md` and GitHub issue labels), and they
drift over time. This command detects and optionally fixes the drift.

## Hard constraints

- You **MAY NOT** auto-fix drift without approval. Report first, fix after the user
  says which direction wins.
- You **MAY NOT** close or reopen GitHub issues without explicit approval.
- You **MAY NOT** delete local stories.

## Process

### 1. Collect GitHub state

```bash
gh issue list --state all --limit 1000 \
  --json number,title,state,labels,milestone,closedAt
```

Parse into a map: `storyId → {state, labels, milestone}`.

Extract the story ID from each title (assuming titles start with `[BLD-007]`,
`[GEN-014]`, etc.).

### 2. Collect local state

Grep the four requirement files for story entries and extract each story's status
(`📋 Planned`, `🔄 In Progress`, `✅ Done`, etc.).

For each feature in `docs/specs/features/`, read its `spec.md` to get the
feature→stories mapping.

### 3. Detect drift

For each story, compare:

| Local status | GitHub labels | Drift? |
|---|---|---|
| 📋 Planned | status:new | No |
| 📋 Planned | status:in-progress | ⚠ Yes |
| ✅ Done | status:done + closed | No |
| ✅ Done | open + status:in-progress | ⚠ Yes |
| 🔄 In Progress | status:done + closed | ⚠ Yes |
| missing locally | exists on GitHub | ⚠ Yes (orphan on GitHub) |
| exists locally | missing on GitHub | ⚠ Yes (orphan locally) |

### 4. Present the drift report

Group by drift type. For each drifted story, show:
- Story ID
- Local status
- GitHub state + labels
- Suggested resolution (trust local / trust GitHub / create missing)

Ask: **"How should I resolve these? Options:
 - `trust-local` — update GitHub to match local
 - `trust-github` — update local to match GitHub
 - `per-item` — walk through each one
 - `report-only` — just show the report, change nothing"**

### 5. Apply the resolution

Based on the user's choice, update labels via `gh issue edit` or patch the
requirement files via `Edit`. Never delete stories.

### 6. Report

- How many stories checked
- How many were drifted
- How many were resolved
- Remaining orphans (if any)
