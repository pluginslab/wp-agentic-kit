# create-wp-ai-plugin

Interactive scaffolder for [wp-agentic-kit](https://github.com/pluginslab/wp-agentic-kit). Fetches the kit at the requested git ref and replaces the example plugin identity with values you choose.

## Usage

```bash
npm create wp-ai-plugin my-cool-plugin
# or
npx create-wp-ai-plugin my-cool-plugin
```

You'll be prompted for:

- **Plugin name** — free text, e.g. `My Cool Plugin`
- **Vendor prefix** — optional, e.g. `pl`, `acme`
- **One-sentence description** — optional, fills the placeholder in `CLAUDE.md` / `AGENTS.md`
- **Author** — optional, fills the `Author:` line
- **Minimum WordPress version** — pick from 6.6 / 6.7 / 6.8 / 7.0
- **Minimum PHP version** — pick from 8.0 / 8.1 / 8.2 / 8.3 / 8.4

The CLI derives the slug, namespace, and constant/function prefixes from your inputs, then substitutes every occurrence across the kit's files.

### Pinning a release

```bash
npm create wp-ai-plugin my-cool-plugin -- --ref v0.2.0
```

Any branch, tag, or commit SHA on the upstream repo works.

## Requirements

- Node.js 18+ and `npm`
- PHP 8.0+ and `composer`
- `git` on `$PATH` (used to initialise a fresh repo with a `scaffold` tag on the initial commit)

Missing composer or npm doesn't abort the scaffold — the corresponding install step is skipped and surfaced in the final summary so you can run it manually.

## What it does

1. Fetches the repo tarball from `codeload.github.com` at the requested ref.
2. Removes kit-only artifacts (`cli/`, `docs/`, `.github/`).
3. Substitutes:
   - `pl-example` → your slug
   - `PLExample` → your namespace
   - `PL_EXAMPLE_*` → your constant prefix
   - `pl_example_*` → your function prefix
   - `Example Plugin` → your plugin name
   - `**WordPress:** 6.7+` and `minimum_supported_wp_version` → your WP version
   - `**PHP:** 8.2+`, `composer.json#require.php`, and `testVersion` → your PHP version
   - placeholder description / author sentences if you supply them
4. Strips kit-meta HTML comments from `CLAUDE.md` and `AGENTS.md`.
5. Runs `composer install` and `npm install` foregrounded with a spinner. Each step's full output is captured to `/tmp/setup-<step>-<slug>.log` and only surfaced on failure.
6. Runs three foreground indexing / sync steps with spinners (also logged to `/tmp/setup-<step>-<slug>.log`):
   - Clones [WordPress/agent-skills](https://github.com/WordPress/agent-skills) (`trunk`) into `.claude/skills/`, preserving any skill dir already present in the scaffold.
   - `wp-devdocs-mcp` indexes fresh WP 7.0 sources (wp-ai-client, abilities-api).
   - `wp-blockmarkup-mcp` indexes Gutenberg core blocks.
7. Initialises a fresh git repo and tags the initial commit `scaffold` so `git reset --hard scaffold` has a stable anchor.

## License

MIT
