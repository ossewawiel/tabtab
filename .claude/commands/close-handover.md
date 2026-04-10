---
description: Verify all stories in a feature are complete, close the milestone, and archive handover documents.
argument-hint: "feature=<name>"
---

# /close-handover

You are closing out a fully-implemented feature. Your job is to **verify**,
**archive**, and **report** — not to fix or implement.

## Inputs

Arguments: **$ARGUMENTS** (expects `feature=<name>`)

## Hard constraints

- You **MAY NOT** close a feature with open stories. Stop and report the gap.
- You **MAY NOT** delete handover documents. Archive them.
- You **MAY NOT** close the GitHub milestone while any issue in it is open.

## Process

### 1. Load the feature

Read `docs/specs/features/{feature-name}/spec.md`. Extract the full story list
and the target milestone.

### 2. Verify every story is done

For each story in the spec:

**a. Check the requirements file** — status must be `✅ Done`.

**b. Check the GitHub issue:**
```bash
gh issue view {number} --json state,labels
```
Must be `CLOSED` with label `status:done`.

**c. Check the handover's task table** — every row must be `✅ Complete`.

If **any** check fails, stop and report:
- Which story failed which check
- Suggested next action (usually `/implement-story` or `/fix-story`)

### 3. Verify the build is green

```bash
# Builder
cd builder && cmake --build build --parallel && cd build && ctest --output-on-failure

# Codegen (if affected)
cd tests/codegen && python run_tests.py

# Output examples (if affected)
cd examples/customer-manager/exported && ./gradlew build
```

If anything is red, stop. The feature isn't done.

### 4. Update the feature spec

In `docs/specs/features/{feature-name}/spec.md`:
- Change `status: planned` or `status: in_progress` → `status: complete`
- Add `completed: {YYYY-MM-DD}` to the frontmatter
- Update the Stories table so every row shows ✅ Done

### 5. Archive handovers

Move the feature directory to an archive prefix:

```bash
mv docs/specs/features/{feature-name} docs/specs/features/_archive/{feature-name}
```

(Create `docs/specs/features/_archive/` if it doesn't exist.)

### 6. Close the GitHub milestone

```bash
gh api repos/:owner/:repo/milestones/{milestone-number} -X PATCH -f state=closed
```

### 7. Report

- Feature name
- Stories closed (count)
- Archive location
- Milestone URL
- Suggested next command: `/plan-feature` for the next feature, or `/create-release`
  if the milestone completion finishes a phase.
