# Constitution — Example Plugin

Last updated: 2026-05-18

<!--
This is the scaffolded starter constitution. Edit it deliberately — the
agent treats anything not listed here as "ask first." Adding a dependency
means amending this file in its own commit, with the reason in the commit
message.
-->

## Stack

- WordPress: >= 6.7
- PHP: >= 8.2
- Node: >= 20
- Deploy lane: none (set when the plugin is hooked into a host)

## Allowed npm dependencies

- `@wordpress/scripts` (build)
- `@wordpress/blocks`, `@wordpress/block-editor`, `@wordpress/components`
- `@wordpress/element`, `@wordpress/i18n`, `@wordpress/api-fetch`
- `@wordpress/hooks`, `@wordpress/data`

Anything not on this list requires amending the constitution first.

## Allowed Composer dependencies

- Dev: `squizlabs/php_codesniffer`, `wp-coding-standards/wpcs`, `phpunit/phpunit`

## Allowed input sanitizers

- `sanitize_text_field`, `sanitize_email`, `sanitize_key`, `sanitize_file_name`
- `sanitize_hex_color`, `sanitize_textarea_field`
- `absint`, `floatval`, `(bool) rest_sanitize_boolean`
- `esc_url_raw` (for storage)
- `wp_kses_post`, `wp_kses` (with explicit allowlist)

## Allowed output escapers

- `esc_html`, `esc_attr`, `esc_url`, `esc_js`
- `wp_kses_post`, `wp_kses` (with explicit allowlist)
- `esc_html__`, `esc_attr__`, `esc_html_e`, `esc_attr_e` (translated)

## Allowed capability constants

- `manage_options` — admin-only settings
- `edit_posts` — content editors
- `read` — any logged-in user

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
