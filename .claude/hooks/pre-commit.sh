#!/usr/bin/env bash
#
# Pre-commit gate
# Fires before any Bash invocation. Filters for `git commit` and delegates
# to scripts/quality.sh — the single source of truth for the quality suite.
# Exits non-zero to block the commit if the suite fails.
#
set -uo pipefail

command=$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("command", ""))
except Exception:
    pass
')

case "$command" in
  git\ commit*) ;;
  *) exit 0 ;;
esac

if [[ ! -x "./scripts/quality.sh" ]]; then
  echo "scripts/quality.sh missing or not executable; skipping pre-commit gate." >&2
  exit 0
fi

if ! ./scripts/quality.sh; then
  echo "" >&2
  echo "Commit blocked. Fix the issues above, then commit again." >&2
  exit 1
fi

exit 0
