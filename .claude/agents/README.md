# `.claude/agents/`

Sub-agents the main Claude Code agent can delegate to. Each one runs in its own context window, with its own restricted tool set, so the main agent stays focused.

## Why use a sub-agent

- **Context isolation** — a deep code review doesn't bloat the main agent's working memory.
- **Tool discipline** — the security reviewer has no `Edit` or `Write`, so it can't accidentally "fix" things you didn't ask for.
- **Parallelism** — independent sub-agents can run concurrently.
- **Reusable specialty** — write the security playbook once; invoke it on every PR.

## Shipped sub-agents

| Sub-agent | Tools | When to invoke |
|---|---|---|
| [`security-reviewer`](./security-reviewer.md) | Read, Grep, Glob, Bash | Before merging a PR, before a release, after any change to input handling |
| [`gutenberg-block-builder`](./gutenberg-block-builder.md) | full | When adding or refactoring a Gutenberg block |
| [`rest-endpoint-builder`](./rest-endpoint-builder.md) | full | When adding or extending a REST API route |

## How invocation works

Inside Claude Code:

```
> use the security-reviewer subagent to audit the changes on this branch
> have the gutenberg-block-builder add an order-status block, dynamic render
```

The main agent recognizes the sub-agent name, spawns it with its own context, and reports back when it finishes.

## Adding your own

1. Drop a markdown file in this directory.
2. Frontmatter requires `name`, `description`, and `tools` (comma-separated list).
3. The body is the sub-agent's system prompt — keep it focused. One job, one playbook.
4. Reference shared knowledge via `@.claude/skills/...` paths so sub-agents and the main agent share the same source of truth.

## Naming convention

- kebab-case filename matches the `name:` in frontmatter.
- Verb-noun if the sub-agent acts on something (`security-reviewer`, `block-builder`).
- Plural-noun if it manages a set (`release-manager`).

## Tool restrictions

The `tools:` line is a permission allowlist. If you omit a tool, the sub-agent can't call it. Use this aggressively — a sub-agent with no `Edit`/`Write` can't go off-script. The security reviewer is the model: read-only by design.
