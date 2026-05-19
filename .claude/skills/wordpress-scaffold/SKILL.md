---
name: wordpress-scaffold
description: Interview-driven workflow to scaffold a brand-new WordPress plugin. Asks for identity (name, slug, namespace), writes a constitution of defaults + strict allowlists, then generates a complete plugin with optional Settings page, REST API, Gutenberg blocks, and editor extensions. Use only when there is no existing plugin in the working directory — for adding features to an existing plugin, use wordpress-feature instead. Enforces WordPress 6.7+, PHP 8.2+, Node 20+, and the WordPress Coding Standards.
---

# WordPress Scaffold

Scaffolds a brand-new WordPress plugin through a short interview. **Greenfield only** — if a `*.php` file with a `Plugin Name:` header already exists in the working directory, stop and use the `wordpress-feature` skill.

## Phases

1. **Identity.** Ask one question at a time, don't continue without a clear answer:
   - Plugin name (e.g. "Order Tracker")
   - One-sentence description
   - Vendor prefix (optional, e.g. `acme`)
   - Slug — derive `acme-order-tracker` or `order-tracker`; confirm
   - PHP namespace — PascalCase from slug, e.g. `AcmeOrderTracker`; confirm

   Show the full identifier set before generating: slug, text domain (= slug), namespace, constant prefix, function prefix, options key.

2. **Constitution.** Write `.claude/plans/constitution.md` from the template in @.claude/references/PLANNING.md. The file has two binding levels:
   - **Default sections** (loose) — `@wordpress/*` packages, Composer deps, deploy lane, quality gates. Accept the template defaults unless the user wants different.
   - **Allowed sections** (strict, security-relevant) — sanitize functions, escape functions, capability constants, forbidden constructs. Match @.claude/references/SECURITY.md exactly.

   Confirm both before writing. The distinction is the point: treat everything as strict and the agent asks permission for trivia; treat nothing as strict and the plugin is one missing escape from disclosure.

3. **Feature selection.** Ask one at a time: Settings page? REST API? Gutenberg blocks (@.claude/references/BLOCKS.md)? Editor extensions?

4. **Spec + plan.** Create `.claude/plans/features/000-initial-scaffold/` and write `spec.md` + `plan.md` describing the initial scaffold. This becomes the project's first plan artifact.

5. **Generate.** Standard plugin layout: `{slug}.php` (bootstrap with header, `*_VERSION`/`*_PATH`/`*_URL`/`*_FILE` constants, single `get_instance()` class, top-level activation/deactivation hooks), `includes/class-utils.php`, `includes/class-settings.php` (if selected), `includes/api/class-rest.php` + `class-rest-example.php` (if selected), `src/blocks/test-block/` (if selected), `src/extensions/` (if selected), `languages/`, `package.json` (if blocks/extensions), `composer.json`, `phpcs.xml.dist`, `readme.txt`, `uninstall.php`, `.gitignore`. Every PHP file MUST start with the `ABSPATH` guard.

6. **Deliver.** Show the file tree. Print the three install commands (`composer install`, `npm install` if blocks/extensions, `npm run build` if blocks/extensions). Write `progress.md` with `status: complete, last_completed: scaffold` and immediately move `features/000-initial-scaffold/` to `.claude/plans/archive/{YYYY-MM-DD}-000-initial-scaffold/`. Offer to spin up `wp-playground` for a smoke test. Tell the user: **next features go through `wordpress-feature`.**

## Hard rules (this skill)

Every PHP file MUST start with `if ( ! defined( 'ABSPATH' ) ) { exit; }`. Every generated piece MUST follow @.claude/references/SECURITY.md — sanitize input, escape output, verify nonces, check capabilities, prepare queries. Constitution's **strict** sections bind hard; **default** sections are advisory.

## Naming (locked at scaffold)

- Slug: kebab-case (`acme-order-tracker`) · Text domain: same as slug, literal string
- Namespace: PascalCase (`AcmeOrderTracker`)
- Constants: `ACME_ORDER_TRACKER_*` · Functions: `acme_order_tracker_*`
- Class files: `class-{name}.php` · Hooks: namespaced action/filter names

## After generation

Remind the user to run `./vendor/bin/phpcs`, verify activation → deactivation → uninstall leaves no orphan data, commit `composer.lock` + `package-lock.json`, and run `security-reviewer` before the first PR.

## References

- @.claude/references/PLANNING.md — plan-file templates and rationale
- @.claude/references/SECURITY.md — complete security checklist
- @.claude/references/BLOCKS.md — Gutenberg block development patterns
