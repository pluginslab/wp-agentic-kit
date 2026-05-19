---
description: Commit the active feature's spec.md + plan.md on a plan/ branch and open a PR for human review. Wraps scripts/open-plan-pr.sh.
argument-hint: "[feature-slug]"
---

# Plan freeze

Run the plan-freeze flow for the active feature (or the slug provided as `$ARGUMENTS` if specified).

1. If `$ARGUMENTS` is empty, locate the active feature: the most recently modified `.claude/plans/features/*/progress.md` whose `status:` is not `complete|done|shipped|archived|completed`. Use its directory's basename as the slug.
2. If `$ARGUMENTS` is non-empty, use it as the slug. Verify `.claude/plans/features/$ARGUMENTS/spec.md` and `plan.md` both exist; refuse if not.
3. Confirm the working tree has no changes outside `.claude/plans/features/<slug>/`. If it does, ask the user to commit or stash them first — `scripts/open-plan-pr.sh` will refuse otherwise.
4. Run:
   ```bash
   ./scripts/open-plan-pr.sh <slug>
   ```
5. Report the PR URL the script printed.
6. Remind the user: **do not start implementing yet.** Phase 3 begins after a human merges the plan PR.
7. Offer to dispatch the `plan-reviewer` sub-agent against the PR for a read-only audit before requesting human review.
