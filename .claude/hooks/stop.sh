#!/usr/bin/env bash
#
# Stop — touch progress.md's last_updated when the agent finishes a turn.
#
# Without this, last_updated only changes when the agent remembers to write
# to progress.md, which is exactly the failure mode the planning layer is
# meant to defend against. This closes the loop: file age now reflects
# actual session activity.
#
# Silent. Never blocks. Modifies at most one file.
#
set -uo pipefail

plans_dir=".claude/plans/features"
[[ ! -d "$plans_dir" ]] && exit 0

# Find the most recently modified non-complete progress.md (same logic as
# user-prompt-submit.sh — keeps the two hooks in lockstep on which feature
# is "active").
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

now=$(date "+%Y-%m-%d %H:%M")

# Replace the line; create one if it's missing. Cross-platform sed: BSD sed
# (macOS) needs -i ''; GNU sed accepts -i alone. We sidestep with a temp file.
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if grep -q '^last_updated:' "$active"; then
  awk -v now="$now" '
    /^last_updated:/ { print "last_updated: " now; next }
    { print }
  ' "$active" > "$tmp" && mv "$tmp" "$active"
else
  # Insert after the status: line, or at the top if no status: line.
  awk -v now="$now" '
    BEGIN { inserted = 0 }
    /^status:/ && !inserted { print; print "last_updated: " now; inserted = 1; next }
    { print }
    END {
      if (!inserted) {
        # No status: line found; nothing inserted. Leave file alone.
      }
    }
  ' "$active" > "$tmp" && mv "$tmp" "$active"
fi

exit 0
