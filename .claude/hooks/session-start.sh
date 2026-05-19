#!/usr/bin/env bash
#
# SessionStart — orient on resume / compact / clear.
#
# When a session resumes, the conversation history is back but the active
# plan isn't surfaced anywhere visible. This hook prints a one-line banner
# so you re-anchor before typing the next prompt. Silent when no plan is
# active.
#
# Per Anthropic issue #10373, SessionStart stdout is dropped on brand-new
# sessions but works on `resume|compact|clear`. The kit registers this hook
# under those matchers in settings.json; that's where the constraint lives.
#
set -uo pipefail

plans_dir=".claude/plans/features"
[[ ! -d "$plans_dir" ]] && exit 0

active=""
newest=0
while IFS= read -r -d '' progress; do
  status=$(grep -m1 '^status:' "$progress" 2>/dev/null | sed 's/^status: *//' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  case "$status" in
    complete|completed|done|shipped|archived) continue ;;
  esac
  mtime=$(stat -f %m "$progress" 2>/dev/null || stat -c %Y "$progress" 2>/dev/null || echo 0)
  if (( mtime > newest )); then
    newest=$mtime
    active="$progress"
  fi
done < <(find "$plans_dir" -mindepth 2 -maxdepth 2 -name progress.md -print0 2>/dev/null)

[[ -z "$active" ]] && exit 0

feature_dir=$(dirname "$active")
feature_slug=$(basename "$feature_dir")
next_action=$(grep -m1 '^- next_action:' "$active" 2>/dev/null | sed 's/^- next_action: *//')

cat <<EOF
Active feature: $feature_slug
Next action: ${next_action:-(see $feature_dir/plan.md)}
Plan: $feature_dir/plan.md · Progress: $active
EOF

exit 0
