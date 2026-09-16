#!/usr/bin/env bash
#
# Shared helpers for the kit's hooks.
#
# `session-start.sh`, `user-prompt-submit.sh` and `stop.sh` all need the same
# answer to the same question: which feature is active right now? That logic
# used to be copy-pasted into all three, with a comment in stop.sh asking the
# reader to keep them "in lockstep" by hand. They drifted the moment anyone
# touched one — and worse, they carried an identical portability bug that made
# every one of them silently no-op on Linux. One definition now.
#
# Sourced, not executed. No side effects at source time beyond defining
# functions and probing which `stat` this machine has.

# --- Portable mtime -----------------------------------------------------
#
# GNU and BSD `stat` disagree, and the disagreement is not a clean failure you
# can paper over with `||`.
#
# BSD/macOS:  `stat -f %m FILE`  -> epoch mtime.
# GNU/Linux:  `-f` means "file system status", so `%m` is not a format string,
#             it is parsed as a SECOND FILE argument. GNU prints a six-line
#             filesystem dump for FILE, then exits 1 because no file named
#             '%m' exists.
#
# So the obvious chain — `stat -f %m "$f" || stat -c %Y "$f"` — does the worst
# possible thing on Linux: the first command half-succeeds (dumping filesystem
# trivia to stdout) *and* returns 1, so the fallback runs too, and command
# substitution captures both. The result is six lines of "Block size: ..."
# with the real epoch stuck on the end. Any arithmetic on that is a syntax
# error, the comparison silently evaluates false, and the caller concludes
# there is no active feature.
#
# Probe once, bind the right implementation, and validate the output is
# actually numeric so no future platform can reintroduce this class of bug.
if stat -c %Y . >/dev/null 2>&1; then
  _hook_stat_mtime() { stat -c %Y "$1" 2>/dev/null; }
else
  _hook_stat_mtime() { stat -f %m "$1" 2>/dev/null; }
fi

# hook_mtime <file> -> epoch seconds, or 0 if unavailable.
# Guaranteed to print a non-negative integer and nothing else.
hook_mtime() {
  local m
  m=$(_hook_stat_mtime "$1") || m=''
  [[ "$m" =~ ^[0-9]+$ ]] || m=0
  printf '%s' "$m"
}

# --- Active feature -----------------------------------------------------

# hook_is_complete <status> -> 0 if the status means "finished".
# Tolerates whitespace, case, and the synonyms people actually type.
hook_is_complete() {
  local status
  status=$(printf '%s' "${1:-}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
  case "$status" in
    complete|completed|done|shipped|archived) return 0 ;;
    *) return 1 ;;
  esac
}

# hook_active_progress [plans_dir] -> path to the most recently modified
# progress.md that is not marked complete. Prints nothing if there is none.
#
# Shipped features get moved to .claude/plans/archive/, so anything still
# under features/ with a completion status is excluded deliberately.
hook_active_progress() {
  local plans_dir="${1:-.claude/plans/features}"
  local active='' newest=0 progress status mtime

  [[ -d "$plans_dir" ]] || return 0

  while IFS= read -r -d '' progress; do
    status=$(grep -m1 '^status:' "$progress" 2>/dev/null | sed 's/^status: *//')
    if hook_is_complete "$status"; then
      continue
    fi
    mtime=$(hook_mtime "$progress")
    if (( mtime > newest )); then
      newest=$mtime
      active="$progress"
    fi
  done < <(find "$plans_dir" -mindepth 2 -maxdepth 2 -name progress.md -print0 2>/dev/null)

  [[ -n "$active" ]] && printf '%s' "$active"
  return 0
}
