# Example Plugin

<!--
========================================================================
HOW TO USE THIS FILE
This file is part of wp-agentic-kit. Run `npm create wp-ai-plugin
<target>` (or `npx create-wp-ai-plugin <target>`) once after cloning
to replace the "Example Plugin" / "pl-example" / "PLExample" example
values with your own across every file in the kit.

CLAUDE.md and AGENTS.md are kept identical so any agent finds the
instructions, whatever name it looks for. Edit one and copy to the
other, or symlink them: ln -sf CLAUDE.md AGENTS.md.

Coding agents read this at the start of every session:
- Claude Code reads CLAUDE.md
- Codex, Cursor, Gemini CLI, GitHub Copilot, Windsurf read AGENTS.md

KEEP IT TIGHT:
- Aim for under 200 lines and under 15 rules total.
- Put critical "never do this" / security rules in the first 40 lines.
- Use IMPORTANT: / YOU MUST sparingly. If everything is important,
  nothing is. Reserve them for the one or two rules that are truly
  non-negotiable.
- Prefer runnable commands over prose. "Run pnpm test" beats "test it."
- Use @path/to/file to pull in extra context on demand.
- For rules that MUST always run (lints, formatters, gates), use hooks
  in .claude/hooks/. CLAUDE.md is advisory; hooks are deterministic.

ITERATE:
When you find yourself correcting the agent on the same mistake twice,
add a rule here that prevents it.

The HTML comments in this file (like this one) are for the human
maintaining the template. Strip them before shipping to keep the
file lean.
========================================================================
-->

## What this is

An example WordPress plugin scaffolded with wp-agentic-kit. Replace this sentence with what your plugin actually does.

- **Type:** WordPress plugin
- **Author:** Example Author
- **WordPress:** 6.7+
- **PHP:** 8.2+
- **Slug:** `pl-example` · **Namespace:** `PLExample` · **Text domain:** `pl-example`

## IMPORTANT: security is non-negotiable

YOU MUST follow these in every PHP file you touch:

- Every PHP file starts with `if ( ! defined( 'ABSPATH' ) ) { exit; }`.
- Sanitize all input: `sanitize_text_field`, `sanitize_email`, `absint`, `sanitize_key`, `esc_url_raw`, `wp_kses_post`.
- Escape all output: `esc_html`, `esc_attr`, `esc_url`, `wp_kses_post`.
- Verify nonces on every form submission and AJAX call.
- Check capabilities (`current_user_can(...)`) before any admin action.
- Use `$wpdb->prepare()` for any query that includes user input.
- Never use `eval`, `extract`, variable variables, or include files from user-controlled paths.

<!-- WHY this lives at the top: the first ~40 lines get the strongest model
     attention. Security rules earn that real estate; convenience rules don't. -->

## Commands

```bash
# Install
composer install
npm install

# Build assets (blocks / extensions)
npm run build            # production
npm run start            # dev with watch

# Quality gates (run before considering work done)
./vendor/bin/phpcs       # WordPress Coding Standards
npm run lint             # ESLint + stylelint

# Tests
./vendor/bin/phpunit
npm test

# Local WordPress for manual testing
wp-env start
```

<!-- WHY: research consistently identifies exact commands as the highest-value
     section of CLAUDE.md. Without them, the agent guesses npm test when your
     project uses pnpm vitest, and burns turns debugging the wrong command. -->

## Structure

```
pl-example/
├── pl-example.php               # Bootstrap, plugin header, top-level hooks only
├── includes/                     # PHP classes, one per file
│   ├── class-utils.php
│   ├── class-settings.php
│   └── api/                      # REST controllers
├── src/                          # JS / TS sources
│   ├── blocks/                   # Gutenberg blocks
│   └── extensions/               # Editor extensions
├── build/                        # compiled output, gitignored
├── languages/                    # .pot / .po files
├── readme.txt                    # WordPress.org-style readme
└── uninstall.php                 # cleanup on uninstall
```

Deeper details: @.claude/skills/wordpress-feature/SKILL.md (and @.claude/skills/wordpress-scaffold/SKILL.md for greenfield)

