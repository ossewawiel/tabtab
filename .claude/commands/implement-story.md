---
description: Implement a single story using TDD, with a mandatory review checkpoint.
argument-hint: "story=<ID or issue number>"
---

# /implement-story

You are implementing a single story using TDD. Your job is to **write tests first**,
**implement minimal code**, **stop for review**, and only then **update tracking docs**.

## Inputs

Arguments: **$ARGUMENTS** (expects `story=<ID>` or `story=<GitHub issue number>`)

## Hard constraints

- You **MAY NOT** decompose stories (that's `/plan-feature`).
- You **MAY NOT** create handover documents (that's `/process-feature`).
- You **MAY NOT** modify code belonging to other stories.
- You **MUST** follow Red → Green → Refactor for domain and service layers
  (see `docs/standards/tdd-guidelines.md`).
- You **MUST** stop at the review checkpoint (step 7) and wait for explicit
  developer approval.
- You **MAY NOT** update any documentation or GitHub state before the developer says "yes".

## Process

### 1. Resolve the story

From `$ARGUMENTS`:
- If it's a story ID (e.g. `BLD-007`), find it in `docs/specs/requirements/{platform}.md`
  and find the matching GitHub issue with `gh issue list --search "BLD-007 in:title"`.
- If it's a GitHub issue number, fetch via `gh issue view {number}` and extract the
  story ID from the title.

Detect the platform from the prefix:
- `BLD-*` → Builder (C++, `builder/`)
- `GEN-*` → Code Generator (C++, `builder/src/codegen/`)
- `OUT-*` → Output Framework (Kotlin, `output-template/`)
- `INF-*` → Infrastructure (`.github/`, build configs)
- `DOC-*` → Documentation (`docs/`)
- `TT-*` → Cross-cutting (ask for clarification)

### 2. Load the handover

Find the feature this story belongs to (check GitHub issue's milestone, or grep the
requirements file, or the spec's story list). Read:

- `docs/specs/features/{feature-name}/{platform}-handover.md`
- `docs/specs/features/{feature-name}/implementation-plan.md`

Extract the story's row from the Tasks table, its files list, and its TDD test plan.

### 3. Load standards (only once per session)

- `docs/standards/coding-standards.md`
- `docs/standards/tdd-guidelines.md`

### 4. Update GitHub status

```bash
gh issue edit {number} --add-label "status:in-progress" --remove-label "status:ready"
```

### 5. Present the implementation plan

Show the user:
- Story ID, title, platform
- Files to create/modify (from handover)
- Tests to write first
- Brief description of the approach

This is a **preview** — no confirmation needed yet. Proceed to step 6.

### 6. TDD implementation loop

For each test in the TDD test plan:

**Red:**
1. Write the failing test.
2. Run the test suite, confirm the new test fails for the **expected reason**.

**Green:**
3. Write the minimum code to make the test pass.
4. Run the suite, confirm green.

**Refactor:**
5. Clean up the code while keeping the suite green.
6. Run linters / formatters (`clang-format` for C++, `ktlint` for Kotlin).

Do **not** batch tests. One test at a time, fully cycled before moving on.

### 7. 🛑 MANDATORY REVIEW CHECKPOINT 🛑

**STOP HERE. DO NOT PROCEED WITHOUT EXPLICIT APPROVAL.**

Present:
- Story ID and title
- Files created/modified
- Test count (new, passing)
- Build status
- Any deviations from the handover plan (with justification)
- Verification instructions the developer can run locally:
  ```bash
  cd builder && cmake --build build --parallel
  cd builder/build && ctest --output-on-failure --label-regex "{story-id}"
  ```

Then ask: **"Is the story acceptable? Reply `yes` to record completion, or tell me what to fix."**

Wait. Do not update any docs or GitHub state.

### 8. Post-approval tracking

Only after explicit `yes`:

**a. Update `docs/specs/requirements/{platform}.md`**

Find the story's entry. Change `**Status:** 📋 Planned` → `**Status:** ✅ Done`.

**b. Update the handover document**

In `docs/specs/features/{feature-name}/{platform}-handover.md`, mark the story's
task row as `✅ Complete` in the Tasks table.

**c. Update the implementation plan**

In `docs/specs/features/{feature-name}/implementation-plan.md`, mark the story
as complete in any status tracking.

**d. Comment on the GitHub issue**

```bash
gh issue comment {number} --body "$(cat <<'EOF'
Implementation complete.

**Files changed:**
- ...

**Tests added:** N (all passing)

**Build:** green
EOF
)"
```

**e. Close-out label**

```bash
gh issue edit {number} --add-label "status:done" --remove-label "status:in-progress"
gh issue close {number}
```

### 9. Report milestone progress and suggest next

```bash
gh issue list --milestone "{milestone}" --state all --json number,title,state,labels
```

Tell the user:
- X of Y stories done in this milestone
- Next story from the implementation plan's critical path
- Suggested next command: `/implement-story story=<next-ID>`
