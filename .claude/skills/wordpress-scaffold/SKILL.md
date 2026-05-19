---
name: wordpress-scaffold
description: Interview-driven workflow to scaffold a brand-new WordPress plugin. Asks for identity (name, slug, namespace), writes a constitution of allowlists, then generates a complete plugin with optional Settings page, REST API, Gutenberg blocks, and editor extensions. Use only when there is no existing plugin in the working directory — for adding features to an existing plugin, use wordpress-feature instead. Enforces WordPress 6.7+, PHP 8.2+, Node 20+, and the WordPress Coding Standards.
---

# WordPress Scaffold

This skill scaffolds a brand-new WordPress plugin through a short interview. It is **only for greenfield plugin creation** — if a `*.php` file with a `Plugin Name:` header already exists in the working directory, stop and use the `wordpress-feature` skill instead.

---

## The planning layer

Plan artifacts live under `.claude/plans/`. This skill creates the initial set:

```
.claude/plans/
├── constitution.md                     ← written in Phase 2
└── features/
    └── 000-initial-scaffold/
        ├── spec.md                     ← written in Phase 4
        ├── plan.md                     ← written in Phase 4
        └── progress.md                 ← written in Phase 6
```

Templates and rationale: @.claude/references/PLANNING.md.

---

## Phase 1 — Identity

Ask one question at a time. Don't continue until you have a clear answer.

1. **Plugin name?** (e.g. "Order Tracker")
2. **One-sentence description?** (used in the plugin header and `readme.txt`)
3. **Vendor prefix?** Optional, e.g. `acme`. If empty, no prefix.
4. **Slug?** Derive from name + prefix: `acme-order-tracker` or just `order-tracker`. Confirm.
5. **PHP namespace?** PascalCase from slug, e.g. `AcmeOrderTracker`. Confirm.

Show the full identifier set before generating:

| Identifier | Example |
|---|---|
| Slug | `acme-order-tracker` |
| Text domain | `acme-order-tracker` (same as slug, literal string) |
| Namespace | `AcmeOrderTracker` |
| Constant prefix | `ACME_ORDER_TRACKER_*` |
| Function prefix | `acme_order_tracker_*` |
| Options key | `acme_order_tracker_options` |

## Phase 2 — Constitution

Write `.claude/plans/constitution.md` from the template in @.claude/references/PLANNING.md. Interview for:

- Allowed `@wordpress/*` packages (default set provided in template).
- Allowed sanitize / escape functions (default: the SECURITY.md table).
- Allowed capability constants (default: `manage_options`, `edit_posts`, `read`).
- Deploy lane (none, Ploi auto-deploy, GHA + Tailscale, custom).
- Required quality gates (default: phpcs, eslint, phpunit, jest).

Confirm the whitelist before writing. The constitution is a *whitelist, not prose* — list exact package names, not "modern WordPress packages."

## Phase 3 — Feature selection

Ask each one at a time:

1. **Settings page?** → Settings API with a tabbed interface.
2. **REST API?** → A REST controller base class and one example endpoint.
3. **Gutenberg blocks?** → Block registration + one test block. See @.claude/references/BLOCKS.md.
4. **Editor extensions?** → Sidebar panel / toolbar button scaffold.

## Phase 4 — Spec + plan for the initial scaffold

Create `.claude/plans/features/000-initial-scaffold/` and write `spec.md` + `plan.md` describing what will be generated. This becomes the project's first plan artifact and the example future features follow.

## Phase 5 — Generate

Generate this structure:

```
{slug}/
├── {slug}.php              # Bootstrap, plugin header, top-level hooks
├── includes/
│   ├── class-utils.php     # Generic helpers, caching
│   ├── class-settings.php  # if Settings selected
│   └── api/                # if REST selected
│       ├── class-rest.php
│       └── class-rest-example.php
├── src/                     # if blocks or extensions selected
│   ├── blocks/
│   │   └── test-block/
│   └── extensions/
├── languages/
├── package.json             # if blocks or extensions selected
├── composer.json
├── phpcs.xml.dist
├── readme.txt
├── uninstall.php
└── .gitignore
```

### Bootstrap pattern (`{slug}.php`)

- Standard plugin header with all required fields.
- Single bootstrap class instantiated once via a static `get_instance()`.
- Heavy work happens in hooks, never at load time.
- Admin-only feature classes guarded behind `is_admin()`.
- `register_activation_hook` and `register_deactivation_hook` at top scope only.
- Constants defined once: `*_VERSION`, `*_PATH`, `*_URL`, `*_FILE`.

### Security defaults (mandatory)

Every PHP file generated MUST start with:

```php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
```

All generated code MUST follow @.claude/references/SECURITY.md: sanitize input, escape output, verify nonces, check capabilities, prepared queries.

## Phase 6 — Deliver

After generating, show:

1. File tree of what was created.
2. Three key commands:
   ```bash
   composer install
   npm install          # only if blocks or extensions selected
   npm run build        # only if blocks or extensions selected
   ```
3. Write `progress.md` in `features/000-initial-scaffold/` with `status: complete`, `last_completed: scaffold`, `next_action: composer install && npm install`. Then move the dir to `.claude/plans/archive/{YYYY-MM-DD}-000-initial-scaffold/`.
4. Offer to spin up `wp-playground` for a smoke test.
5. Tell the user: **next features go through the `wordpress-feature` skill.**

---

## Naming conventions

| Type | Format | Example |
|---|---|---|
| Slug | kebab-case | `acme-order-tracker` |
| Text domain | same as slug, literal string | `acme-order-tracker` |
| Namespace | PascalCase | `AcmeOrderTracker` |
| Constants | UPPER_SNAKE_CASE with prefix | `ACME_ORDER_TRACKER_VERSION` |
| Functions | lower_snake_case with prefix | `acme_order_tracker_init` |
| Class files | `class-{name}.php` | `class-rest-example.php` |
| Hooks | filter/action names | `acme_order_tracker_after_save` |

---

## Hard rules

- **NEVER** generate code without `ABSPATH` guard.
- **NEVER** output unsanitized data.
- **NEVER** use `extract()`, `eval()`, `create_function()`, or variable variables.
- **NEVER** include files from user-controlled paths.
- **NEVER** trust `$_GET`, `$_POST`, `$_REQUEST`, `$_COOKIE`.
- **ALWAYS** verify nonces on form submissions and AJAX.
- **ALWAYS** check capabilities before admin actions.
- **ALWAYS** prepare database queries: `$wpdb->prepare()`.

See @.claude/references/SECURITY.md for the full checklist with code examples.

---

## After generation

Remind the user to:

1. Run `./vendor/bin/phpcs` to confirm WordPress Coding Standards compliance.
2. Verify activation → deactivation → uninstall leaves no orphan data.
3. Commit `composer.lock` and `package-lock.json`.
4. Open a PR — the `security-reviewer` sub-agent runs against the diff before merge.

---

## References

- @.claude/references/PLANNING.md — plan-file templates and rationale
- @.claude/references/SECURITY.md — complete security checklist
- @.claude/references/BLOCKS.md — Gutenberg block development patterns
- WordPress Code Reference: https://developer.wordpress.org/reference/
- WordPress Coding Standards: https://github.com/WordPress/WordPress-Coding-Standards
