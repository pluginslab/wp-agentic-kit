# wordpress-feature skill

Interview-driven workflow for adding features to an **existing** WordPress plugin. Writes spec + plan before code, freezes the plan for human review, then implements. Also handles maintenance edits (typos, version bumps) with a lightweight log. For brand-new plugin creation, use [`wordpress-scaffold`](../wordpress-scaffold/) instead.

## Maps to the talk's framework

**Delegação.** Adding a feature is the work you stop doing by hand and hand to the agent. The skill structures that handoff — interview, plan, freeze, implement — so the agent doesn't improvise.

## Invoke

```
/wordpress-feature
```

Inside a Claude Code session, in a directory with an existing plugin (a `*.php` file with `Plugin Name:` in the header).

## Modes

- **Feature mode** — spec → plan → freeze for human review → implement → ship. Six phases.
- **Maintenance mode** — typo, version bump, micro-fix. Skips planning; writes a one-liner to the maintenance log.

## What's enforced

- Plan freeze: the agent stops after `plan.md` and waits for a human-merged plan PR.
- Constitution allowlists: no library, sanitizer, or capability slips in without amending the constitution first.
- Full security checklist from @../../references/SECURITY.md.
- Block API v3 for Gutenberg work — see @../../references/BLOCKS.md.