## Conventions

- **Namespace:** `PLExample` (PascalCase, no underscores)
- **Constant prefix:** `PL_EXAMPLE_*` (UPPER_SNAKE_CASE)
- **Function prefix:** `pl_example_*` (lower_snake_case)
- **Class files:** `class-{name}.php`, kebab-case
- **Text domain:** literal string `pl-example`, never a variable
- **Options:** one option per plugin, named `pl_example_options`, value is an array
- Activation / deactivation hooks register only at top scope.
- Heavy work happens in hooks, not at load time. Admin code stays behind `is_admin()`.
- Use transients for caching with explicit invalidation hooks.

## Workflow

- For a new feature, invoke the `wordpress-feature` skill — it writes spec + plan, freezes for review, then implements.
- Run the matching quality command after each change: `phpcs` for PHP, `npm run lint` for JS/CSS.
- Prefer extending an existing class over adding a new one.
- One concern per PR. Keep diffs small.
- For uncertain WordPress API behaviour, check the `wp-devdocs` MCP before guessing.
- For block markup, check the `wp-blockmarkup` MCP rather than writing serialised JSON by hand.

## Never

- Never trust `$_GET`, `$_POST`, `$_REQUEST`, or `$_COOKIE` without sanitization.
- Never echo unsanitized data.
- Never use `extract()` or variable variables.
- Never include files from user-controlled paths.
- Never commit `.env`, credentials, `vendor/`, or `node_modules/`.
- Never skip nonce verification on the grounds of "it's only admin".
- Never push directly to `main`. Open a PR.

<!-- WHY: explicit negative rules matter as much as positive ones. Without
     them, the agent picks the most common pattern it has seen, which may
     not match your project. -->

## MCP servers configured here

- `wp-devdocs` — canonical WordPress function / hook reference
- `wp-blockmarkup` — block markup schemas and validation
- `wp-playground` — spin up ephemeral WordPress for testing
- `chrome-devtools` — inspect rendered output of blocks / pages
- `github` — repository, PRs, issues

<!-- WHY: naming the tools available makes the agent more likely to use
     them instead of falling back to web search or guessing. -->

## Planning layer

The agent's load-bearing memory across sessions lives under `.claude/plans/`:

- `.claude/plans/constitution.md` — project guardrails. Two binding levels: **strict** for security-relevant choices (sanitizers, escapers, capability constants, forbidden constructs — never deviate without approval), **default** for dependencies (advisory; extend when needed and note why).
- `.claude/plans/features/NNN-feature-slug/` — one dir per in-flight feature: `spec.md`, `plan.md`, `progress.md` (+ optional `findings.md`).
- `.claude/plans/archive/` — shipped features, kept for long-term memory.

The `UserPromptSubmit` hook surfaces the active feature's next step on every turn. New features always go through the `wordpress-feature` skill (greenfield plugins go through `wordpress-scaffold`), which writes the plan files before generating code.

@.claude/plans/constitution.md

## References (load on demand)

- @.claude/plans/README.md — planning layer overview
- @.claude/skills/wordpress-scaffold/SKILL.md — greenfield plugin workflow
- @.claude/skills/wordpress-feature/SKILL.md — feature + maintenance workflow
- @.claude/references/PLANNING.md — plan-file templates and rationale
- @.claude/references/SECURITY.md — full security checklist
- @.claude/references/BLOCKS.md — Gutenberg patterns
- WordPress Code Reference: https://developer.wordpress.org/reference/
- WordPress Coding Standards: https://github.com/WordPress/WordPress-Coding-Standards

## Memory hygiene

- When you catch yourself correcting me on the same mistake twice, append a rule above instead of re-explaining.
- Per-feature progress, decisions, and dead ends go in the feature's `.claude/plans/features/NNN-slug/progress.md` (live) and `findings.md` (research). Shipped features move to `.claude/plans/archive/` — that's the long-term agent memory.
- `CHANGELOG.md` is for human-facing release notes only (one entry per version bump). Don't conflate it with agent memory.
