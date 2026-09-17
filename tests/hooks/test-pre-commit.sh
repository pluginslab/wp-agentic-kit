#!/usr/bin/env bash
#
# Tests for .claude/hooks/pre-commit.sh
#
# The hook filters Bash invocations and only acts on `git commit`. We test:
#   1. non-commit Bash → exit 0 (passthrough)
#   2. git commit + no scripts/quality.sh → exit 0 with warning (skip gate)
#   3. git commit + passing quality.sh → exit 0
#   4. git commit + failing quality.sh → exit 1 (block), naming the command
#   5. compound / flagged commit forms still trigger the gate
#   6. no JSON parser available → exit 0, but loudly
#   7. empty payload → quiet passthrough
#
# Cases 5 and 6 exist because this hook had two ways of silently doing
# nothing. A prefix match meant `git add -A && git commit -m x` — the most
# common commit idiom there is — never triggered it. And parsing the payload
# with python3 alone meant a host without python3 got no gate and no warning.
# Both failed open *invisibly*, which is the worst property a gate can have:
# you keep the belief that you are covered.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "pre-commit.sh"

# Everything that asserts the gate *fires* needs a JSON parser on PATH, because
# without one the hook cannot read the command and correctly declines to gate.
# Demanding a gate on a host with no parser would make this suite red for
# behaving exactly as designed — the same "the test encodes my machine" mistake
# that hid the Linux mtime bug. Case 6 covers the no-parser contract head-on.
if command -v python3 >/dev/null 2>&1 || command -v jq >/dev/null 2>&1; then
  HAVE_PARSER=1
else
  HAVE_PARSER=0
fi

write_quality() {
  # write_quality <exit-code>
  mkdir -p scripts
  printf '#!/usr/bin/env bash\nexit %s\n' "$1" > scripts/quality.sh
  chmod +x scripts/quality.sh
}

# --- Case 1: non-commit Bash command → exit 0, no gate run ---
setup_sandbox
run_hook "pre-commit.sh" '{"tool_input":{"command":"ls -la"}}'
assert_exit_code "non-commit → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 2: git status → exit 0, no gate run ---
setup_sandbox
run_hook "pre-commit.sh" '{"tool_input":{"command":"git status"}}'
assert_exit_code "git status (not commit) → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

if (( HAVE_PARSER )); then

  # --- Case 3: git commit but no scripts/quality.sh → exit 0 with warning ---
  setup_sandbox
  run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m foo"}}'
  assert_exit_code "git commit, no quality.sh → exit 0" 0 "$HOOK_EXIT"
  assert_contains "git commit, no quality.sh → warns on stderr" \
    "$HOOK_STDERR_TEXT" "quality.sh missing"
  teardown_sandbox

  # --- Case 4: git commit + passing quality.sh → exit 0 ---
  setup_sandbox
  write_quality 0
  run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m feat"}}'
  assert_exit_code "git commit, quality pass → exit 0" 0 "$HOOK_EXIT"
  teardown_sandbox

  # --- Case 5: git commit + failing quality.sh → exit 1 (blocks commit) ---
  setup_sandbox
  write_quality 1
  run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m bad"}}'
  assert_exit_code "git commit, quality fail → exit 1" 1 "$HOOK_EXIT"
  assert_contains "git commit, quality fail → block message" \
    "$HOOK_STDERR_TEXT" "Commit blocked"
  # The widened match can fire on a command that merely mentions committing,
  # so a block has to say what triggered it or the user cannot tell why.
  assert_contains "git commit, quality fail → names the command" \
    "$HOOK_STDERR_TEXT" "git commit -m bad"
  teardown_sandbox

  # --- Case 6: commit shapes a prefix match would miss ---
  # Every one of these bypassed the gate entirely before the match was widened.
  for cmd in \
    "git add -A && git commit -m x" \
    "cd sub && git commit -m x" \
    "git -C /some/dir commit -m x" \
    "git commit --amend --no-edit"
  do
    setup_sandbox
    write_quality 1
    run_hook "pre-commit.sh" "{\"tool_input\":{\"command\":\"$cmd\"}}"
    assert_exit_code "gate fires on: $cmd" 1 "$HOOK_EXIT"
    teardown_sandbox
  done

  # …and shapes that must still pass straight through.
  for cmd in "git status" "git log --oneline" "ls -la" "make build"; do
    setup_sandbox
    write_quality 1
    run_hook "pre-commit.sh" "{\"tool_input\":{\"command\":\"$cmd\"}}"
    assert_exit_code "gate ignores: $cmd" 0 "$HOOK_EXIT"
    teardown_sandbox
  done

else
  echo "  - skipped 14 gate-firing cases: no python3 or jq on PATH"
fi

# --- Case 7: no JSON parser on PATH → fail open, but say so ---
# This path used to be silent: no python3 meant no gate and no warning.
setup_sandbox
write_quality 1

# A PATH with no python3 and no jq on it.
stub_bin="$SANDBOX/stub-bin"
mkdir -p "$stub_bin"
for tool in bash cat grep sed; do
  real=$(command -v "$tool" 2>/dev/null) && ln -sf "$real" "$stub_bin/$tool" 2>/dev/null
done

out=$(PATH="$stub_bin" "$KIT_ROOT/.claude/hooks/pre-commit.sh" \
  <<< '{"tool_input":{"command":"git commit -m x"}}' 2>&1)
rc=$?

assert_exit_code "no parser → does not block" 0 "$rc"
assert_contains "no parser → warns the gate is off" "$out" "QUALITY GATE IS NOT RUNNING"
teardown_sandbox

# --- Case 8: empty payload → quiet passthrough ---
# Nothing to inspect, and no real invocation looks like this. Warning here
# would cry wolf on every command.
setup_sandbox
run_hook "pre-commit.sh" ""
assert_exit_code "empty payload → exit 0" 0 "$HOOK_EXIT"
assert_empty "empty payload → no stderr noise" "$HOOK_STDERR_TEXT"
teardown_sandbox

exit $FAIL_COUNT
