#!/usr/bin/env bash
#
# Tests for .claude/hooks/session-start.sh
#
# Verifies the banner emits on resume/compact/clear when a plan is active,
# stays silent when nothing's active, and respects the completion synonyms.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "session-start.sh"

# --- Case 1: no .claude/plans/ → silent ---
setup_sandbox
rm -rf .claude
run_hook "session-start.sh"
assert_exit_code "no .claude dir → exit 0" 0 "$HOOK_EXIT"
assert_empty "no .claude dir → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 2: empty features/ → silent ---
setup_sandbox
run_hook "session-start.sh"
assert_exit_code "empty features/ → exit 0" 0 "$HOOK_EXIT"
assert_empty "empty features/ → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 3: in_progress feature → banner with slug + next_action ---
setup_sandbox
write_progress "001-foo" "in_progress" "Step 1" "Step 2 — implement at file.php:42"
run_hook "session-start.sh"
assert_exit_code "active → exit 0" 0 "$HOOK_EXIT"
assert_contains "active → mentions slug" "$HOOK_STDOUT_TEXT" "001-foo"
assert_contains "active → mentions next_action" "$HOOK_STDOUT_TEXT" "Step 2 — implement at file.php:42"
assert_contains "active → cites plan.md path" "$HOOK_STDOUT_TEXT" "plan.md"
teardown_sandbox

# --- Case 4: completed feature → silent ---
setup_sandbox
write_progress "001-shipped" "complete"
run_hook "session-start.sh"
assert_empty "complete → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 5: mix → picks the active one ---
setup_sandbox
write_progress "001-done" "shipped"
sleep 1
write_progress "002-active" "in_progress" "Step A" "Step B"
run_hook "session-start.sh"
assert_contains "mixed → picks active" "$HOOK_STDOUT_TEXT" "002-active"
assert_not_contains "mixed → ignores shipped" "$HOOK_STDOUT_TEXT" "001-done"
teardown_sandbox

# --- Case 6: completion synonyms → silent ---
for status in done completed shipped archived; do
  setup_sandbox
  write_progress "001-$status" "$status"
  run_hook "session-start.sh"
  assert_empty "status=$status → no stdout" "$HOOK_STDOUT_TEXT"
  teardown_sandbox
done

exit $FAIL_COUNT
