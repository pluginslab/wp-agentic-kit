# wp-agentic-kit

A starter kit for building WordPress with agentic engineering. The harness, the skills, and the MCP servers Marcel uses every day, packaged so you can install once and start delegating implementation on Monday morning.

Companion to the talk **"A Nova Era do WordPress: De Developer a Arquiteto com Engenharia Agêntica"** at WordCamp Portugal 2026.

## Why this exists

Senior WordPress developers don't need to write boilerplate anymore. What we still need to do is design the system that writes it. This kit codifies that system:

- **CLAUDE.md / AGENTS.md** templates that tell the agent how WordPress projects work.
- **Skills** for the recurring jobs: scaffold a plugin, add a block, review for security.
- **MCP servers** curated for WordPress: docs, block markup, Playground, dev tools.
- **Hooks** that enforce the boundaries the agent can't be trusted to remember.

If the talk taught the four D's (Delegação, Descrição, Discernimento, Diligência), this repo is the Descrição layer made executable.

## What's in here

| | | |
|---|---|---|
| 1 | [`CLAUDE.md`](./CLAUDE.md) | Annotated project instructions for any WP project |
| 2 | [`AGENTS.md`](./AGENTS.md) | Cross-tool mirror (Codex, Cursor, Gemini CLI, Copilot, Windsurf) |
| 3 | [`.claude/settings.json`](./.claude/) | Permissions and allowed commands |
| 4 | [`.mcp.json`](./.mcp.json) + [`mcp/`](./mcp/) | MCP servers shipped via project-scoped config |
| 5 | [`.claude/skills/`](./.claude/skills/) | Interview-driven plugin / feature scaffolder + the [WordPress/agent-skills](https://github.com/WordPress/agent-skills) library pulled fresh on scaffold |
| 6 | [`.claude/agents/`](./.claude/agents/) | One sub-agent: `security-reviewer` (read-only audit). Block / REST work is covered by skills, not sub-agents. |
| 7 | [`.claude/hooks/`](./.claude/hooks/) | Pre-commit gate (blocking) and post-edit lint (informational) |
| 8 | [`docs/`](./docs/) | Eight-chapter walkthrough from zero to a fully configured harness |

## Quick start

```bash
npm create wp-ai-plugin my-cool-plugin
# or
npx create-wp-ai-plugin my-cool-plugin
```

The interactive scaffolder asks for the plugin name, an optional vendor prefix, a one-sentence description, an author, and then lets you pick the minimum WordPress and PHP versions from a short list. It fetches the kit from GitHub at the requested git ref, derives the slug / namespace / constant / function prefixes, runs a find-and-replace across every file, runs `composer install` and `npm install`, pulls [`WordPress/agent-skills`](https://github.com/WordPress/agent-skills) into `.claude/skills/`, and initialises a fresh git repo with a `scaffold` tag on the initial commit.

**Prerequisites:** Node 18+ and `npm`, PHP 8.2+ and `composer`, `git` on `$PATH`. The CLI source lives in [`cli/`](./cli/), published to npm as [`create-wp-ai-plugin`](https://www.npmjs.com/package/create-wp-ai-plugin).

Need to pin a release?

```bash
npm create wp-ai-plugin my-cool-plugin -- --ref v0.2.0
```

If you'd rather adopt the kit into an existing plugin, copy individual pieces (`CLAUDE.md`, `AGENTS.md`, `.claude/`, `mcp/`) into your project and replace the example values by hand.

## Status

This kit is being built live alongside the talk. Each piece lands in its own commit so you can see the harness assemble step by step.

- [x] 1 — CLAUDE.md
- [x] 2 — AGENTS.md
- [x] 3 — settings.json
- [x] 4 — MCP servers
- [x] 5 — Skills
- [x] 6 — Sub-agents
- [x] 7 — Hooks
- [x] 8 — Docs walkthrough

## License

MIT. Take it, fork it, ship faster.
