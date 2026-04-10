---
description: Tag a release, update version numbers, generate changelog from closed issues, and trigger the release workflow.
argument-hint: "[version=<x.y.z>]"
---

# /create-release

You are cutting a release. Your job is to **determine the version**, **update
version metadata**, **generate the changelog**, and **create the git tag** — not
to push or publish.

## Inputs

Arguments: **$ARGUMENTS** (optional `version=<x.y.z>`; if omitted, compute next)

## Hard constraints

- You **MAY NOT** create a release while any CI job is failing on `main`.
- You **MAY NOT** push the tag without explicit developer approval.
- You **MAY NOT** re-tag or delete an existing tag.
- You **MUST** use semantic versioning.

## Process

### 1. Verify the working tree

```bash
git status --porcelain
git branch --show-current
```

- Must be on `main`.
- Must be clean (no uncommitted changes).
- Must be in sync with `origin/main`.

If not, stop and report.

### 2. Determine the version

**If `version=` was provided:** validate it as `MAJOR.MINOR.PATCH` and check it
doesn't already exist:
```bash
git tag --list "v{version}"
```

**If not provided:**
1. Find the latest tag: `git describe --tags --abbrev=0`
2. Inspect closed PRs/issues since that tag.
3. Propose the next version:
   - Breaking change mentioned anywhere → bump MAJOR
   - New feature (`type:feature`) → bump MINOR
   - Only bugs/docs/maintenance → bump PATCH
4. Show the proposal and ask for confirmation.

### 3. Update version metadata

- `builder/CMakeLists.txt` — update the `project(tabtab VERSION x.y.z)` line.
- Any other version-pinned files the agent finds via grep (e.g., `about.md`).

### 4. Generate the changelog

Query closed issues since the last tag:

```bash
gh issue list --state closed --search "closed:>{last-tag-date}" \
  --json number,title,labels,closedAt --limit 500
```

Group by type:

```markdown
## v{version} — {YYYY-MM-DD}

### Features
- [{ID}] Title — #{number}

### Bug fixes
- ...

### Improvements
- ...

### Maintenance & docs
- ...
```

Prepend this to `CHANGELOG.md` (create if missing).

### 5. Commit and tag

Show the user:
- Files changed
- Generated changelog entry
- Proposed commit message: `chore: release v{version}`
- Proposed tag: `v{version}`

Ask: **"Create commit and tag? Reply `yes` to commit locally (not push)."**

On approval:
```bash
git add builder/CMakeLists.txt CHANGELOG.md
git commit -m "chore: release v{version}"
git tag -a "v{version}" -m "Release v{version}"
```

### 6. Ask about pushing

Ask: **"Push commit and tag to origin? This triggers the release workflow. (yes / no)"**

On approval:
```bash
git push origin main
git push origin "v{version}"
```

### 7. Report

- Version
- Tag created (and whether pushed)
- Changelog path
- GitHub release URL (once the workflow creates it)
