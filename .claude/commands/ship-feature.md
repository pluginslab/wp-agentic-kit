---
description: Mark the active feature complete and archive it. Updates progress.md status, then moves the dir to .claude/plans/archive/YYYY-MM-DD-NNN-slug/.
argument-hint: "[feature-slug]"
---

# Ship feature

Close the loop on a shipped feature.

1. If `$ARGUMENTS` is empty, locate the active feature: the most recently modified `.claude/plans/features/*/progress.md` whose `status:` is not already `complete`. Use its directory's basename as the slug.
2. If `$ARGUMENTS` is non-empty, use it as the slug. Verify the dir exists.
3. **Pre-flight checks** (refuse if any fail):
   - The feature's PR is merged into `main`. Confirm with `gh pr list --state merged --head feat/<slug>` or ask the user if `gh` isn't available.
   - `./scripts/quality.sh` exits clean against the current `main`.
   - Working tree is clean (no uncommitted changes).
4. Update `.claude/plans/features/<slug>/progress.md`:
   - Set `status: complete`.
   - Append a final log entry: `YYYY-MM-DD HH:MM — Feature shipped, archiving.`
5. Move the dir:
   ```bash
   mv ".claude/plans/features/<slug>" \
      ".claude/plans/archive/$(date +%Y-%m-%d)-<slug>"
   ```
6. Commit the archive move on `main` (or open a tiny PR if the project requires PRs for everything):
   ```
   chore: archive plan for <slug>
   ```
7. Report:
   - The archive path.
   - The merged PR URL.
   - Any open follow-up notes from `findings.md` worth turning into new features.
