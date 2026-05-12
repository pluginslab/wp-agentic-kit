# 4. MCP servers

## What MCP is

Model Context Protocol — an open standard for exposing tools to coding agents. Think of it as USB for AI: a server implements MCP, and any compatible client (Claude Code, Codex, Cursor, etc.) can use its tools.

For a WordPress workflow, this means the agent can:

- Look up real WordPress function signatures (`wp-devdocs`).
- Validate Gutenberg block markup against the canonical schema (`wp-blockmarkup`).
- Spin up a throwaway WordPress instance to test a plugin (`wp-playground`).
- Inspect rendered HTML, run Lighthouse, capture network traffic (`chrome-devtools`).
- Open PRs, search code, fetch issues (`github`).

Without MCP, the agent guesses or scrapes the web. With it, the agent talks to the source.

## Project-scoped vs. user-scoped

The kit uses **project-scoped** MCPs via [`.mcp.json`](../.mcp.json) at the project root. Claude Code reads this file automatically. Anyone who clones the repo gets the same servers — no per-developer install dance.

User-scoped MCPs (registered with `claude mcp add --scope user`) work everywhere on your machine but don't travel with the project. Use those for tools that aren't project-specific (Gmail, Calendar, etc.).

## The kit's curated list

| Server | Why it's here | Auth? |
|---|---|---|
| `wp-devdocs` | WordPress reference truth | no |
| `wp-blockmarkup` | Block markup schemas | no |
| `wp-playground` | Ephemeral test environments | no |
| `github` | Repo / PR / issue access | optional (token for private repos) |
| `chrome-devtools` | Visual + perf checks | no |

All five run via `npx`, so the first call fetches them. Nothing to install up front.

## The allowlist must match

`.mcp.json` registers the server. `.claude/settings.json` `permissions.allow` decides whether the agent can call its tools without asking. If you add a server, you also add `mcp__<server-name>` to the allowlist — otherwise every tool call hits a permission prompt.

This is the single most common friction point. Add both, or remove both. The kit's `mcp/README.md` calls this out at the top.

## Authentication

If a server needs credentials, add an `env` block in `.mcp.json`:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

Export `GITHUB_TOKEN` from your shell (`~/.zshrc` or via direnv). Never commit the actual token. Add `${VAR}` references to `.mcp.json`; the actual value stays in your environment.

## Discovery

Browse the public MCP registry at https://github.com/modelcontextprotocol/servers for ideas. Common useful additions for WordPress work:

- `filesystem` — read/write files outside the project (drafts, downloads).
- `postgres` / `mysql` — direct DB queries when you're debugging.
- `puppeteer` — alternative to chrome-devtools for browser automation.
- `slack` — post deploy notifications.

Add only what you'd reach for at least once a week. Each MCP costs context tokens and adds a tool the model has to consider on every turn.

## Removing or disabling

To temporarily disable an MCP without removing it, comment-equivalent in JSON doesn't exist — but you can move the entry into a `disabledServers` block (custom, you ignore it in code) or just delete it and reinstate later from git history. Simpler: remove the allowlist line in `.claude/settings.json`; the server still loads but the agent has to ask before using it. Useful when troubleshooting.

## Context bloat warning

Each MCP server contributes its tool list to the agent's context every turn. Five servers is fine. Twenty-five is not — research (Carey, AI Engineer Conf 2025) shows context bloat from over-eager MCP configurations is a real failure mode. Curate.

---

← [Skills](./03-skills.md) · Next: [Sub-agents →](./05-sub-agents.md)
