#!/usr/bin/env bash
#
# Pre-commit gate
# Fires before any Bash invocation. Filters for `git commit` and runs the
# full quality suite. Exits non-zero to block the commit if anything fails.
#
# This is the deterministic safety net. CLAUDE.md says "run phpcs before
# committing" — this hook makes sure it actually happens regardless of
# what the agent remembers.
#
set -uo pipefail

# Parse the hook payload to extract the Bash command.
command=$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("command", ""))
except Exception:
    pass
')

# Only intercept git commits. Everything else passes through.
case "$command" in
  git\ commit*) ;;
  *) exit 0 ;;
esac

echo "Pre-commit quality gate running..." >&2

fail=0

# PHP — WordPress Coding Standards.
if [[ -x "./vendor/bin/phpcs" ]]; then
  echo "  - phpcs" >&2
  ./vendor/bin/phpcs --standard=WordPress >&2 || fail=1
fi

# PHP static analysis (optional).
if [[ -x "./vendor/bin/phpstan" ]]; then
  echo "  - phpstan" >&2
  ./vendor/bin/phpstan analyse --no-progress >&2 || fail=1
fi

# JS/CSS lint (only if the project has them).
if [[ -x "./node_modules/.bin/eslint" && -d "src" ]]; then
  echo "  - eslint" >&2
  ./node_modules/.bin/eslint src/ >&2 || fail=1
fi

if [[ -x "./node_modules/.bin/stylelint" && -d "src" ]]; then
  echo "  - stylelint" >&2
  ./node_modules/.bin/stylelint "src/**/*.{css,scss}" >&2 || fail=1
fi

# Tests — only PHPUnit, JS tests can be slow and noisy at commit time.
if [[ -x "./vendor/bin/phpunit" ]]; then
  echo "  - phpunit" >&2
  ./vendor/bin/phpunit >&2 || fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "" >&2
  echo "Quality gate failed. Fix the issues above, then commit again." >&2
  exit 1
fi

echo "Quality gate passed." >&2
exit 0
