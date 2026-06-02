# Changelog

The kit's evolution, kept for humans. Per-feature progress lives in `.claude/plans/`.

## v1.0.1 — 2026-06-02

### Fixed

- **The quality gate now passes on a fresh scaffold.** `scripts/quality.sh` ran `phpcs --standard=WordPress`, which overrode the project `phpcs.xml.dist` and discarded its `<file>` list, so phpcs aborted with "must supply at least one file or directory" — and `pre-commit.sh` blocked the very first commit. It now runs `phpcs` against the project ruleset, gated on a `phpcs.xml(.dist)` being present.
- **phpunit no longer fails an unconfigured scaffold.** The suite runs phpunit only when a `phpunit.xml(.dist)` exists. The example `WP_UnitTestCase` test needs the WordPress test harness (wp-env); until that's set up, phpunit stays benign instead of erroring out.
- **Example template files are now WordPress-Coding-Standards clean** (36 phpcs violations → 0): added the missing class / function / parameter / member docblocks, switched to long array syntax, scoped a `phpcs:ignore` to the one-shot direct DB call in `uninstall.php`, and excluded the entry-point main file from the class-file-naming sniff. A freshly scaffolded plugin is green out of the box.

## v1.0.0 — 2026-05-19

The first release that's structurally complete: every D of the talk's framework is wired into the kit, and every piece has its place.

### Added

- **Planning layer** (`.claude/plans/`). Four-file cascade — `constitution.md` (project-stable), per-feature `spec.md` / `plan.md` / `progress.md`, optional `findings.md`. Shipped features archive to `.claude/plans/archive/{YYYY-MM-DD}-{slug}/`. Templates and rationale in `.claude/references/PLANNING.md`.
- **`wordpress-feature` skill.** Greenfield was `wordpress-development` before; now split so `wordpress-feature` handles the per-PR loop (spec → plan → freeze → implement → ship) and `wordpress-scaffold` handles the once-per-plugin bootstrap.
- **Conditional plan-freeze.** Every `plan.md` ends with a five-checkbox Freeze assessment. Any box checked → plan-PR loop. Zero checked → in-session execution. Trivial features no longer pay PR ceremony.
- **`plan-reviewer` sub-agent.** Read-only audit of `spec.md` + `plan.md` before human review. Catches missing `Out of scope`, steps without file paths, dishonest freeze assessments, and constitution-violating choices.
- **`UserPromptSubmit` hook.** Injects the active feature's `next_action` and `last_completed` on every prompt — the load-bearing defense against plan drift.
- **`Stop` hook.** Auto-bumps `progress.md`'s `last_updated` when the agent finishes a turn, so file age tracks activity even when the agent forgets to log.
- **`SessionStart` hook.** Orientation banner on `resume|compact|clear` naming the active feature and next step.
- **Slash commands.** `/plan-freeze`, `/audit-plan`, `/ship-feature` wrap the common operations as muscle-memory shortcuts.
- **`scripts/open-plan-pr.sh`.** Automates the plan-freeze flow — branch, commit, push, `gh pr create` with pre-filled body.
- **`tests/` directory.** Bash test suite for the four hooks (56 cases, plain bash, zero deps). Integrated into `scripts/quality.sh` so a failing hook blocks commits.
- **Worked example feature** (`.claude/plans/features/001-example-hello-rest/`). Spec, plan, findings, progress — plus the actual code (`pl-example.php`, `includes/api/class-rest-hello.php`, `tests/phpunit/test-rest-hello.php`) that the plan refers to. Every file the plan names exists.
- **Docs chapter 3 — Planning.** Walks the four-file cascade, the freeze assessment, and the conditional-vs-unconditional reasoning end to end. Existing chapters renumbered (4–9).
- **Four D's framing wired through every README** (`.claude/plans/`, `.claude/skills/*/`, `.claude/agents/`, `.claude/hooks/`, top-level README, docs walkthrough) — Delegação / Descrição / Discernimento / Diligência mapped to specific kit pieces.

### Changed

- **Constitution split into two binding levels.** Strict sections (sanitizers, escapers, capability constants, forbidden constructs) bind hard — the failure mode is a CVE. Default sections (npm / Composer dependencies) are advisory — extend as needed, note why in `findings.md`. Treats security and dependency choices as the different decisions they are.
- **`SKILL.md` files trimmed ~70%.** Both `wordpress-scaffold/SKILL.md` and `wordpress-feature/SKILL.md` down from ~180 lines to 54. Duplicated security and plan-file rules removed; phase prose compressed; references centralized in `.claude/references/`. Trusts the model more.
- **References promoted to `.claude/references/`.** `SECURITY.md`, `BLOCKS.md`, `PLANNING.md` now shared across both skills, both sub-agents, and the planning chapter — single source of truth.
- **`security-reviewer` description.** Now references the shared `.claude/references/SECURITY.md` instead of the old per-skill copy.
- **CLAUDE.md / AGENTS.md "Memory hygiene" section.** Clarified that per-feature memory lives in `progress.md` / `findings.md`; `CHANGELOG.md` is for release notes only.

### Removed

- `wordpress-development` skill — split into `wordpress-scaffold` + `wordpress-feature`. The old skill name no longer appears anywhere in the kit.
- Duplicated security checklists from `SKILL.md` files. The canonical list is at `.claude/references/SECURITY.md`; `CLAUDE.md` repeats the load-bearing items in its first 40 lines.
- Invented skill frontmatter fields (`license:`, `compatibility:`). Claude Code skills only honor a defined set of keys; the others were silently ignored.

### Fixed

- `UserPromptSubmit` hook status parser now tolerates whitespace, case, and completion synonyms (`done`, `shipped`, `archived`, `completed`).
- Plan PR script (`scripts/open-plan-pr.sh`) header now documents the GitHub assumption and the requirement for `gh` on PATH.
- `github` MCP entry in `.mcp.json` ships with the `${GITHUB_TOKEN}` env block pre-wired — just export the variable in your shell.

---

## v0.1.0 — 2026-04

Initial scaffold release: CLAUDE.md / AGENTS.md templates, the `wordpress-development` skill, `security-reviewer` sub-agent, post-edit + pre-commit hooks, the five MCP servers, the Node CLI (`create-wp-ai-plugin`), and the eight-chapter docs walkthrough.
