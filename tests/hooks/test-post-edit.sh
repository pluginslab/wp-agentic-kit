#!/usr/bin/env bash
#
# Tests for .claude/hooks/post-edit.sh
#
# The hook reads tool_input.file_path from JSON on stdin and lints. We can
# verify the input handling (missing path → exit 0, nonexistent file → exit
# 0) without needing phpcs/eslint installed. The actual lint dispatch is
# tested implicitly by checking the hook doesn't crash on either path.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "post-edit.sh"

# --- Case 1: empty payload → exit 0, silent ---
setup_sandbox
run_hook "post-edit.sh" ""
assert_exit_code "empty payload → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 2: payload with no file_path field → exit 0 ---
setup_sandbox
run_hook "post-edit.sh" '{"tool_name":"Edit","tool_input":{}}'
assert_exit_code "missing file_path → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 3: file_path points to nonexistent file → exit 0 ---
setup_sandbox
run_hook "post-edit.sh" '{"tool_input":{"file_path":"/tmp/does-not-exist.php"}}'
assert_exit_code "missing file → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 4: real PHP file but no phpcs installed → exit 0 (silent skip) ---
setup_sandbox
echo "<?php echo 1; ?>" > sample.php
run_hook "post-edit.sh" "{\"tool_input\":{\"file_path\":\"$SANDBOX/sample.php\"}}"
assert_exit_code "real PHP, no phpcs → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 5: real JS file, no eslint installed → exit 0 ---
setup_sandbox
echo "const x = 1;" > sample.js
run_hook "post-edit.sh" "{\"tool_input\":{\"file_path\":\"$SANDBOX/sample.js\"}}"
assert_exit_code "real JS, no eslint → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 6: unknown extension → exit 0 (no linter selected) ---
setup_sandbox
echo "hello" > sample.txt
run_hook "post-edit.sh" "{\"tool_input\":{\"file_path\":\"$SANDBOX/sample.txt\"}}"
assert_exit_code "unknown ext → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

exit $FAIL_COUNT
