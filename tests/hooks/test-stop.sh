#!/usr/bin/env bash
#
# Tests for .claude/hooks/stop.sh
#
# Verifies the hook bumps last_updated on the active feature, inserts the
# line if missing, leaves completed features alone, and stays silent when
# there's nothing to update.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "stop.sh"

# --- Case 1: no .claude/plans/ → silent, no file mod ---
setup_sandbox
rm -rf .claude
run_hook "stop.sh"
assert_exit_code "no .claude dir → exit 0" 0 "$HOOK_EXIT"
assert_empty "no .claude dir → no stdout" "$HOOK_STDOUT_TEXT"
teardown_sandbox

# --- Case 2: active feature with existing last_updated → timestamp bumped ---
setup_sandbox
write_progress "001-active" "in_progress"
# Force a known-old timestamp.
sed -i.bak 's/^last_updated:.*/last_updated: 1999-01-01 00:00/' .claude/plans/features/001-active/progress.md
rm -f .claude/plans/features/001-active/progress.md.bak
run_hook "stop.sh"
assert_exit_code "active feature → exit 0" 0 "$HOOK_EXIT"
# The new timestamp should match today's year (YYYY-MM-DD).
year=$(date +%Y)
assert_file_contains "active feature → last_updated reflects today" \
  .claude/plans/features/001-active/progress.md "last_updated: $year"
# Old marker must be gone.
if grep -q "last_updated: 1999-01-01" .claude/plans/features/001-active/progress.md; then
  _fail "active feature → old timestamp removed" "still contains 1999-01-01"
else
  _pass "active feature → old timestamp removed"
fi
teardown_sandbox

# --- Case 3: progress.md missing last_updated line → line inserted after status: ---
setup_sandbox
mkdir -p .claude/plans/features/001-bare
cat > .claude/plans/features/001-bare/progress.md <<'EOF'
# Progress

status: in_progress

- last_completed: x
- next_action: y
- blockers: none
EOF
run_hook "stop.sh"
assert_file_contains "missing last_updated → line inserted" \
  .claude/plans/features/001-bare/progress.md "last_updated:"
teardown_sandbox

# --- Case 4: completed feature → no mod ---
setup_sandbox
write_progress "001-done" "complete"
before=$(cat .claude/plans/features/001-done/progress.md)
run_hook "stop.sh"
after=$(cat .claude/plans/features/001-done/progress.md)
assert_equals "complete feature → file unchanged" "$before" "$after"
teardown_sandbox

# --- Case 5: multiple features → only most-recent active one is touched ---
setup_sandbox
write_progress "001-old" "in_progress"
sleep 1
write_progress "002-newer" "in_progress"
# Mark both with the same old stamp; we should only touch the newer one.
sed -i.bak 's/^last_updated:.*/last_updated: 1999-01-01 00:00/' \
  .claude/plans/features/001-old/progress.md \
  .claude/plans/features/002-newer/progress.md
rm -f .claude/plans/features/001-old/progress.md.bak .claude/plans/features/002-newer/progress.md.bak
# Touch 002-newer to make it the newest mtime again (sed changed both).
touch .claude/plans/features/002-newer/progress.md
run_hook "stop.sh"
assert_file_contains "multi-feature → newer touched" \
  .claude/plans/features/002-newer/progress.md "last_updated: $(date +%Y)"
if grep -q "last_updated: 1999-01-01" .claude/plans/features/001-old/progress.md; then
  _pass "multi-feature → older untouched"
else
  _fail "multi-feature → older untouched" "older feature's timestamp changed unexpectedly"
fi
teardown_sandbox

exit $FAIL_COUNT
