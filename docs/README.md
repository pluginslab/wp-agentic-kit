# Walkthrough

The kit's narrative companion. Read these in order if you've never set up an agentic WordPress workflow, or jump to a chapter if you want the deep-dive on one piece.

## Chapters

1. [Getting started](./01-getting-started.md) — clone, run setup.sh, open your first session
2. [CLAUDE.md (Description)](./02-claude-md.md) — the project brief the agent reads on every turn
3. [Skills](./03-skills.md) — naming the workflows you reach for repeatedly
4. [MCP servers](./04-mcp-servers.md) — connecting WordPress, the browser, GitHub, and beyond
5. [Sub-agents](./05-sub-agents.md) — delegation with context isolation and tool discipline
6. [Hooks](./06-hooks.md) — the deterministic safety net
7. [Permissions](./07-permissions.md) — what the agent can do without asking
8. [Putting it together](./08-putting-it-together.md) — one feature end-to-end through the harness

## The framing

Each chapter is anchored to one of the four D's of the [AI Fluency Framework](https://www.anthropic.com/ai-fluency) (Anthropic):

| D | Chapter |
|---|---|
| Delegação | Sub-agents, permissions, when to invoke a skill |
| Descrição | CLAUDE.md, AGENTS.md, skill prompts |
| Discernimento | The agent's own validation against tests, plus your code review |
| Diligência | Hooks — the things that must always run |

The harness is what makes the four D's tractable on a real project. Without it, you keep re-explaining; with it, your conventions persist and your safety nets are inescapable.
