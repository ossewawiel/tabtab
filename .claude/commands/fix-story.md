---
description: Fix issues found in a completed story during review — keeps TDD discipline and re-runs the review checkpoint.
argument-hint: "story=<ID or issue number>"
---

# /fix-story

You are fixing problems found in a story that has already been through
`/implement-story` but **failed review**. The developer said "no, fix X" at the
review checkpoint — or found a problem after approval and wants it addressed
inside the same story.

## Inputs

Arguments: **$ARGUMENTS** (expects `story=<ID>` and the problems to fix — you may
ask the developer if unclear)

## Hard constraints

- You **MAY NOT** expand the story's scope. Only fix what was flagged.
- You **MAY NOT** skip tests. If the bug slipped past the TDD test plan, that
  means a test is missing — add it **first** before fixing.
- You **MUST** re-run the full review checkpoint after fixing.
- If the fix reveals a flaw in the handover's TDD test plan, update the handover.

## Process

### 1. Resolve the story

Same as `/implement-story` step 1 — find the story in requirements and the matching
GitHub issue.

### 2. Read the developer's complaint

From the latest review feedback:
- What is broken / wrong / missing?
- Is it a code bug, a test gap, a spec drift, or a scope disagreement?

If it's a scope disagreement, **stop** and ask the developer whether to amend the
story's handover or spin off a new story via `/plan-feature`.

### 3. Re-load context

- The story's handover document
- The files already created by `/implement-story` (via `git status` and `git diff`)
- Relevant architecture docs (only the sections touching the affected area)

### 4. For each problem

**a. Write a failing test that reproduces the problem.**
   - Run the suite; confirm it fails for the expected reason.

**b. Fix the code** until the new test passes and all existing tests still pass.

**c. Refactor** if the fix exposed smells, but stay inside the story's scope.

### 5. Update the handover's test plan

If the original TDD plan missed this case, append the new test(s) to the handover's
test plan table with a note: `added during fix-story`.

### 6. Re-run the review checkpoint

Exactly like `/implement-story` step 7 — stop and wait for approval. Do **not**
auto-update docs or GitHub.

### 7. On approval

Same tracking updates as `/implement-story` step 8:
- Update requirements file (if status changed from review back to done)
- Update handover
- Comment on the GitHub issue describing the fix
- Re-apply `status:done` label if it was removed

### 8. Report

Summarise: what was broken, what was fixed, which tests were added, current build
status.
