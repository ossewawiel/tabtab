---
description: Create a single GitHub issue from a short description, with correct labels and milestone.
argument-hint: "<description>"
---

# /create-issue

You are creating a single GitHub issue on behalf of the user. This is for quick
one-off issues that don't need the full `/plan-feature` decomposition.

## Inputs

The description: **$ARGUMENTS**

## Hard constraints

- You **MAY NOT** decompose into multiple issues. One invocation = one issue.
  If the user describes something that needs decomposition, suggest `/plan-feature`
  instead.
- You **MAY NOT** start investigating or implementing — only create the issue.
- You **MUST** classify and label correctly.

## Process

### 1. Classify

From the description, infer:
- **Type:** `bug` / `feature` / `improvement` / `maintenance` / `docs`
- **Component:** `builder` / `codegen` / `output` / `infra` / `docs`
- **Priority:** `critical` / `high` / `medium` / `low` (default `medium`)
- **Phase:** `phase-1` ... `phase-5` (if obvious; otherwise leave unlabeled)

### 2. Draft the issue

Use the matching template structure:

**Bug:**
```markdown
## Description
{what is broken}

## Steps to reproduce
1. ...

## Expected behaviour
...

## Actual behaviour
...

## Platform
{builder / output / codegen}

## Version
{if known}
```

**Feature/improvement:**
```markdown
## Description
{what should exist}

## Motivation
{why}

## Proposed solution
{if the user had one}

## Alternatives considered
{if the user mentioned any}
```

### 3. Present for approval

Show:
- Draft title (≤ 70 chars)
- Draft body
- Labels
- Milestone (if any)

Ask: **"Create this issue? (yes / edit / cancel)"**

### 4. On approval

```bash
gh issue create \
  --title "{title}" \
  --body-file /tmp/issue-body.md \
  --label "type:{type},comp:{comp},prior:{prior},status:new,source:ai-agent" \
  {--milestone "{milestone}" if applicable}
```

### 5. Report

- Issue URL
- Suggested next command:
  - `/process-issue issue={number}` — investigate and plan the fix
  - `/plan-feature` — if it turns out to need decomposition
