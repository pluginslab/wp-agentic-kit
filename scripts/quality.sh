#!/usr/bin/env bash
#
# Full quality suite for the plugin.
#
# Single source of truth for "what does CI / a pre-commit check actually run."
# Called by:
#   - .claude/hooks/pre-commit.sh  (Claude Code commits)
#   - .git/hooks/pre-commit        (terminal / IDE commits, if you install it)
#   - CI                           (GitHub Actions, etc.)
#
# Each check is gated on the tool being installed in the project, so this
# script is benign on a fresh scaffold and gets stricter as you add tooling.
#
set -uo pipefail

echo "Quality suite running..." >&2

fail=0

if [[ -x "./vendor/bin/phpcs" && ( -f phpcs.xml || -f phpcs.xml.dist ) ]]; then
  echo "  - phpcs" >&2
  # No --standard here: the project phpcs.xml.dist already sets the standard
  # and the files to scan. Passing --standard would override it and drop the
  # ruleset's <file> list ("must supply at least one file or directory").
  ./vendor/bin/phpcs >&2 || fail=1
fi

if [[ -x "./vendor/bin/phpstan" ]]; then
  echo "  - phpstan" >&2
  ./vendor/bin/phpstan analyse --no-progress >&2 || fail=1
fi

if [[ -x "./node_modules/.bin/eslint" && -d "src" ]]; then
  echo "  - eslint" >&2
  ./node_modules/.bin/eslint src/ >&2 || fail=1
fi

if [[ -x "./node_modules/.bin/stylelint" && -d "src" ]]; then
  echo "  - stylelint" >&2
  ./node_modules/.bin/stylelint "src/**/*.{css,scss}" >&2 || fail=1
fi

# phpunit runs only once a config exists. The example test uses WP_UnitTestCase,
# which needs the WordPress test harness (wp-env). Until you add phpunit.xml(.dist)
# and that harness, this stays benign on a fresh scaffold instead of erroring.
if [[ -x "./vendor/bin/phpunit" && ( -f phpunit.xml || -f phpunit.xml.dist ) ]]; then
  echo "  - phpunit" >&2
  ./vendor/bin/phpunit >&2 || fail=1
fi

if [[ -x "./tests/run.sh" ]]; then
  echo "  - tests/run.sh (kit harness)" >&2
  ./tests/run.sh >&2 || fail=1
fi

if [[ $fail -ne 0 ]]; then
  echo "" >&2
  echo "Quality suite failed." >&2
  exit 1
fi

echo "Quality suite passed." >&2
exit 0
