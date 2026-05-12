#!/usr/bin/env bash
#
# wp-agentic-kit setup
# Run once after cloning. Replaces "Example Plugin" example values with yours
# across every file in the kit.
#
set -euo pipefail

echo "wp-agentic-kit setup"
echo "===================="
echo ""
echo "This will replace the example values across the kit:"
echo "  Example Plugin · pl-example · PLExample · PL_EXAMPLE_* · pl_example_*"
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

# --- summary + confirm ---
cat <<EOF

Generated values:
  Plugin name:        $PLUGIN_NAME
  Slug:               $SLUG
  Namespace:          $NAMESPACE
  Constant prefix:    $CONST_PREFIX
  Function prefix:    $FN_PREFIX

EOF
read -p "Proceed with find/replace? [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted. Nothing changed."
  exit 0
fi

# --- portable sed -i ---
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"            # GNU
  else
    sed -i '' "$@"         # BSD / macOS
  fi
}

# --- find files to touch ---
files=$(grep -rl \
  --include='*.md' --include='*.php' --include='*.json' \
  --include='*.txt' --include='*.yml' --include='*.yaml' \
  -e 'Example Plugin' -e 'pl-example' -e 'PLExample' \
  -e 'PL_EXAMPLE' -e 'pl_example' \
  . 2>/dev/null \
  | grep -v "^\./setup\.sh$" \
  | grep -v "/\.git/" \
  | grep -v "/vendor/" \
  | grep -v "/node_modules/" \
  || true)

if [[ -z "$files" ]]; then
  echo "No example values found in the repo. Already customized?"
  exit 0
fi

# --- replace (order matters: longer / more specific first) ---
count=0
while IFS= read -r f; do
  sed_inplace "s/PL_EXAMPLE/$CONST_PREFIX/g" "$f"
  sed_inplace "s/PLExample/$NAMESPACE/g" "$f"
  sed_inplace "s/pl_example/$FN_PREFIX/g" "$f"
  sed_inplace "s/pl-example/$SLUG/g" "$f"
  sed_inplace "s/Example Plugin/$PLUGIN_NAME/g" "$f"
  count=$((count+1))
done <<< "$files"

echo ""
echo "Replaced example values across $count file(s)."
echo ""
echo "Next steps:"
echo "  1. Review the diff:    git diff"
echo "  2. Commit:             git add -A && git commit -m 'init: customize wp-agentic-kit'"
echo "  3. Remove this script: rm setup.sh"
