#!/usr/bin/env bash
#
# Pre-commit gate
# Fires before any Bash invocation. Filters for `git commit` and delegates
# to scripts/quality.sh — the single source of truth for the quality suite.
# Exits non-zero to block the commit if the suite fails.
#
# This hook fails OPEN by design: it runs before every Bash call, so blocking
# on its own internal errors would wedge the session. The price of failing
# open is that a broken gate is invisible — you keep believing you are gated
# while nothing runs. So every path that gives up says so, loudly, on stderr.
#
set -uo pipefail

payload=$(cat)

# No payload at all: nothing to inspect, and no real invocation looks like
# this. Stay quiet rather than crying wolf on every command.
[[ -z "$payload" ]] && exit 0

# Extract .tool_input.command. Two parsers, because the hook previously used
# python3 alone and did not check whether it existed — on a host without it,
# the capture came back empty, matched nothing, and the gate silently turned
# itself off.
parsed=''
have_parser=0

if command -v python3 >/dev/null 2>&1; then
  if parsed=$(printf '%s' "$payload" | python3 -c '
import json, sys
data = json.load(sys.stdin)
sys.stdout.write(str(data.get("tool_input", {}).get("command", "")))
' 2>/dev/null); then
    have_parser=1
  fi
fi

if (( ! have_parser )) && command -v jq >/dev/null 2>&1; then
  if parsed=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""' 2>/dev/null); then
    have_parser=1
  fi
fi

if (( ! have_parser )); then
  echo "pre-commit: cannot read the hook payload — no working python3 or jq on PATH." >&2
  echo "pre-commit: THE QUALITY GATE IS NOT RUNNING. Install python3 or jq to re-enable it." >&2
  exit 0
fi

# Match `git commit` anywhere in the command, not only at the start.
#
# The previous prefix match (`git commit*`) meant the gate never fired for
# `git add -A && git commit -m ...` — the most common commit idiom there is —
# nor for `cd sub && git commit`, nor `git -C dir commit`. The gate looked
# present and was inert for the shapes people actually type.
#
# The regex allows flags and paths between `git` and `commit`, but not a
# command separator, so `git status && make commit-docs` does not match.
#
# Tradeoff: this does match a command that merely mentions committing, e.g.
# `git log --grep=commit`. That direction is the safe one — a needless quality
# run costs seconds, a skipped gate costs a broken commit — but it is a real
# tradeoff, so the block message below names the command that triggered it.
# Held in a variable: inside [[ =~ ]] an inline pattern containing `;` or `&`
# is parsed as shell syntax before the regex engine ever sees it.
commit_re='(^|[;&|[:space:]])git[[:space:]][^;&|]*commit'

if [[ ! "$parsed" =~ $commit_re ]]; then
  exit 0
fi

if [[ ! -x "./scripts/quality.sh" ]]; then
  echo "scripts/quality.sh missing or not executable; skipping pre-commit gate." >&2
  exit 0
fi

if ! ./scripts/quality.sh; then
  echo "" >&2
  echo "Commit blocked. Fix the issues above, then commit again." >&2
  echo "Triggered by: $parsed" >&2
  exit 1
fi

exit 0
