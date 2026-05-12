---
name: wordpress-development
description: Interview-driven workflow to scaffold a new WordPress plugin or add a feature (Gutenberg block, REST endpoint, Settings page, editor extension) to an existing one. Enforces WordPress 6.7+, PHP 8.2+, and the WordPress Coding Standards.
license: MIT
compatibility:
  wordpress: ">=6.7"
  php: ">=8.2"
  node: ">=20"
---

# WordPress Development

This skill scaffolds production-ready WordPress code through a short interview. It runs in one of two modes depending on where it's invoked.

## Modes

**New plugin mode** — invoked outside a plugin (no main plugin file detected in the working directory). Generates a complete plugin scaffold with the features you select.

**Feature mode** — invoked inside an existing plugin (a `*.php` file with a `Plugin Name:` header is present). Adds a single feature: a block, a REST endpoint, a Settings page, or an editor extension.

Decide which mode applies before asking any questions. If unsure, ask: "Are we starting a new plugin or adding to an existing one?"

---

## New plugin mode

### Phase 1 — Plugin identity

Ask one question at a time. Don't continue until you have a clear answer.

1. **Plugin name?** (e.g. "Order Tracker")
2. **One-sentence description?** (used in the plugin header and `readme.txt`)
3. **Vendor prefix?** Optional, e.g. `acme`. If empty, no prefix.
4. **Slug?** Derive from name + prefix: `acme-order-tracker` or just `order-tracker`. Confirm.
5. **PHP namespace?** PascalCase from slug, e.g. `AcmeOrderTracker`. Confirm.

Derive the rest from the slug. Show the user the full set before generating:

| Identifier | Example |
|---|---|
| Slug | `acme-order-tracker` |
| Text domain | `acme-order-tracker` (same as slug, literal string) |
| Namespace | `AcmeOrderTracker` |
| Constant prefix | `ACME_ORDER_TRACKER_*` |
| Function prefix | `acme_order_tracker_*` |
| Options key | `acme_order_tracker_options` |

### Phase 2 — Feature selection

Ask each of the following one at a time:

6. **Settings page?** → Settings API with a tabbed interface.
7. **REST API?** → A REST controller base class and one example endpoint.
8. **Gutenberg blocks?** → Block registration + one test block. See @references/BLOCKS.md.
9. **Editor extensions?** → Sidebar panel / toolbar button scaffold.

### Phase 3 — Generate

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

#### Bootstrap pattern (`{slug}.php`)

- Standard plugin header with all required fields.
- Single bootstrap class instantiated once via a static `get_instance()`.
- Heavy work happens in hooks, never at load time.
- Admin-only feature classes guarded behind `is_admin()`.
- `register_activation_hook` and `register_deactivation_hook` at top scope only.
- Constants defined once: `*_VERSION`, `*_PATH`, `*_URL`, `*_FILE`.

#### Security defaults (mandatory)

Every PHP file generated MUST start with:

```php
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}
```

All generated code MUST follow @references/SECURITY.md: sanitize input, escape output, verify nonces, check capabilities, prepared queries.

### Phase 4 — Delivery

After generating, show:

1. File tree of what was created.
2. The three key commands to run next:
   ```bash
   composer install
   npm install          # only if blocks or extensions selected
   npm run build        # only if blocks or extensions selected
   ```
3. A short testing checklist (activate, deactivate, uninstall — verify each leaves the database clean).
4. Offer to spin up `wp-playground` for a quick smoke test.

---

## Feature mode

Detect the plugin context first:

1. Find the main plugin file (the `*.php` with `Plugin Name:` in the header).
2. Read its constants, namespace, text domain.
3. Match the existing conventions exactly. Don't introduce new naming styles.

Then ask:

- **What feature?** Settings page, REST endpoint, Gutenberg block, editor extension, custom post type, custom taxonomy, CLI command.

Generate just that feature, integrate cleanly with the existing bootstrap, and remind the user to run their existing build / lint commands.

---

## Naming conventions (both modes)

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

See @references/SECURITY.md for the full security checklist with code examples.

---

## After generation

Remind the user to:

1. Run `./vendor/bin/phpcs` to confirm WordPress Coding Standards compliance.
2. Verify activation → deactivation → uninstall leaves no orphan data.
3. Add tests as features grow: PHPUnit for PHP, Jest / Playwright for blocks.
4. Commit `composer.lock` and `package-lock.json` so the agent (and humans) build the same thing.

---

## References

- @references/SECURITY.md — complete security checklist with code patterns
- @references/BLOCKS.md — Gutenberg block development patterns
- WordPress Code Reference: https://developer.wordpress.org/reference/
- WordPress Coding Standards: https://github.com/WordPress/WordPress-Coding-Standards
