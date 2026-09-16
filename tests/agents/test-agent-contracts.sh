#!/usr/bin/env bash
#
# Tests for .claude/agents/*.md
#
# The kit's sub-agents are read-only by design, and that guarantee is enforced
# by the `tools:` allowlist in each file's frontmatter — not by the prompt body.
# A prompt saying "you do not modify code" is advisory; omitting Edit/Write is
# structural. These tests verify the structural half, so a future edit can't
# quietly hand an auditor write access.
#
# Also checks the things that silently break invocation: a `name:` that doesn't
# match the filename, a missing `description:` (the main agent matches intent
# against it), and skills that dispatch an agent which doesn't exist.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "agents/*.md"

AGENTS_DIR="$KIT_ROOT/.claude/agents"

# Tools that can mutate the working tree. No kit sub-agent may declare one.
WRITE_TOOLS=(Edit Write MultiEdit NotebookEdit)

# Read one frontmatter key from an agent file. Frontmatter is the block between
# the first two `---` lines; we stop there so a mention in the body can't be
# mistaken for a declaration.
frontmatter_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---"    { exit }
    infm && index($0, key ":") == 1 {
      sub("^" key ": *", "")
      print
      exit
    }
  ' "$file"
}

# --- Case 1: the directory exists and has agents in it ---
agent_files=$(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' ! -name 'README.md' -type f | sort)

if [[ -z "$agent_files" ]]; then
  _fail "agents dir → contains at least one agent" "no *.md files under $AGENTS_DIR"
  exit $FAIL_COUNT
fi
_pass "agents dir → contains at least one agent"

# --- Case 2: per-agent frontmatter contract ---
for file in $agent_files; do
  base=$(basename "$file" .md)

  name=$(frontmatter_value "$file" "name")
  desc=$(frontmatter_value "$file" "description")
  tools=$(frontmatter_value "$file" "tools")

  assert_equals "$base → name matches filename" "$base" "$name"

  if [[ -n "$desc" ]]; then
    _pass "$base → has description"
  else
    _fail "$base → has description" "frontmatter has no description:"
  fi

  if [[ -n "$tools" ]]; then
    _pass "$base → declares tools"
  else
    _fail "$base → declares tools" "frontmatter has no tools: (inherits everything, including Edit)"
  fi

  # The load-bearing assertion: no write tool in the allowlist.
  for tool in "${WRITE_TOOLS[@]}"; do
    # Match the tool as a whole comma-separated entry, not as a substring —
    # "Write" must not match inside a hypothetical "WriteReport".
    if [[ ",${tools// /}," == *",$tool,"* ]]; then
      _fail "$base → read-only (no $tool)" "tools: declares $tool"
    else
      _pass "$base → read-only (no $tool)"
    fi
  done
done

# --- Case 3: playground-verifier holds the tools it needs to do its job ---
# It is the kit's only runtime gate; without wp-playground access it silently
# degrades into a worse security-reviewer.
pv="$AGENTS_DIR/playground-verifier.md"
if [[ -f "$pv" ]]; then
  pv_tools=$(frontmatter_value "$pv" "tools")
  for required in start_playground stop_playground wp_cli get_playground_logs; do
    assert_contains "playground-verifier → can $required" "$pv_tools" "mcp__wp-playground__$required"
  done
  # Tearing the instance down is not optional: only one can run at a time, so a
  # leaked instance breaks the *next* run, not this one.
  assert_file_contains "playground-verifier → documents teardown" "$pv" "stop_playground"
  assert_file_contains "playground-verifier → boots at declared minimums" "$pv" "Requires at least"

  # The two false-pass traps, found by running the agent for real against
  # pl-example. Both let the agent report "clean" on a broken plugin, so they
  # are pinned here: a future edit that drops the warning reintroduces a gate
  # that cannot fail.
  #
  #   1. get_playground_logs surfaces the Node process's output, NOT PHP errors.
  #      PHP diagnostics land in wp-content/debug.log and are invisible to it.
  #   2. Playground's auto-login mu-plugin 302-redirects cookie-less requests,
  #      so the unauthenticated-REST check can't run without the suppression
  #      cookie — it silently proves nothing instead of failing loudly.
  assert_file_contains "playground-verifier → reads debug.log for PHP errors" "$pv" "debug.log"
  assert_file_contains "playground-verifier → warns get_playground_logs misses PHP errors" \
    "$pv" "does not show PHP errors"
  assert_file_contains "playground-verifier → probes that logging is on" "$pv" "PLAYGROUND-LOG-PROBE-DELIBERATE"
  assert_file_contains "playground-verifier → documents the auto-login trap" \
    "$pv" "playground_auto_login_already_happened"
  assert_file_contains "playground-verifier → confirms versions from inside" "$pv" "PHP_VERSION"
  # `wp plugin uninstall` is not implemented by the MCP bridge; the agent must
  # know the uninstall_plugin() substitute or the uninstall stage can't run.
  assert_file_contains "playground-verifier → knows the uninstall substitute" "$pv" "uninstall_plugin("

  # Third false-pass trap, from the second live run: WP_DEBUG_DISPLAY defaults
  # to false in Playground, so the "notices in the page body" check can never
  # fire unless the blueprint turns it on. It looked like a pass; it was a no-op.
  assert_file_contains "playground-verifier → enables WP_DEBUG_DISPLAY" "$pv" "WP_DEBUG_DISPLAY"
  # The fresh-clone reproduction is the check that catches deploy-time fatals.
  # Deriving the exclusion list by hand drifts from .gitignore; git archive
  # ships exactly the tracked files by definition.
  assert_file_contains "playground-verifier → clones via git archive" "$pv" "git -C <repo> archive"
else
  _fail "playground-verifier → exists" "no $pv"
fi

# --- Case 4: every agent a skill dispatches actually exists ---
# A skill naming a sub-agent that isn't on disk fails at the worst moment —
# mid-ship, after the work is done.
for skill in "$KIT_ROOT"/.claude/skills/*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  skill_name=$(basename "$(dirname "$skill")")
  for agent in plan-reviewer security-reviewer playground-verifier; do
    if grep -qF "$agent" "$skill"; then
      if [[ -f "$AGENTS_DIR/$agent.md" ]]; then
        _pass "$skill_name → dispatches $agent, which exists"
      else
        _fail "$skill_name → dispatches $agent, which exists" "$AGENTS_DIR/$agent.md missing"
      fi
    fi
  done
done

# --- Case 5: the wp-playground MCP server is actually configured ---
# The agent's tool allowlist is meaningless if the server isn't in .mcp.json.
assert_file_contains "mcp config → declares wp-playground" "$KIT_ROOT/.mcp.json" "wp-playground"
assert_file_contains "settings → permits wp-playground" "$KIT_ROOT/.claude/settings.json" "mcp__wp-playground"

exit $FAIL_COUNT
