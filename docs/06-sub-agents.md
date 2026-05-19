# 5. Sub-agents

## Why delegate

Three reasons to spin up a sub-agent instead of doing the work in the main thread:

1. **Context isolation** — a deep code review or a wide search shouldn't bloat the main agent's working memory. Sub-agents have their own context window.
2. **Tool discipline** — restrict what the sub-agent can do. The security reviewer in this kit has no `Edit` or `Write`. It can't accidentally "fix" anything you didn't ask for.
3. **Parallelism** — independent sub-agents run concurrently. Three reviews of the same diff in the time it takes for one.

In the AI Fluency Framework, sub-agents make **Discernimento** concrete: independent judgement before a human signs off, with the tool restriction making "no, you can't fix it yourself" structurally enforced.

## The kit's sub-agents

The kit ships two — both read-only audits. The bar for shipping more is high: a sub-agent has to do something a skill can't.

### `plan-reviewer`

Read-only. Audits a feature's `spec.md` and `plan.md` against the conventions in `PLANNING.md` and the project's `constitution.md`. Reports findings with `file:line · severity · rule · suggested fix`. Invoked during Phase 2.5 (plan freeze) of `wordpress-feature`, after `scripts/open-plan-pr.sh` opens the plan PR and before a human signs off.

Use it: after writing a plan, before requesting human review. It catches the mechanical misses (missing `Out of scope`, steps without file paths, a library that isn't in the constitution) so the human review can focus on intent and approach.

### `security-reviewer`

Read-only. Audits PHP and JS against the project's `SECURITY.md` checklist. Reports findings with `file:line · severity · rule · suggested fix`. Never edits.

Use it: before opening a feature PR, before tagging a release, after touching input handling.

The read-only restriction is the whole point of both. A skill could *describe* the audit; only a sub-agent with a restricted tool list can *enforce* that the audit doesn't turn into a drive-by refactor. That structural guarantee is what makes it worth the extra hop.

### Why not block-builder / rest-builder?

Tempting, but skills cover that ground more cheaply. A sub-agent without tool restrictions is just a skill with extra ceremony — same context isolation cost, same prompt-as-source-of-truth, no enforcement. Block and REST work is handled by the `wp-block-development` and `wp-rest-api` skills the kit pulls in from [WordPress/agent-skills](https://github.com/WordPress/agent-skills).

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
```

The main agent recognizes the sub-agent by name, spawns it with its own context, hands off the task, and integrates the result when the sub-agent reports back.

You can also let the main agent decide. The description in sub-agent frontmatter helps it match user intent.

## When NOT to use a sub-agent

- One-shot quick task. The overhead of spinning up a sub-agent isn't worth it.
- The work needs to see what the main agent has been doing. Sub-agents start cold.
- You'd have to pass a lot of state. Better to let the main agent do it directly.

## Adding your own

1. `.claude/agents/<name>.md` — frontmatter with `name`, `description`, `tools`.
2. Body: a focused system prompt. One job, one playbook.
3. Reference shared docs via `@.claude/references/...` so sub-agents and the main agent share the same source of truth.
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

← [MCP servers](./05-mcp-servers.md) · Next: [Hooks →](./07-hooks.md)
