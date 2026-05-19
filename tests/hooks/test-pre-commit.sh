#!/usr/bin/env bash
#
# Tests for .claude/hooks/pre-commit.sh
#
# The hook filters Bash invocations and only acts on `git commit`. We test:
#   1. non-commit Bash → exit 0 (passthrough)
#   2. git commit + no scripts/quality.sh → exit 0 with warning (skip gate)
#   3. git commit + passing quality.sh → exit 0
#   4. git commit + failing quality.sh → exit 1 (block)
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "pre-commit.sh"

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

# --- Case 3: git commit but no scripts/quality.sh → exit 0 with warning ---
setup_sandbox
run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m foo"}}'
assert_exit_code "git commit, no quality.sh → exit 0" 0 "$HOOK_EXIT"
assert_contains "git commit, no quality.sh → warns on stderr" \
  "$HOOK_STDERR_TEXT" "quality.sh missing"
teardown_sandbox

# --- Case 4: git commit + passing quality.sh → exit 0 ---
setup_sandbox
mkdir -p scripts
cat > scripts/quality.sh <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x scripts/quality.sh
run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m feat"}}'
assert_exit_code "git commit, quality pass → exit 0" 0 "$HOOK_EXIT"
teardown_sandbox

# --- Case 5: git commit + failing quality.sh → exit 1 (blocks commit) ---
setup_sandbox
mkdir -p scripts
cat > scripts/quality.sh <<'EOF'
#!/usr/bin/env bash
echo "phpcs found 1 error" >&2
exit 1
EOF
chmod +x scripts/quality.sh
run_hook "pre-commit.sh" '{"tool_input":{"command":"git commit -m bad"}}'
assert_exit_code "git commit, quality fail → exit 1" 1 "$HOOK_EXIT"
assert_contains "git commit, quality fail → block message" \
  "$HOOK_STDERR_TEXT" "Commit blocked"
teardown_sandbox

exit $FAIL_COUNT
