#!/usr/bin/env bash
#
# wp-agentic-kit setup
# Scaffolds the kit into a target directory, then renames the "Example Plugin"
# placeholders with values you provide. The kit repo itself stays clean.
#
# Usage:
#   ./setup.sh <target-dir>
#
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $(basename "$0") <target-dir>

Copies the kit into <target-dir> and renames the "Example Plugin"
placeholders to your plugin's identity. The target is created if it
doesn't exist. If it exists, it must be empty.

Example:
  $(basename "$0") ../demo-plugin
EOF
}

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

TARGET_INPUT="$1"
mkdir -p "$TARGET_INPUT"
TARGET_DIR="$(cd "$TARGET_INPUT" && pwd)"

if [[ "$TARGET_DIR" == "$KIT_DIR" ]]; then
  echo "Refusing to scaffold into the kit itself. Pick a different target." >&2
  exit 1
fi

if [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
  echo "Target '$TARGET_DIR' is not empty. Aborting to avoid overwriting." >&2
  exit 1
fi

echo "wp-agentic-kit setup"
echo "===================="
echo ""
echo "Source: $KIT_DIR"
echo "Target: $TARGET_DIR"
echo ""

# --- inputs ---
read -p "Plugin name (e.g. 'My Cool Plugin'): " PLUGIN_NAME
if [[ -z "$PLUGIN_NAME" ]]; then
  echo "Plugin name is required." >&2
  exit 1
fi

read -p "Vendor prefix (optional, e.g. 'pl', 'acme'; press Enter to skip): " VENDOR_PREFIX

# --- derive slug ---
slug_base=$(echo "$PLUGIN_NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g')
if [[ -n "$VENDOR_PREFIX" ]]; then
  SLUG="${VENDOR_PREFIX}-${slug_base}"
else
  SLUG="$slug_base"
fi

# --- derive namespace (PascalCase per segment) ---
NAMESPACE=$(echo "$SLUG" | awk -F- '{
  for (i = 1; i <= NF; i++)
    printf "%s", toupper(substr($i,1,1)) substr($i,2)
}')

# --- derive constant / function prefixes ---
CONST_PREFIX=$(echo "$SLUG" | tr 'a-z-' 'A-Z_')
FN_PREFIX=$(echo "$SLUG" | tr '-' '_')

cat <<EOF

Generated values:
  Plugin name:        $PLUGIN_NAME
  Slug:               $SLUG
  Namespace:          $NAMESPACE
  Constant prefix:    $CONST_PREFIX
  Function prefix:    $FN_PREFIX

EOF
read -p "Scaffold the kit into $TARGET_DIR with these values? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted. Nothing changed."
  exit 0
fi

# --- copy kit into target (rsync if available, fall back to cp) ---
# Excludes: .git/ (fresh history in target), setup.sh (kit-only),
# LICENSE (the new plugin picks its own).
if command -v rsync >/dev/null; then
  rsync -a \
    --exclude='.git/' \
    --exclude='setup.sh' \
    --exclude='LICENSE' \
    "$KIT_DIR/" "$TARGET_DIR/"
else
  ( cd "$KIT_DIR" && tar --exclude='./.git' --exclude='./setup.sh' --exclude='./LICENSE' -cf - . ) \
    | ( cd "$TARGET_DIR" && tar -xf - )
fi

# --- portable sed -i ---
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"            # GNU
  else
    sed -i '' "$@"         # BSD / macOS
  fi
}

# --- find files in target with placeholders ---
files=$(cd "$TARGET_DIR" && grep -rl \
  --include='*.md' --include='*.php' --include='*.json' \
  --include='*.txt' --include='*.yml' --include='*.yaml' \
  -e 'Example Plugin' -e 'pl-example' -e 'PLExample' \
  -e 'PL_EXAMPLE' -e 'pl_example' \
  . 2>/dev/null \
  | grep -v "/\.git/" \
  | grep -v "/vendor/" \
  | grep -v "/node_modules/" \
  || true)

if [[ -z "$files" ]]; then
  echo "Warning: no placeholder values found in the copied kit."
  exit 0
fi

# --- replace (order matters: longer / more specific first) ---
count=0
while IFS= read -r f; do
  abs="$TARGET_DIR/${f#./}"
  sed_inplace "s/PL_EXAMPLE/$CONST_PREFIX/g" "$abs"
  sed_inplace "s/PLExample/$NAMESPACE/g" "$abs"
  sed_inplace "s/pl_example/$FN_PREFIX/g" "$abs"
  sed_inplace "s/pl-example/$SLUG/g" "$abs"
  sed_inplace "s/Example Plugin/$PLUGIN_NAME/g" "$abs"
  count=$((count+1))
done <<< "$files"

# --- strip kit-meta HTML comments from CLAUDE.md / AGENTS.md ---
# The kit's own instruction blocks are HTML comments; they're explicitly
# marked as "strip before shipping". Use perl for portable multi-line edit.
if command -v perl >/dev/null; then
  for meta in "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/AGENTS.md"; do
    [[ -f "$meta" ]] && perl -i -0pe 's/<!--.*?-->\s*//gs' "$meta"
  done
fi

# --- top up the wp-devdocs index with sources newer than the base bake ---
# The container image ships pre-indexed with the 8 standard WordPress sources
# (wp-core, gutenberg, plugin-handbook, etc.). This step adds the genuinely
# fresh stuff — WP 7.0 AI Client, Abilities API — so /talk:mcp-devdocs has
# canonical signatures to look up. Backgrounded so we don't block the demo;
# narrate "indexing in the background, ready by the time we need it."
if command -v npx >/dev/null; then
  (
    echo ""
    echo "Indexing fresh WP 7.0 sources (background)..."
    npx -y -p wp-devdocs-mcp wp-hooks source:add \
      --name=wp-ai-client \
      --type=github-public \
      --repo=https://github.com/WordPress/wp-ai-client \
      --branch=trunk \
      --content-type=source \
      --no-index 2>/dev/null || true
    npx -y -p wp-devdocs-mcp wp-hooks source:add \
      --name=abilities-api \
      --type=github-public \
      --repo=https://github.com/WordPress/abilities-api \
      --branch=trunk \
      --content-type=source \
      --no-index 2>/dev/null || true
    npx -y -p wp-devdocs-mcp wp-hooks index 2>&1 | tail -5
    echo "wp-devdocs ready."
  ) > "/tmp/setup-index-${SLUG}.log" 2>&1 &
  echo "(indexing pid=$!; tail /tmp/setup-index-${SLUG}.log to follow)"
fi

# --- fresh git history in the scaffold ---
# Tags the initial commit `scaffold` so reset.sh / dry-run helpers have a
# stable anchor to roll back to.
if [[ ! -d "$TARGET_DIR/.git" ]] && command -v git >/dev/null; then
  ( cd "$TARGET_DIR" \
    && git init -q \
    && git add -A \
    && git -c user.email=scaffold@local -c user.name=scaffold \
         commit -q -m "init: scaffold $SLUG from wp-agentic-kit" \
    && git tag scaffold ) || true
fi

echo ""
echo "Scaffolded $count file(s) into $TARGET_DIR"
echo ""
echo "Next:"
echo "  cd $TARGET_DIR"
echo "  claude        # start coding with the harness loaded"
