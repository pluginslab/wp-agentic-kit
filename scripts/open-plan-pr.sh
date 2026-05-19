#!/usr/bin/env bash
#
# open-plan-pr.sh — automate the "plan freeze" step.
#
# Given a feature slug (e.g. 001-order-status-block):
#   1. Verify the feature dir exists and has spec.md + plan.md.
#   2. Verify working tree is clean except for those files.
#   3. Create branch plan/NNN-feature-slug from current HEAD.
#   4. Commit only the plan artifacts.
#   5. Push the branch.
#   6. Open a PR with gh, titled `plan: NNN-feature-slug`, body =
#      the spec's "What" + the plan's "Approach" sections.
#   7. Print the PR URL.
#
# Requirements:
#   - GitHub. The script uses `gh pr create`. For GitLab / Bitbucket / a
#     local-only Git, replace this script with one that calls the
#     equivalent CLI (`glab mr create`, `bb pr create`, …) or run the
#     plan-freeze steps by hand.
#   - `gh` CLI authenticated against the repo's host.
#   - `git` configured with a remote named `origin` that can accept pushes.
#
# Usage: ./scripts/open-plan-pr.sh NNN-feature-slug
#
set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "Usage: $0 NNN-feature-slug" >&2
  exit 2
fi

feature_dir=".claude/plans/features/$slug"
spec="$feature_dir/spec.md"
plan="$feature_dir/plan.md"

if [[ ! -d "$feature_dir" ]]; then
  echo "Feature dir not found: $feature_dir" >&2
  exit 1
fi
if [[ ! -f "$spec" || ! -f "$plan" ]]; then
  echo "Missing spec.md or plan.md in $feature_dir" >&2
  exit 1
fi

# Refuse to run if anything outside the feature dir is staged or modified.
dirty=$(git status --porcelain | grep -v "^.. $feature_dir/" || true)
if [[ -n "$dirty" ]]; then
  echo "Working tree has changes outside $feature_dir:" >&2
  echo "$dirty" >&2
  echo "Commit or stash them before opening the plan PR." >&2
  exit 1
fi

# Tools
command -v gh >/dev/null || { echo "gh CLI required" >&2; exit 1; }
command -v git >/dev/null || { echo "git required" >&2; exit 1; }

branch="plan/$slug"
if git rev-parse --verify --quiet "$branch" >/dev/null; then
  echo "Branch $branch already exists. Delete it or choose a different slug." >&2
  exit 1
fi

# Extract title from spec's first H1.
title=$(grep -m1 '^# ' "$spec" | sed 's/^# *//')
[[ -z "$title" ]] && title="$slug"

# Body = spec "What" section + plan "Approach" section.
body=$(
  printf '## Spec\n\n'
  awk '/^## What$/{flag=1; next} /^## /{flag=0} flag' "$spec"
  printf '\n## Approach\n\n'
  awk '/^## Approach$/{flag=1; next} /^## /{flag=0} flag' "$plan"
  printf '\n---\n\nPlan files: \n- `%s`\n- `%s`\n' "$spec" "$plan"
)

git checkout -b "$branch"
git add "$spec" "$plan"
git commit -m "plan: $title"
git push -u origin "$branch"

pr_url=$(gh pr create \
  --title "plan: $title" \
  --body "$body")

echo ""
echo "Plan PR opened: $pr_url"
echo ""
echo "Next steps:"
echo "  1. Review the plan on GitHub. Edit spec.md / plan.md if needed."
echo "  2. Merge the plan PR."
echo "  3. Back on main: git checkout main && git pull"
echo "  4. Start Phase 3 implementation on branch feat/$slug."
