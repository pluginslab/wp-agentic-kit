# `.claude/agents/`

Sub-agents the main Claude Code agent can delegate to. Each one runs in its own context window, with its own restricted tool set, so the main agent stays focused.

## Why use a sub-agent

The kit's bar for shipping a sub-agent: it has to do something a skill can't. In practice that means either **tool restriction** (the sub-agent literally can't call `Edit` / `Write`) or **context isolation** for work that would otherwise dump thousands of lines into the main agent's window.

A "specialist who writes blocks" or "specialist who writes REST endpoints" doesn't clear that bar — it's a skill in disguise. So the kit ships exactly one sub-agent.

## Shipped sub-agents

| Sub-agent | Tools | When to invoke |
|---|---|---|
| [`security-reviewer`](./security-reviewer.md) | Read, Grep, Glob, Bash | Before merging a PR, before a release, after any change to input handling |

Block and REST work is handled by the `wp-block-development` and `wp-rest-api` skills the kit pulls from [WordPress/agent-skills](https://github.com/WordPress/agent-skills) into `.claude/skills/`. The main agent loads them on demand — no handoff needed.

## How invocation works

Inside Claude Code:

```
> use the security-reviewer subagent to audit the changes on this branch
```

The main agent recognizes the sub-agent name, spawns it with its own context, and reports back when it finishes.

## Adding your own

1. Drop a markdown file in this directory.
2. Frontmatter requires `name`, `description`, and `tools` (comma-separated list).
3. The body is the sub-agent's system prompt — keep it focused. One job, one playbook.
4. Reference shared knowledge via `@.claude/skills/...` paths so sub-agents and the main agent share the same source of truth.

## Naming convention

- kebab-case filename matches the `name:` in frontmatter.
- Verb-noun if the sub-agent acts on something (`security-reviewer`, `migration-auditor`).
- Plural-noun if it manages a set (`release-manager`).

## Tool restrictions

The `tools:` line is a permission allowlist. If you omit a tool, the sub-agent can't call it. Use this aggressively — a sub-agent with no `Edit`/`Write` can't go off-script. The security reviewer is the model: read-only by design.
