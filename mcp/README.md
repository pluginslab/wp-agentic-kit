# MCP servers

The kit ships project-scoped MCP servers via [`../.mcp.json`](../.mcp.json) at the project root. When Claude Code (or any tool that reads `.mcp.json`) opens this project, the servers below are available with zero install steps. They're all `npx`-based, so the first call fetches them.

> **Heads up:** if you add a server to `.mcp.json`, also add `mcp__<server-name>` to the allowlist in [`../.claude/settings.json`](../.claude/settings.json) — otherwise the agent will ask permission every time it calls a tool.

## What's in the box

### `wp-devdocs`
Canonical WordPress function, hook, and class reference. Use when you need the real signature, deprecation status, or @since tag for a WP API — better than guessing or searching the web.

- Package: `wp-devdocs-mcp`
- Source: https://www.npmjs.com/package/wp-devdocs-mcp

### `wp-blockmarkup`
Block markup schemas and validation. Use when generating or validating Gutenberg block serialised markup — beats hand-rolling JSON comments.

- Package: `wp-blockmarkup-mcp`
- Source: https://www.npmjs.com/package/wp-blockmarkup-mcp

### `wp-playground`
Spin up ephemeral WordPress instances for testing. Use when you want to verify a plugin works without polluting your local environment.

- Package: `wp-playground-mcp`
- Source: https://www.npmjs.com/package/wp-playground-mcp

### `github`
Repos, PRs, issues, code search. Use for releases, opening PRs, fetching issue context.

- Package: `@modelcontextprotocol/server-github`
- Auth: optional. Public repos work without a token; for private repos see [Authentication](#authentication) below.

### `chrome-devtools`
Headless Chrome via DevTools Protocol. Use for visual checks on rendered blocks, console / network inspection, Lighthouse audits.

- Package: `chrome-devtools-mcp`
- Source: https://github.com/ChromeDevTools/chrome-devtools-mcp

## Authentication

Some servers need credentials. Add an `env` block in `.mcp.json`:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

Export `GITHUB_TOKEN` in your shell (`~/.zshrc` or via direnv). Never commit the actual token.

## Adding more MCPs

1. Edit `.mcp.json` and add the server block.
2. Edit `.claude/settings.json` and add `"mcp__<name>"` to `permissions.allow`.
3. Restart Claude Code so it picks up the new server.

Browse the registry at https://github.com/modelcontextprotocol/servers for ideas. Common useful additions: `filesystem`, `postgres`, `puppeteer`, `slack`.

## Codex equivalent

Codex reads MCPs from `~/.codex/config.toml` (user scope) or a project-scoped file. Same idea, different syntax:

```toml
[mcp_servers.wp-devdocs]
command = "npx"
args = ["wp-devdocs-mcp"]
```

For now this kit only ships the Claude Code config (`.mcp.json`). If you use Codex too, mirror the entries into `~/.codex/config.toml`.

## Removing a server

1. Delete its block from `.mcp.json`.
2. Remove the matching `"mcp__<name>"` line from `.claude/settings.json` (optional but tidy).
