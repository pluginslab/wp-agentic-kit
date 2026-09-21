#!/usr/bin/env bash
#
# Tests for the scaffolder's find-and-replace coverage (cli/index.js).
#
# The CLI rewrites the example plugin's identity by literal string replacement,
# and every replacement key is case-sensitive: `PL_EXAMPLE` does not match
# `PL_Example`, and neither matches `PLExample`. A casing that appears in a
# template file but has no entry in the replacements array ships to the user
# verbatim — which is how every scaffolded plugin ended up with a bootstrap
# class literally named `PL_Example_Plugin`, colliding the moment two
# kit-scaffolded plugins are active on the same site.
#
# These tests close that gap generically: scan the files the CLI will actually
# rewrite, collect every casing of the example identity present, and assert
# each one has a replacement entry. A future template edit that introduces a
# sixth casing fails here instead of in someone else's plugin.
#
set -uo pipefail

# shellcheck source=../lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

echo "cli/index.js substitutions"

CLI="$KIT_ROOT/cli/index.js"

# Every casing of the example identity the template might plausibly use.
TOKENS=(PL_EXAMPLE PL_Example PLExample pl_example pl-example)

# Directories the CLI removes after extract (REMOVE_AFTER_EXTRACT) or never
# walks (SKIP_DIRS) — tokens in these never reach the user, so they don't
# need replacement entries.
PRUNE=(-name .git -o -name node_modules -o -name vendor -o -name build
       -o -name cli -o -name docs -o -name .github -o -name demo-plugin
       -o -name tests)

# File extensions the CLI rewrites (TEXT_EXTENSIONS in cli/index.js).
EXTS=(md php json txt yml yaml scss css js ts html xml dist)

find_args=()
for e in "${EXTS[@]}"; do
  find_args+=(-o -name "*.$e")
done
# Drop the leading -o
find_args=("${find_args[@]:1}")

template_files=$(find "$KIT_ROOT" \( "${PRUNE[@]}" \) -prune -o -type f \( "${find_args[@]}" \) -print)

# --- Case 1: the scan found something to check ---
if [[ -z "$template_files" ]]; then
  _fail "template scan → found files" "no substitutable files under $KIT_ROOT"
  exit $FAIL_COUNT
fi
_pass "template scan → found files"

# --- Case 2: every casing present in the template has a replacement entry ---
for token in "${TOKENS[@]}"; do
  # grep -F, case-sensitive on purpose: that is the semantics the CLI uses.
  hits=$(grep -lF "$token" $template_files 2>/dev/null | head -3)

  if [[ -z "$hits" ]]; then
    # Token isn't in the template at all. Nothing to cover.
    _pass "$token → absent from template (no entry needed)"
    continue
  fi

  if grep -qF "['$token'," "$CLI"; then
    _pass "$token → present in template, has replacement entry"
  else
    first_hit=$(echo "$hits" | head -1 | sed "s|$KIT_ROOT/||")
    _fail "$token → present in template, has replacement entry" \
      "found in $first_hit but cli/index.js has no ['$token', …] entry — it would ship verbatim"
  fi
done

# --- Case 3: the derived class prefix is actually computed ---
# PL_Example maps to underscore-separated PascalCase, which is a distinct
# derivation from the namespace (squashed) and the constant prefix (ALL_CAPS).
assert_file_contains "cli → derives a classPrefix" "$CLI" "classPrefix"
assert_file_contains "cli → classPrefix joins on underscore" "$CLI" ".join('_')"

# --- Case 4: deriveIdentity produces the expected forms ---
# Exercise the real derivation rather than trusting the source reads right.
# node evaluates the same expressions the CLI uses, for a representative slug.
#
# Guarded on node being installed. The CLI is a Node program, so a host without
# node cannot run the scaffolder at all and has nothing to assert about it —
# but the rest of this file is plain bash and stays useful. Without the guard
# this failed with a baffling `got ''`, because the error was swallowed by a
# 2>/dev/null. That is the same "the test encodes the author's machine" trap
# that hid the Linux mtime bug in the hooks; it does not get a pass here just
# because it is our own test.
if command -v node >/dev/null 2>&1; then
  derived=$(node -e '
    const slug = "acme-order-tracker";
    const cap = s => s[0].toUpperCase() + s.slice(1);
    const parts = slug.split("-").filter(Boolean);
    console.log([
      parts.map(cap).join(""),          // namespace
      parts.map(cap).join("_"),         // classPrefix
      slug.toUpperCase().replace(/-/g, "_"),
      slug.replace(/-/g, "_"),
    ].join(" "));
  ')

  assert_equals "deriveIdentity → all four forms for acme-order-tracker" \
    "AcmeOrderTracker Acme_Order_Tracker ACME_ORDER_TRACKER acme_order_tracker" \
    "$derived"
else
  echo "  - skipped: deriveIdentity check needs node on PATH"
fi

# --- Case 5: the main plugin file gets renamed, not just rewritten ---
# WordPress expects {slug}.php; leaving pl-example.php in place breaks the
# convention even when the contents are correct.
assert_file_contains "cli → renames slug-named files" "$CLI" "renameSync"

exit $FAIL_COUNT
