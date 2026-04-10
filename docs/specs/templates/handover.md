---
feature: {feature-name}
platform: {builder|codegen|output|infra}
stories: [{story-ids}]
status: pending  # pending | in_progress | complete
dependencies: [{dependency-list}]
created: {YYYY-MM-DD}
---

# {Platform} Handover: {Feature Name}

## Context

{Background from architecture docs. What the implementing agent needs to know
with zero prior context. Include key class names, file paths, and data-flow
notes. Maximum ~300 words. If you're tempted to write more, link to the arch
doc instead.}

## Tasks

| # | Task | Story ID | Status | Files |
|---|------|----------|--------|-------|
| 1 | {task description} | {ID} | ⬜ Pending | {key files} |
| 2 | ... | ... | ⬜ Pending | ... |

## Files to Create/Modify

### New Files
- `{path}` — {purpose}
- ...

### Modified Files
- `{path}` — {what changes, 1 line}
- ...

## TDD Test Plan

| Test | Tests What | Priority |
|------|-----------|----------|
| `test_{unit}_{scenario}_{expected}` | {what this protects against} | Must have |
| ... | ... | ... |

## Acceptance Criteria

{Copy verbatim from the GitHub issue — checkbox list}

- [ ] ...
- [ ] ...

## Definition of Done

- [ ] All tasks marked ✅ Complete
- [ ] All tests pass
- [ ] Code follows `docs/standards/coding-standards.md`
- [ ] No compiler warnings
- [ ] `clang-tidy` / `ktlint` clean
- [ ] Documentation updated if the public API changed
- [ ] Review checkpoint approved by developer
