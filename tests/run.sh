#!/usr/bin/env bash
#
# tests/run.sh — run every test under tests/hooks/ (and any future layer).
# Returns non-zero if any test fails.
#
# Usage:
#   ./tests/run.sh              # run all
#   ./tests/run.sh hooks        # run just one layer
#   ./tests/run.sh hooks/test-stop.sh   # run one file
#
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

filter="${1:-}"

# Discover test files. By default everything under tests/**/test-*.sh.
if [[ -n "$filter" ]]; then
  files=$(find "tests/$filter" -name 'test-*.sh' -type f 2>/dev/null | sort)
else
  files=$(find tests -name 'test-*.sh' -type f | sort)
fi

if [[ -z "$files" ]]; then
  echo "No tests found." >&2
  exit 2
fi

total_pass=0
total_fail=0
file_failures=0

for file in $files; do
  # Run in a subshell so per-test traps + cwd don't leak.
  output=$(bash "$file" 2>&1)
  exit_code=$?

  echo "$output"
  echo ""

  # Tally the ✓ and ✗ lines.
  pass=$(echo "$output" | grep -c '✓' || true)
  fail=$(echo "$output" | grep -c '✗' || true)
  total_pass=$((total_pass + pass))
  total_fail=$((total_fail + fail))

  if (( exit_code != 0 )); then
    file_failures=$((file_failures + 1))
  fi
done

echo "──────────────────────────────────────"
printf "Summary: \033[32m%d passed\033[0m" "$total_pass"
if (( total_fail > 0 )); then
  printf ", \033[31m%d failed\033[0m" "$total_fail"
fi
echo " (${file_failures} test file(s) with failures)"

if (( total_fail > 0 || file_failures > 0 )); then
  exit 1
fi
exit 0
