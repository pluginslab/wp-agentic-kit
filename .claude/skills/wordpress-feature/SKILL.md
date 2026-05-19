---
name: wordpress-feature
description: Interview-driven workflow to add a feature (Gutenberg block, REST endpoint, Settings page, editor extension, custom post type, taxonomy, CLI command) to an existing WordPress plugin. Writes spec.md + plan.md before generating code and freezes the plan for human review when the feature warrants it. Also handles maintenance edits (typos, version bumps) with a lightweight log. Use when a plugin already exists in the working directory — for greenfield scaffolding, use wordpress-scaffold instead. Enforces WordPress 6.7+, PHP 8.2+, Node 20+, and the WordPress Coding Standards.
---

# WordPress Feature

Adds features (block, REST, settings, extension, CPT, taxonomy, CLI command) and maintenance edits (typos, version bumps) to an existing WordPress plugin. If no main plugin file (`*.php` with a `Plugin Name:` header) is present, stop and use the `wordpress-scaffold` skill.

## Mode

Decide first: **feature** (gets spec + plan, possibly its own PR) or **maintenance** (typo / version bump / micro-fix; one-line log). Ask if unsure.

## Feature mode

1. **Context.** Find the main plugin file. Read its constants, namespace, text domain — match the existing conventions exactly. Read `.claude/plans/constitution.md`; offer to backfill from the codebase if missing.
2. **Spec.** Allocate `.claude/plans/features/NNN-feature-slug/` (next zero-padded number). Write `spec.md` from the template in @.claude/references/PLANNING.md. End with an explicit `Out of scope` section.
3. **Plan.** Write `plan.md` from the same template. Phased steps, **file paths in every step**, tests encouraged before each implementation step. Fill the **Freeze assessment** checklist honestly at the end.
4. **Freeze decision.** Read the assessment's recommendation:
    - **freeze** (any box checked): run `./scripts/open-plan-pr.sh NNN-slug`, dispatch the `plan-reviewer` sub-agent against the PR, **stop and wait for the human-merged plan PR before starting step 5**.
    - **proceed** (no boxes checked): create `feat/NNN-slug`, commit `spec.md` + `plan.md` as the first commit, surface the assessment to the user, start step 5.
    - The user can override either direction.
5. **Implement.** After the plan PR merges (or immediately for "proceed"), mirror open plan steps into the harness task tool (e.g. `TaskCreate` if available). Tick off as you go; append to `progress.md`.
6. **Findings (lazy).** When an MCP lookup (`wp-devdocs`, `wp-blockmarkup`) surfaces a non-obvious fact that shaped the code, append to `findings.md`. Skip if nothing surprised you.
7. **Ship.** Run `./scripts/quality.sh`. Open the feature PR. Dispatch `security-reviewer` on the diff. After merge, archive the feature dir to `.claude/plans/archive/{YYYY-MM-DD}-{slug}/`.

## Maintenance mode

Confirm "skipping spec/plan, ok?" → make the change → append a one-liner to the active feature's `progress.md` (or `.claude/plans/maintenance.md` if no feature is active):

```
2026-05-18 — Bumped version to 1.2.4 for security patch.
```

## Hard rules (this skill)

- **NEVER** generate code in feature mode without a `plan.md` in the active feature dir.
- **NEVER** start step 5 (implement) if the Freeze assessment recommends **freeze** and the plan PR hasn't merged.
- **NEVER** ship a blank or dishonest Freeze assessment. The `plan-reviewer` catches it.
- **NEVER** use a sanitizer, escaper, capability constant, or otherwise-forbidden construct that isn't in the constitution's **strict** sections. Dependencies (npm / Composer) follow the **default** sections — extend when needed, note why in `findings.md`.

For the universal security checklist (ABSPATH, sanitize, escape, nonce, capability, prepare) see @.claude/references/SECURITY.md. CLAUDE.md repeats the load-bearing ones at the top of every session.

## Naming

- Feature dir: `NNN-kebab-slug` (e.g. `001-order-status-block`)
- Plan branch: `plan/NNN-slug` · Feature branch: `feat/NNN-slug`
- Plugin slug, namespace, prefixes: match what's already in the plugin — they were locked at scaffold time.

## References

- @.claude/references/PLANNING.md — plan-file templates + rationale + freeze assessment
- @.claude/references/SECURITY.md — full security checklist with code patterns
- @.claude/references/BLOCKS.md — Gutenberg block development patterns
