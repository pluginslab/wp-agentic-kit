# 5. Sub-agents

## Why delegate

Three reasons to spin up a sub-agent instead of doing the work in the main thread:

1. **Context isolation** — a deep code review or a wide search shouldn't bloat the main agent's working memory. Sub-agents have their own context window.
2. **Tool discipline** — restrict what the sub-agent can do. The security reviewer in this kit has no `Edit` or `Write`. It can't accidentally "fix" anything you didn't ask for.
3. **Parallelism** — independent sub-agents run concurrently. Three reviews of the same diff in the time it takes for one.

In the AI Fluency Framework, sub-agents make **Delegação** concrete: you don't just delegate a task, you delegate it to a specialist with bounded permissions.

## The kit's three sub-agents

### `security-reviewer`

Read-only. Audits PHP and JS against the project's `SECURITY.md` checklist. Reports findings with `file:line · severity · rule · suggested fix`. Never edits.

Use it: before opening a PR, before tagging a release, after touching input handling.

### `gutenberg-block-builder`

Full toolset. Specialist in Block API v3. Knows `block.json` schema, when to pick dynamic over static rendering, the WordPress component library.

Use it: when adding a block or refactoring one. The main agent can hand off the whole task.

### `rest-endpoint-builder`

Full toolset. Builds REST controllers that are safe by default — real permission callbacks, sanitize/validate callbacks per arg, `prepare_item_for_response` for shape consistency.

Use it: when adding endpoints. Especially useful because REST mistakes are the most common security blunders in WordPress plugins.

## Tool restriction is the lever

The `tools:` line in a sub-agent's frontmatter is an allowlist. Omit a tool and the sub-agent can't call it.

```yaml
---
name: security-reviewer
tools: Read, Grep, Glob, Bash
---
```

No `Edit`, no `Write`. The sub-agent is structurally incapable of modifying code. Even if the prompt asked it to (and it doesn't), the harness refuses.

This is the engineering trick: **bound the blast radius at the framework level, not the prompt level.** Prompts are advisory; tool allowlists are enforced.

## How invocation works

From inside Claude Code:

```
> use the security-reviewer subagent to audit the changes on this branch
> have the gutenberg-block-builder add an order-status block, dynamic render
```

The main agent recognizes the sub-agent by name, spawns it with its own context, hands off the task, and integrates the result when the sub-agent reports back.

You can also let the main agent decide. The descriptions in sub-agent frontmatter help it match user intent to the right specialist.

## When NOT to use a sub-agent

- One-shot quick task. The overhead of spinning up a sub-agent isn't worth it.
- The work needs to see what the main agent has been doing. Sub-agents start cold.
- You'd have to pass a lot of state. Better to let the main agent do it directly.

## Adding your own

1. `.claude/agents/<name>.md` — frontmatter with `name`, `description`, `tools`.
2. Body: a focused system prompt. One job, one playbook.
3. Reference shared docs via `@.claude/skills/...` so sub-agents and the main agent share the same source of truth.
4. Decide on tool restrictions deliberately. Default to less.

## Sub-agents vs. skills

| | Skill | Sub-agent |
|---|---|---|
| Lives where | `.claude/skills/<name>/SKILL.md` | `.claude/agents/<name>.md` |
| Runs in | Main agent's context | Its own context |
| Tool restriction | inherits main agent | can restrict via `tools:` |
| Best for | Workflows / interviews | Specialist tasks with isolation |

A skill is "how to do this workflow." A sub-agent is "a specialist who does this kind of work." Sometimes you want both — a skill describes the workflow, a sub-agent specializes in executing it.

---

← [MCP servers](./04-mcp-servers.md) · Next: [Hooks →](./06-hooks.md)
