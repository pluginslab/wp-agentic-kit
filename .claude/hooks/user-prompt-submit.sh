#!/usr/bin/env bash
#
# UserPromptSubmit — surface the active plan on every turn.
#
# Reads .claude/plans/features/*/progress.md, picks the most recently
# modified active feature, and emits a short context block so the agent
# re-anchors on its plan instead of drifting (the 33% edit-without-read
# failure mode observed in the wild).
#
# Stays silent when no active feature exists. Never blocks.
#
set -uo pipefail

plans_dir=".claude/plans/features"
[[ ! -d "$plans_dir" ]] && exit 0

# Hooks must never block, so a missing lib is a silent no-op rather than an error.
lib="$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[[ -r "$lib" ]] || exit 0
# shellcheck source=./lib.sh
source "$lib"

active=$(hook_active_progress "$plans_dir")
[[ -z "$active" ]] && exit 0

feature_dir=$(dirname "$active")
feature_slug=$(basename "$feature_dir")
plan="$feature_dir/plan.md"

# Pull the next pending step from plan.md (first H3 under Steps that isn't
# already mentioned in progress.md as last_completed).
next_action=$(grep -m1 '^- next_action:' "$active" 2>/dev/null | sed 's/^- next_action: *//')
last_completed=$(grep -m1 '^- last_completed:' "$active" 2>/dev/null | sed 's/^- last_completed: *//')
blockers=$(grep -m1 '^- blockers:' "$active" 2>/dev/null | sed 's/^- blockers: *//')

cat <<EOF
<system-reminder>
Active feature plan: $feature_slug

- Last completed: ${last_completed:-(none recorded)}
- Next action: ${next_action:-(see $plan)}
- Blockers: ${blockers:-none}

Plan file: $plan
Progress file: $active

Read the plan before editing. Update progress.md when a step completes.
Mirror open plan steps into your harness task tool (e.g. TaskCreate) at session start, if one is available.
</system-reminder>
EOF

exit 0
