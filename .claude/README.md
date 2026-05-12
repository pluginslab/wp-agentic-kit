# `.claude/`

Project-level configuration for Claude Code. Everything in here is committed and shared with your team. Anything personal goes in `settings.local.json` (gitignored).

## `settings.json`

Defines what the agent can do without asking. The kit ships a WordPress-focused allowlist.

### Bash allowlist

| Command | What it unlocks |
|---|---|
| `wp:*` | WP-CLI — managing posts, options, users, plugins, the works |
| `wp-env:*` | Local WordPress via Docker (`wp-env start`, `wp-env stop`) |
| `composer:*` | PHP dependency management |
| `php:*` | Running PHP scripts directly |
| `npm:*` / `pnpm:*` / `npx:*` | JS tooling and block/extension builds |
| `git:*` | Version control |
| `gh:*` | GitHub CLI (PRs, issues, releases) |
| `curl:*` | Hitting REST endpoints during development |
| `./vendor/bin/phpcs`, `phpcbf`, `phpunit`, `phpstan`, `psalm` | Quality gates |

### MCP allowlist

| Server | Purpose |
|---|---|
| `wp-devdocs` | Canonical WordPress function and hook reference |
| `wp-blockmarkup` | Gutenberg block markup schemas |
| `wp-playground` | Ephemeral WordPress instances for testing |
| `github` | Repo, PRs, issues, code search |
| `chrome-devtools` | Inspect rendered output, run Lighthouse |

These servers are configured separately in [`../mcp/`](../mcp/). The allowlist here just means "don't ask permission every time you call one of them."

## `settings.local.json` (gitignored)

For your personal additions: extra tools, MCPs, or experimental permissions you don't want to commit. Claude Code merges this on top of `settings.json`.

Example:

```json
{
  "permissions": {
    "allow": [
      "Bash(docker:*)",
      "Bash(ssh:*)"
    ]
  }
}
```

## What's not in here (deliberately)

- `effortLevel` — keep that in your global `~/.claude/settings.json`; it's a personal preference, not a project policy.
- `enabledPlugins` — install plugins yourself; the kit doesn't dictate.
- `model` — let your own setup decide which model to use.

## Adding a permission

When the agent gets stopped mid-task asking for the same command three times, add it here. That's the same iteration loop as `CLAUDE.md`: catch a recurring friction, codify the rule, move on.
