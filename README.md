# wp-agentic-kit

A starter kit for building WordPress with agentic engineering. The harness, the skills, and the MCP servers Marcel uses every day, packaged so you can install once and start delegating implementation on Monday morning.

Companion to the talk **"A Nova Era do WordPress: De Developer a Arquiteto com Engenharia Agêntica"** at WordCamp Portugal 2026.

## Why this exists

Senior WordPress developers don't need to write boilerplate anymore. What we still need to do is design the system that writes it. The talk frames that system in four D's; the kit makes each one concrete:

| Talk D | Kit piece | What it does |
|---|---|---|
| **Delegação** | [`.claude/skills/`](./.claude/skills/) | Interview-driven workflows (`wordpress-scaffold`, `wordpress-feature`) that hand structured work to the agent |
| **Descrição** | [`.claude/plans/`](./.claude/plans/) + `CLAUDE.md` / `AGENTS.md` | Durable description the agent reads first — constitution, spec, plan, progress |
| **Discernimento** | [`.claude/agents/`](./.claude/agents/) | Read-only sub-agents (`plan-reviewer`, `security-reviewer`) — independent judgement before sign-off |
| **Diligência** | [`.claude/hooks/`](./.claude/hooks/) | Deterministic gates: pre-commit quality, post-edit lint, plan injection, progress timestamping |

Plus curated MCP servers and the scaffolding CLI that sets it all up in one command.

## What's in here

| | | |
|---|---|---|
| 1 | [`CLAUDE.md`](./CLAUDE.md) | Annotated project instructions for any WP project |
| 2 | [`AGENTS.md`](./AGENTS.md) | Cross-tool mirror (Codex, Cursor, Gemini CLI, Copilot, Windsurf) |
| 3 | [`.claude/settings.json`](./.claude/) | Permissions and allowed commands |
| 4 | [`.mcp.json`](./.mcp.json) + [`mcp/`](./mcp/) | MCP servers shipped via project-scoped config |
| 5 | [`.claude/skills/`](./.claude/skills/) | Two skills: `wordpress-scaffold` (greenfield plugin) and `wordpress-feature` (feature + maintenance). Each writes plan artifacts before generating code. Plus the [WordPress/agent-skills](https://github.com/WordPress/agent-skills) library pulled fresh on scaffold |
| 6 | [`.claude/plans/`](./.claude/plans/) | Durable cross-session memory — `constitution.md` (strict for security, default for dependencies), per-feature `spec.md` / `plan.md` / `progress.md`, archived plans |
| 7 | [`.claude/agents/`](./.claude/agents/) | Two read-only sub-agents: `plan-reviewer` (audits spec/plan) and `security-reviewer` (audits code). Block / REST work is covered by skills. |
| 8 | [`.claude/hooks/`](./.claude/hooks/) | Pre-commit gate (blocking), post-edit lint, `UserPromptSubmit` plan injection, `Stop` progress timestamp, `SessionStart` orientation banner |
| 9 | [`.claude/commands/`](./.claude/commands/) | Slash commands wrapping common operations — `/plan-freeze`, `/audit-plan`, `/ship-feature` |
| 10 | [`scripts/`](./scripts/) | `quality.sh` — single source of truth for "what is quality"; `open-plan-pr.sh` — plan-freeze automation |
| 11 | [`tests/`](./tests/) | Bash test suite for the kit's own hooks. Integrated into `quality.sh`. |
| 12 | [`docs/`](./docs/) | Nine-chapter walkthrough from zero to a fully configured harness |

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
- [x] 5 — Skills (scaffold + feature, with planning phases)
- [x] 6 — Plans (constitution + per-feature spec/plan/progress)
- [x] 7 — Sub-agents (plan-reviewer + security-reviewer)
- [x] 8 — Hooks (pre-commit, post-edit, user-prompt-submit, stop)
- [x] 9 — Scripts (quality.sh, open-plan-pr.sh)
- [x] 10 — Tests (hook test suite, integrated into quality.sh)
- [x] 11 — Docs walkthrough

## License

MIT. Take it, fork it, ship faster.
