#!/usr/bin/env bash
#
# Tests for .claude/hooks/user-prompt-submit.sh
#
# Verifies the hook stays silent without an active feature, emits the
# system-reminder when one exists, and respects status-line completion
# synonyms (complete, done, shipped, ...).
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "user-prompt-submit.sh"

# --- Case 1: no .claude/plans/ at all → silent ---
setup_sandbox
rm -rf .claude
run_hook "user-prompt-submit.sh"
assert_exit_code "no .claude dir → exit 0" 0 "$HOOK_EXIT"
assert_empty "no .claude dir → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 2: empty features/ dir → silent ---
setup_sandbox
run_hook "user-prompt-submit.sh"
assert_exit_code "empty features/ → exit 0" 0 "$HOOK_EXIT"
assert_empty "empty features/ → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 3: one in_progress feature → emits reminder ---
setup_sandbox
write_progress "001-foo" "in_progress" "Step 1 — fixture" "Step 2 — implement at file.php:42"
run_hook "user-prompt-submit.sh"
assert_exit_code "in_progress → exit 0" 0 "$HOOK_EXIT"
assert_contains "in_progress → mentions slug" "$HOOK_STDOUT_TEXT" "001-foo"
assert_contains "in_progress → mentions next_action" "$HOOK_STDOUT_TEXT" "Step 2 — implement at file.php:42"
assert_contains "in_progress → mentions last_completed" "$HOOK_STDOUT_TEXT" "Step 1 — fixture"
assert_contains "in_progress → wraps in system-reminder" "$HOOK_STDOUT_TEXT" "<system-reminder>"
teardown_sandbox

# --- Case 4: completed feature → silent ---
setup_sandbox
write_progress "001-shipped" "complete"
run_hook "user-prompt-submit.sh"
assert_exit_code "complete → exit 0" 0 "$HOOK_EXIT"
assert_empty "complete → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 5: mix of statuses → picks the in_progress one ---
setup_sandbox
write_progress "001-done" "complete"
# Sleep a beat so mtimes differ; the active one must be newer.
sleep 1
write_progress "002-active" "in_progress" "Step 3" "Step 4"
run_hook "user-prompt-submit.sh"
assert_contains "mixed → picks active slug" "$HOOK_STDOUT_TEXT" "002-active"
assert_not_contains "mixed → ignores shipped slug" "$HOOK_STDOUT_TEXT" "001-done"
teardown_sandbox

# --- Case 6: completion synonyms (done, shipped, archived) → silent ---
for status in done shipped archived completed; do
  setup_sandbox
  write_progress "001-$status" "$status"
  run_hook "user-prompt-submit.sh"
  assert_empty "status=$status → no stdout" "$HOOK_STDOUT_TEXT"
  teardown_sandbox
done

# --- Case 7: weird whitespace / case in status → still detects complete ---
setup_sandbox
mkdir -p .claude/plans/features/001-weird
cat > .claude/plans/features/001-weird/progress.md <<EOF
# Progress

status:    COMPLETE

- last_completed: x
- next_action: y
- blockers: none
EOF
run_hook "user-prompt-submit.sh"
assert_empty "weird whitespace + uppercase → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 8: progress.md missing status: line → treated as active (fail-open) ---
setup_sandbox
mkdir -p .claude/plans/features/001-no-status
cat > .claude/plans/features/001-no-status/progress.md <<'EOF'
# Progress

- last_completed: alpha
- next_action: beta
- blockers: none
EOF
run_hook "user-prompt-submit.sh"
assert_contains "missing status: → treated as active" "$HOOK_STDOUT_TEXT" "001-no-status"
teardown_sandbox

# Hand back the counters to the runner.
exit $FAIL_COUNT
