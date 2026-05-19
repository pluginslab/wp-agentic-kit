---
name: wordpress-feature
description: Interview-driven workflow to add a feature (Gutenberg block, REST endpoint, Settings page, editor extension, custom post type, taxonomy, CLI command) to an existing WordPress plugin. Writes spec.md + plan.md before generating code and freezes the plan for human review. Also handles maintenance edits (typos, version bumps) with a lightweight log. Use when a plugin already exists in the working directory — for greenfield scaffolding, use wordpress-scaffold instead. Enforces WordPress 6.7+, PHP 8.2+, Node 20+, and the WordPress Coding Standards.
---

# WordPress Feature

This skill adds features and maintenance changes to an **existing** WordPress plugin. If no main plugin file (`*.php` with `Plugin Name:` header) is present, stop and use the `wordpress-scaffold` skill instead.

It runs in one of two modes, decided up front:

- **Feature mode** — meaningful change with its own spec, plan, and PR. Default.
- **Maintenance mode** — typo, version bump, micro-fix. Skips spec/plan, writes a one-liner to a maintenance log.

If unsure, ask: "Is this a feature, or a maintenance edit?"

---

## The planning layer

Plan artifacts live under `.claude/plans/`. The `UserPromptSubmit` hook reads them on every prompt — that's the cross-session memory.

```
.claude/plans/
├── constitution.md                     ← project-stable; read at session start
└── features/
    └── NNN-feature-slug/
        ├── spec.md                     ← what + explicit out-of-scope
        ├── plan.md                     ← phased steps with file paths
        ├── findings.md                 ← optional research notes
        └── progress.md                 ← live state, machine-oriented
```

Templates and rationale: @.claude/references/PLANNING.md. Read it before generating any plan artifact.

**Hard rules for plan files:**

- `constitution.md` is a *whitelist*, not prose. Don't add a library, sanitizer, escaper, or capability that isn't listed without amending the constitution in a separate commit.
- `spec.md` ends with an `Out of scope` section. If something isn't named there or in Acceptance, the agent assumes it's in scope. That's the failure mode.
- `plan.md` steps include file paths. "Add validation to the form handler" is not a step; "Add `wp_verify_nonce` check at `includes/class-settings.php:142`" is.
- `progress.md` stays under 50 lines, machine-oriented (`last_completed`, `next_action`, `blockers`). It's read by the agent, not a human.
- One feature dir per PR. Allocate `NNN` by counting existing dirs + 1, zero-padded to three digits.
- When a feature ships (PR merged), move its dir to `.claude/plans/archive/{YYYY-MM-DD}-{slug}/`.

---

## Feature mode

### Phase 0 — Detect plugin context

1. Find the main plugin file (the `*.php` with `Plugin Name:` in the header).
2. Read its constants, namespace, text domain. Match the existing conventions exactly — don't introduce new naming styles.
3. Read `.claude/plans/constitution.md`. If missing, offer to backfill it from the codebase before continuing — features without a constitution end up reinventing conventions.

### Phase 1 — Spec

1. Ask: **what feature?** Settings page, REST endpoint, Gutenberg block, editor extension, CPT, taxonomy, CLI command.
2. Allocate a feature dir. `NNN-feature-slug` where `NNN` is the next zero-padded number under `.claude/plans/features/`.
3. Write `spec.md` from the template in @.claude/references/PLANNING.md. End with an explicit `Out of scope` section.

### Phase 2 — Plan

Write `plan.md` as a phased step list with file paths. Encourage (don't require) a test step before each implementation step — PHPUnit for PHP, Jest for JS, Playwright for editor flows.

### Phase 2.5 — Plan freeze (STOP)

Do not start implementing. Plans approved without being read encode instructions you don't actually want followed. Run:

```bash
./scripts/open-plan-pr.sh NNN-feature-slug
```

The script creates the `plan/NNN-feature-slug` branch, commits `spec.md` + `plan.md`, pushes, and opens a PR with the spec summary and plan approach pre-filled.

Before requesting human review, dispatch the `plan-reviewer` sub-agent for a quick read-only audit of the plan PR (it checks: file paths present in every step, "Out of scope" exists, no library used outside the constitution).

**Stop and wait for human review and merge of the plan PR before starting Phase 3.** If the reviewer edits the plan, pull main and re-read both files before coding. Implementation lives on a separate `feat/NNN-feature-slug` branch and is its own PR.

### Phase 3 — Implement

After the plan PR merges, mirror open plan steps into the harness task tool (e.g. `TaskCreate` if available) so they show up in the UI. As each step completes, tick it off and append a line to `progress.md`.

### Phase 4 — Findings (lazy)

When an MCP lookup (`wp-devdocs`, `wp-blockmarkup`) surfaces a non-obvious fact that shaped the implementation, append it to `findings.md`. Skip if nothing surprised you.

### Phase 5 — Ship

Run the quality commands (`./vendor/bin/phpcs`, `npm run lint`, `./vendor/bin/phpunit`). Open the feature PR. Dispatch the `security-reviewer` sub-agent on the diff. After merge, move the feature dir to `.claude/plans/archive/{YYYY-MM-DD}-{slug}/`.

---

## Maintenance mode

For a typo, version bump, or change too small to plan:

1. Confirm with the user: "This is a maintenance edit — skipping spec/plan. OK?"
2. Make the change.
3. Append a one-liner to the active feature's `progress.md` (or `.claude/plans/maintenance.md` if no feature is active):
   ```
   2026-05-18 — Bumped version to 1.2.4 for security patch.
   ```

This keeps the trail without spinning up planning ceremony every change.

---

## Hard rules

Security:

- **NEVER** generate code without `ABSPATH` guard.
- **NEVER** output unsanitized data.
- **NEVER** use `extract()`, `eval()`, `create_function()`, or variable variables.
- **NEVER** include files from user-controlled paths.
- **NEVER** trust `$_GET`, `$_POST`, `$_REQUEST`, `$_COOKIE`.
- **ALWAYS** verify nonces on form submissions and AJAX.
- **ALWAYS** check capabilities before admin actions.
- **ALWAYS** prepare database queries: `$wpdb->prepare()`.

Planning:

- **NEVER** generate code in feature mode without a `plan.md` in the active feature dir.
- **NEVER** start Phase 3 (implementation) before the plan PR has been reviewed and merged by a human. The freeze is the point.
- **NEVER** write code that uses a library or function not allowed by `constitution.md` without first asking the user to extend the allowlist.
- **ALWAYS** update `progress.md` when a plan step completes — that's how the next session recovers state.
- **ALWAYS** mirror open plan steps into your harness task tool at the start of an implementation session.

See @.claude/references/SECURITY.md for the full security checklist.

---

## Naming conventions

| Type | Format | Example |
|---|---|---|
| Feature dir | `NNN-kebab-slug` | `001-order-status-block` |
| Plan branch | `plan/NNN-slug` | `plan/001-order-status-block` |
| Feature branch | `feat/NNN-slug` | `feat/001-order-status-block` |

For the underlying plugin conventions (slug, namespace, prefixes), match what's already in the plugin — they were locked at scaffold time.

---

## References

- @.claude/references/PLANNING.md — plan-file templates and rationale
- @.claude/references/SECURITY.md — complete security checklist
- @.claude/references/BLOCKS.md — Gutenberg block development patterns
- WordPress Code Reference: https://developer.wordpress.org/reference/
- WordPress Coding Standards: https://github.com/WordPress/WordPress-Coding-Standards
