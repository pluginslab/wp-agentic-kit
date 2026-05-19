#!/usr/bin/env bash
#
# tests/lib.sh — shared test helpers.
#
# Source this from each test file. Provides:
#   - assert_equals, assert_contains, assert_not_contains, assert_file_contains
#   - setup_sandbox / teardown_sandbox — temp dir with mini .claude/plans/ tree
#   - pass / fail counters surfaced via PASS_COUNT / FAIL_COUNT
#   - $KIT_ROOT — absolute path to the repo root
#
# Conventions:
#   - Every assertion prints one line on stdout: "  ✓ <name>" or "  ✗ <name>: <reason>"
#   - Test files exit 0 if all asserts pass, non-zero if any fail.
#   - Teardown runs on EXIT via trap, even on failure.

set -uo pipefail

# Resolve the kit root once. Tests run from anywhere.
if [[ -z "${KIT_ROOT:-}" ]]; then
  KIT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  export KIT_ROOT
fi

PASS_COUNT=${PASS_COUNT:-0}
FAIL_COUNT=${FAIL_COUNT:-0}

_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '  \033[32m✓\033[0m %s\n' "$1"
}

_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  \033[31m✗\033[0m %s: %s\n' "$1" "$2"
}

assert_equals() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    _pass "$name"
  else
    _fail "$name" "expected $(printf %q "$expected"), got $(printf %q "$actual")"
  fi
}

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    _pass "$name"
  else
    _fail "$name" "output did not contain $(printf %q "$needle")"
  fi
}

assert_not_contains() {
  local name="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    _pass "$name"
  else
    _fail "$name" "output unexpectedly contained $(printf %q "$needle")"
  fi
}

assert_empty() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    _pass "$name"
  else
    _fail "$name" "expected empty, got $(printf %q "$value")"
  fi
}

assert_file_contains() {
  local name="$1" file="$2" needle="$3"
  if [[ ! -f "$file" ]]; then
    _fail "$name" "file $file does not exist"
    return
  fi
  if grep -qF "$needle" "$file"; then
    _pass "$name"
  else
    _fail "$name" "$file did not contain $(printf %q "$needle")"
  fi
}

assert_exit_code() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    _pass "$name"
  else
    _fail "$name" "expected exit $expected, got $actual"
  fi
}

# Setup a sandbox: temp dir that becomes cwd. Tests put fixtures here.
# Always pair with teardown_sandbox (or rely on the EXIT trap).
setup_sandbox() {
  SANDBOX=$(mktemp -d -t wpkit-test.XXXXXX)
  export SANDBOX
  mkdir -p "$SANDBOX/.claude/plans/features" "$SANDBOX/.claude/plans/archive"
  cd "$SANDBOX"
  trap teardown_sandbox EXIT
}

teardown_sandbox() {
  if [[ -n "${SANDBOX:-}" && -d "$SANDBOX" && "$SANDBOX" == */wpkit-test.* ]]; then
    rm -rf "$SANDBOX"
  fi
}

# Drop a progress.md fixture under .claude/plans/features/$1/.
# Usage: write_progress <slug> <status> [last_completed] [next_action]
write_progress() {
  local slug="$1" status="$2"
  local last_completed="${3:-Step 0}"
  local next_action="${4:-Step 1}"
  mkdir -p ".claude/plans/features/$slug"
  cat > ".claude/plans/features/$slug/progress.md" <<EOF
# Progress — $slug

status: $status
last_updated: 2026-01-01 00:00

## State

- last_completed: $last_completed
- next_action: $next_action
- blockers: none
EOF
}

# Run a hook with stdin payload. Captures stdout + stderr + exit code.
# Sets HOOK_STDOUT / HOOK_STDERR / HOOK_EXIT.
run_hook() {
  local hook="$1" payload="${2:-}"
  HOOK_STDOUT=$(mktemp)
  HOOK_STDERR=$(mktemp)
  echo "$payload" | "$KIT_ROOT/.claude/hooks/$hook" > "$HOOK_STDOUT" 2> "$HOOK_STDERR"
  HOOK_EXIT=$?
  HOOK_STDOUT_TEXT=$(cat "$HOOK_STDOUT")
  HOOK_STDERR_TEXT=$(cat "$HOOK_STDERR")
  rm -f "$HOOK_STDOUT" "$HOOK_STDERR"
  export HOOK_STDOUT_TEXT HOOK_STDERR_TEXT HOOK_EXIT
}
