#!/usr/bin/env bash
#
# Tests for .claude/hooks/lib.sh
#
# These exist because of a bug that was invisible on macOS and fatal on Linux:
# all three hooks derived a file's mtime with
#
#   stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0
#
# On BSD/macOS that is correct. On GNU/Linux `-f` means "file system status",
# so `%m` is parsed as a second FILE argument: GNU prints a six-line filesystem
# dump for $f, *then* exits 1 because no file named '%m' exists — so the
# fallback runs too and the capture ends up holding both. Arithmetic on that
# blob is a syntax error, the comparison quietly evaluates false, and every
# hook concluded there was no active feature. The planning layer was dead on
# Linux and green on the author's laptop.
#
# The assertions below are therefore about *shape*, not just value: mtime must
# be one line of digits and nothing else. That is what makes them catch this
# class of bug on whichever platform is broken, rather than restating what the
# implementation already does.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"
# shellcheck source=../../.claude/hooks/lib.sh
source "$KIT_ROOT/.claude/hooks/lib.sh"

echo "hooks/lib.sh"

# --- hook_mtime: shape ---
setup_sandbox
printf 'x\n' > file.txt

mtime=$(hook_mtime "file.txt")

if [[ "$mtime" =~ ^[0-9]+$ ]]; then
  _pass "hook_mtime → digits only"
else
  _fail "hook_mtime → digits only" "got $(printf %q "$mtime")"
fi

assert_equals "hook_mtime → exactly one line" "1" "$(printf '%s' "$mtime" | wc -l | tr -d ' ' | awk '{print $1+1}')"

if [[ "$mtime" -gt 0 ]] 2>/dev/null; then
  _pass "hook_mtime → non-zero for a real file"
else
  _fail "hook_mtime → non-zero for a real file" "got $(printf %q "$mtime")"
fi

# The bug's signature: filesystem trivia leaking into the value.
assert_not_contains "hook_mtime → no filesystem dump" "$mtime" "Block size"
assert_not_contains "hook_mtime → no file name echo" "$mtime" "File:"

# --- hook_mtime: usable in arithmetic ---
# This is the assertion that would have gone red on Linux before the fix.
newest=0
if (( $(hook_mtime "file.txt") > newest )) 2>/dev/null; then
  _pass "hook_mtime → survives arithmetic comparison"
else
  _fail "hook_mtime → survives arithmetic comparison" "(( )) rejected the value"
fi

# --- hook_mtime: missing file ---
assert_equals "hook_mtime → 0 for a missing file" "0" "$(hook_mtime "does-not-exist.txt")"
teardown_sandbox

# --- hook_is_complete ---
for status in complete completed done shipped archived COMPLETE "  done  "; do
  if hook_is_complete "$status"; then
    _pass "hook_is_complete → '$status' is complete"
  else
    _fail "hook_is_complete → '$status' is complete" "returned non-zero"
  fi
done

for status in in_progress blocked "" "not-done"; do
  if hook_is_complete "$status"; then
    _fail "hook_is_complete → '$status' is active" "treated as complete"
  else
    _pass "hook_is_complete → '$status' is active"
  fi
done

# --- hook_active_progress ---
setup_sandbox
assert_empty "hook_active_progress → empty features/ → nothing" "$(hook_active_progress)"

write_progress "001-only" "in_progress"
assert_contains "hook_active_progress → finds the single active feature" \
  "$(hook_active_progress)" "001-only"

write_progress "002-shipped" "complete"
assert_not_contains "hook_active_progress → skips complete" \
  "$(hook_active_progress)" "002-shipped"

sleep 1
write_progress "003-newer" "in_progress"
assert_contains "hook_active_progress → picks the newest active" \
  "$(hook_active_progress)" "003-newer"

assert_empty "hook_active_progress → missing dir → nothing" "$(hook_active_progress "no/such/dir")"
teardown_sandbox

exit $FAIL_COUNT
