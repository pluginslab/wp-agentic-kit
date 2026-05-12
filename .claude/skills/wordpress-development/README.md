# wordpress-development skill

Interview-driven scaffolding for WordPress plugins and features. Generates secure, standards-compliant code targeting WordPress 6.7+ and PHP 8.2+.

## Invoke

Inside a Claude Code session in this project:

```
/wordpress-development
```

The agent asks what you want to build, collects the identifying details (name, slug, namespace), and generates the files.

## Modes

| Mode | Triggered when | What it does |
|---|---|---|
| New plugin | No plugin main file detected in CWD | Scaffolds a full plugin with selected features |
| Feature | Plugin main file detected | Adds one feature (block, REST, settings, extension) into the existing plugin |

## Features it can generate

- Plugin scaffold (bootstrap, headers, uninstall)
- Settings page (Settings API, tabbed UI, type-safe sanitization)
- REST API controller + example endpoint
- Gutenberg block (block.json + edit/save + auto-registration)
- Editor extension (sidebar panel / toolbar button)
- Custom post type / taxonomy
- WP-CLI command

## What's enforced

- WordPress Coding Standards (PHPCS-ready)
- The full security checklist in [`references/SECURITY.md`](references/SECURITY.md): sanitize, escape, nonce, capability, prepare
- Modern PHP 8.2+ syntax (constructor promotion, readonly, enums where useful)
- Block API v3 for any Gutenberg work — see [`references/BLOCKS.md`](references/BLOCKS.md)

## License

MIT.
