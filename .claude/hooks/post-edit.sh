#!/usr/bin/env bash
#
# Post-edit lint
# Fires after Edit / Write / MultiEdit. Lints just the file that was
# edited (read from the hook payload) and surfaces output to stderr.
# Never blocks — the agent may still be mid-task.
#
set -uo pipefail

file_path=$(python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
')

[[ -z "$file_path" || ! -f "$file_path" ]] && exit 0

case "$file_path" in
  *.php)
    [[ -x "./vendor/bin/phpcs" ]] && \
      ./vendor/bin/phpcs --standard=WordPress --report=summary "$file_path" >&2 || true
    ;;
  *.js|*.ts|*.jsx|*.tsx)
    [[ -x "./node_modules/.bin/eslint" ]] && \
      ./node_modules/.bin/eslint "$file_path" >&2 || true
    ;;
  *.scss|*.css)
    [[ -x "./node_modules/.bin/stylelint" ]] && \
      ./node_modules/.bin/stylelint "$file_path" >&2 || true
    ;;
esac

exit 0
