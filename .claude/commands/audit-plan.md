---
description: Dispatch the plan-reviewer sub-agent to audit the active feature's spec.md and plan.md against PLANNING.md and constitution.md. Read-only.
argument-hint: "[feature-slug]"
---

# Audit plan

Dispatch the `plan-reviewer` sub-agent to audit a feature plan before human review.

1. If `$ARGUMENTS` is empty, locate the active feature: the most recently modified `.claude/plans/features/*/progress.md` whose `status:` is not `complete|done|shipped|archived|completed`. Use its directory's basename as the slug.
2. If `$ARGUMENTS` is non-empty, use it as the slug. Verify `.claude/plans/features/$ARGUMENTS/` exists.
3. Invoke the `plan-reviewer` sub-agent with this instruction:
   > Audit `.claude/plans/features/<slug>/`. Check spec.md, plan.md, findings.md (if present), and constitution.md per the rules in `.claude/agents/plan-reviewer.md`. Report findings grouped by severity.
4. Surface the report back to me grouped by severity (Critical / High / Medium / Low).
5. If Critical findings exist: tell me which ones and stop — they need fixing before the plan PR can be merged.
6. If only Medium/Low findings exist: list them and ask whether to fix now or merge anyway.
7. If clean: confirm the plan is ready for human review and (if a plan PR isn't open yet) offer to run `/plan-freeze`.
