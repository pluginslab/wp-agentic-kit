# Walkthrough

The kit's narrative companion. Read these in order if you've never set up an agentic WordPress workflow, or jump to a chapter if you want the deep-dive on one piece.

## Chapters

1. [Getting started](./01-getting-started.md) — scaffold with `npm create wp-ai-plugin`, open your first session
2. [CLAUDE.md](./02-claude-md.md) — the project brief the agent reads on every turn
3. [Planning](./03-planning.md) — constitution, spec, plan, progress — the durable memory across sessions
4. [Skills](./04-skills.md) — naming the workflows you reach for repeatedly (`wordpress-scaffold`, `wordpress-feature`)
5. [MCP servers](./05-mcp-servers.md) — connecting WordPress, the browser, GitHub, and beyond
6. [Sub-agents](./06-sub-agents.md) — delegation with context isolation and tool discipline (`plan-reviewer`, `security-reviewer`)
7. [Hooks](./07-hooks.md) — the deterministic safety net
8. [Permissions](./08-permissions.md) — what the agent can do without asking
9. [Putting it together](./09-putting-it-together.md) — one feature end-to-end through the harness

## The framing

Each piece of the kit maps to one of the four D's of the [AI Fluency Framework](https://www.anthropic.com/ai-fluency):

| D | Kit piece | Chapter |
|---|---|---|
| **Delegação** | `.claude/skills/` (`wordpress-scaffold`, `wordpress-feature`) | 4 |
| **Descrição** | `CLAUDE.md`, `AGENTS.md`, `.claude/plans/` (constitution, spec, plan, progress) | 2, 3 |
| **Discernimento** | `.claude/agents/` (`plan-reviewer`, `security-reviewer`) | 6 |
| **Diligência** | `.claude/hooks/` (pre-commit, post-edit, user-prompt-submit, stop) | 7 |

The harness is what makes the four D's tractable on a real project. Without it, you keep re-explaining; with it, your conventions persist and your safety nets are inescapable.
