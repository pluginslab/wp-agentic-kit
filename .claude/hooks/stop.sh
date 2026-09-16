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

# Hooks must never block, so a missing lib is a silent no-op rather than an error.
lib="$(dirname "${BASH_SOURCE[0]}")/lib.sh"
[[ -r "$lib" ]] || exit 0
# shellcheck source=./lib.sh
source "$lib"

# Same definition of "active" the other two hooks use — one implementation,
# in lib.sh, rather than three copies kept in lockstep by hand.
active=$(hook_active_progress "$plans_dir")
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
