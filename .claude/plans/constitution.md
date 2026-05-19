# Constitution — Example Plugin

Last updated: 2026-05-18

<!--
The constitution has two parts:

  • Defaults — what we usually reach for. Free to extend; record the
    addition with a one-line note in commit or findings.md.
  • Allowed — strict. Security-relevant choices the agent must not
    deviate from without explicit human approval, because the failure
    mode is a CVE, not a style nit.

The distinction is the point. Treating everything as strict makes the
agent ask permission for trivia; treating nothing as strict puts you
one missing escape away from disclosure.
-->

## Stack

- WordPress: >= 6.7
- PHP: >= 8.2
- Node: >= 20
- Deploy lane: none (set when the plugin is hooked into a host)

## Default npm dependencies

The packages we expect to reach for. If a feature genuinely needs something else, just use it — note the addition in the feature's `findings.md` so future readers know why.

- `@wordpress/scripts` (build)
- `@wordpress/blocks`, `@wordpress/block-editor`, `@wordpress/components`
- `@wordpress/element`, `@wordpress/i18n`, `@wordpress/api-fetch`
- `@wordpress/hooks`, `@wordpress/data`

## Default Composer dependencies

- Dev: `squizlabs/php_codesniffer`, `wp-coding-standards/wpcs`, `phpunit/phpunit`

Same rule: extend when a feature needs it; note why.

## Allowed input sanitizers (strict)

These are exhaustive — sanitizing with anything else is a bug. The wrong sanitizer for the context is a CVE waiting to be filed.

- `sanitize_text_field`, `sanitize_email`, `sanitize_key`, `sanitize_file_name`
- `sanitize_hex_color`, `sanitize_textarea_field`
- `absint`, `floatval`, `(bool) rest_sanitize_boolean`
- `esc_url_raw` (for storage)
- `wp_kses_post`, `wp_kses` (with explicit allowlist)

## Allowed output escapers (strict)

Same rule: escape with one of these, picked by context. Anything else is a bug.

- `esc_html`, `esc_attr`, `esc_url`, `esc_js`
- `wp_kses_post`, `wp_kses` (with explicit allowlist)
- `esc_html__`, `esc_attr__`, `esc_html_e`, `esc_attr_e` (translated)

## Allowed capability constants (strict)

- `manage_options` — admin-only settings
- `edit_posts` — content editors
- `read` — any logged-in user

Custom capabilities (e.g. `pl_example_manage_orders`) require amending the constitution before they're referenced. Using a capability that doesn't exist anywhere silently grants access to everyone or denies it to everyone — and which one depends on WP version.

## Quality gates (run before merge)

- `./vendor/bin/phpcs` — WordPress Coding Standards
- `npm run lint` — ESLint + stylelint
- `./vendor/bin/phpunit` — PHP unit tests
- `npm test` — JS tests (if blocks/extensions present)

## Forbidden constructs

- `eval`, `extract`, `create_function`, variable variables (`$$x`)
- `unserialize` on user data — use `json_decode`
- `assert` with a string argument
- File includes from user-controlled paths
- `'permission_callback' => '__return_true'` on any mutating REST route

## Conventions

- Slug: `pl-example` · Namespace: `PLExample` · Constants: `PL_EXAMPLE_*` · Functions: `pl_example_*`
- Options: one option per plugin, `pl_example_options`, value is an array
- Text domain: literal string `pl-example`, never a variable
