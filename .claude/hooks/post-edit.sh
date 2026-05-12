#!/usr/bin/env bash
#
# Post-edit lint
# Fires after the agent calls Edit or Write. Lints the modified files and
# surfaces any issues to the agent via stderr. Never blocks — the agent
# may still be mid-task and can fix lints on the next pass.
#
set -uo pipefail

# Files changed since the last commit (or all changes if no commits yet).
changed=$(git status --porcelain 2>/dev/null | awk '{print $2}')

[[ -z "$changed" ]] && exit 0

print() { printf '%s\n' "$*" >&2; }

run_phpcs() {
  if [[ -x "./vendor/bin/phpcs" ]]; then
    ./vendor/bin/phpcs --standard=WordPress --report=summary "$1" >&2 || true
  fi
}

run_eslint() {
  if [[ -x "./node_modules/.bin/eslint" ]]; then
    ./node_modules/.bin/eslint "$1" >&2 || true
  fi
}

run_stylelint() {
  if [[ -x "./node_modules/.bin/stylelint" ]]; then
    ./node_modules/.bin/stylelint "$1" >&2 || true
  fi
}

for f in $changed; do
  [[ ! -f "$f" ]] && continue
  case "$f" in
    *.php)             run_phpcs "$f" ;;
    *.js|*.ts|*.jsx|*.tsx)  run_eslint "$f" ;;
    *.scss|*.css)      run_stylelint "$f" ;;
  esac
done

exit 0
