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
| 5 | [`.claude/skills/wordpress-development/`](./.claude/skills/wordpress-development/) | Interview-driven plugin / feature scaffolder |
| 6 | [`.claude/agents/`](./.claude/agents/) | Sub-agents: security review, block builder, REST endpoint |
| 7 | [`.claude/hooks/`](./.claude/hooks/) | Pre-commit gate (blocking) and post-edit lint (informational) |
| 8 | [`docs/`](./docs/) | Eight-chapter walkthrough from zero to a fully configured harness |

## Quick start

```bash
git clone https://github.com/pluginslab/wp-agentic-kit my-cool-plugin
cd my-cool-plugin
./setup.sh
```

`setup.sh` asks for your plugin name and an optional vendor prefix, derives the slug / namespace / constant / function prefixes, then runs a find/replace across every file so the example values become yours. Review with `git diff`, commit, delete the script.

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
