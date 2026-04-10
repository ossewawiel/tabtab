# Investigation: {Issue Title}

**Issue:** #{number}
**Date:** {YYYY-MM-DD}
**Type:** {bug|improvement|feature|maintenance|docs}
**Platforms:** {affected platforms}
**Investigator:** {agent or person}

## Problem Statement

{The issue description, summarised and sharpened. What does the user see? What
did they expect? What's the gap?}

## Investigation Steps

1. {What was checked}
2. {What was found / ruled out}
3. ...

## Root Cause / Analysis

{The concrete technical explanation. What code is wrong, or what design is
missing? Include file paths and line numbers. If you don't know the root cause
yet, say so explicitly and list what you ruled out.}

## Affected Components

### Builder (C++)
- {files/modules touched by the fix}

### Code Generator
- {files/modules}

### Output Framework
- {files/modules}

### Infrastructure
- {files/modules}

## Proposed Fix

{High-level approach. Not the code — just the strategy. Why this approach and
not the alternatives you considered.}

## Alternatives Considered

- **{Alternative 1}** — rejected because {reason}
- **{Alternative 2}** — rejected because {reason}

## Stories to Create

| ID | Platform | Summary |
|---|---|---|
| {ID} | {platform} | {1-line summary} |

## Risks

- {Anything that could go wrong during the fix}
