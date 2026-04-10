#!/usr/bin/env bash
# Initialise the GitHub repository with the label set and 5 phase milestones
# defined in the bootstrap spec.
#
# Usage:   bash scripts/init-github.sh
# Requires: gh CLI authenticated with repo scope against the right remote.

set -euo pipefail

say() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

# Resolve gh binary — prefer on-PATH, fall back to the default Windows install path.
if command -v gh >/dev/null 2>&1; then
    GH=gh
elif [ -x "/c/Program Files/GitHub CLI/gh.exe" ]; then
    GH="/c/Program Files/GitHub CLI/gh.exe"
else
    echo "error: gh CLI not found on PATH or at the default Windows location" >&2
    exit 1
fi

# Confirm we're in the right repo
REPO=$("$GH" repo view --json nameWithOwner -q .nameWithOwner)
say "Operating on repository: $REPO"
read -p "Continue? [y/N] " -r REPLY
[[ "$REPLY" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ----------------------------------------------------------------------
# Labels
# ----------------------------------------------------------------------

declare -A LABELS=(
    # Type
    ["type:feature"]="1d76db|New feature"
    ["type:bug"]="d73a4a|Something isn't working"
    ["type:improvement"]="a2eeef|Enhancement to existing feature"
    ["type:maintenance"]="cfd3d7|Refactor, deps, cleanup"
    ["type:docs"]="0075ca|Documentation only"

    # Component
    ["comp:builder"]="5319e7|Affects the C++ builder app"
    ["comp:codegen"]="5319e7|Affects the code generator"
    ["comp:output"]="5319e7|Affects the generated Kotlin output"
    ["comp:infra"]="5319e7|Affects CI/CD, build system, tooling"
    ["comp:docs"]="5319e7|Affects documentation"

    # Status
    ["status:new"]="c2e0c6|Just created, not yet triaged"
    ["status:investigating"]="fbca04|Being investigated"
    ["status:ready"]="0e8a16|Ready to implement"
    ["status:in-progress"]="f9d0c4|Currently being worked on"
    ["status:review"]="d4c5f9|Awaiting review"
    ["status:done"]="006b75|Complete"

    # Priority
    ["prior:critical"]="b60205|Must fix immediately"
    ["prior:high"]="d93f0b|Important"
    ["prior:medium"]="fbca04|Normal"
    ["prior:low"]="c2e0c6|Nice to have"

    # Phase
    ["phase-1"]="bfd4f2|Foundation"
    ["phase-2"]="bfd4f2|Designer Core"
    ["phase-3"]="bfd4f2|Data & Signals"
    ["phase-4"]="bfd4f2|Code Gen & Export"
    ["phase-5"]="bfd4f2|Polish & Community"

    # Source
    ["source:ai-agent"]="ededed|Created by an AI agent via /plan-feature or /create-issue"
    ["source:community"]="ededed|Reported by a community member"
    ["source:maintainer"]="ededed|Created by a maintainer"
)

say "Creating labels..."
for name in "${!LABELS[@]}"; do
    color="${LABELS[$name]%%|*}"
    desc="${LABELS[$name]##*|}"
    if "$GH" label list --limit 200 | awk '{print $1}' | grep -qx "$name"; then
        "$GH" label edit "$name" --color "$color" --description "$desc" >/dev/null
        printf "  updated: %s\n" "$name"
    else
        "$GH" label create "$name" --color "$color" --description "$desc" >/dev/null
        printf "  created: %s\n" "$name"
    fi
done

# ----------------------------------------------------------------------
# Milestones
# ----------------------------------------------------------------------

create_milestone() {
    local title="$1" description="$2"
    if "$GH" api "repos/$REPO/milestones" --jq '.[].title' | grep -qx "$title"; then
        printf "  exists:  %s\n" "$title"
    else
        "$GH" api "repos/$REPO/milestones" \
            -f title="$title" \
            -f description="$description" \
            -f state=open >/dev/null
        printf "  created: %s\n" "$title"
    fi
}

say "Creating milestones..."
create_milestone "Phase 1: Foundation" \
    "C++ app with Skia, basic widgets, layout engine, YAML parser"
create_milestone "Phase 2: Designer Core" \
    "Drag-drop, property editing, Material 3 components, theming"
create_milestone "Phase 3: Data & Signals" \
    "Signal graph, REST/SQL connectors, live data preview"
create_milestone "Phase 4: Code Gen & Export" \
    "Kotlin generator, Gradle scaffold, quick-run, Fluent"
create_milestone "Phase 5: Polish & Community" \
    "Plugin API, navigation editor, undo/redo, docs"

say "Done."
