# `.claude/agents/`

Sub-agents the main Claude Code agent can delegate to. Each one runs in its own context window, with its own restricted tool set, so the main agent stays focused.

## Maps to the talk's framework

**Discernimento.** Sub-agents are the discernment D — independent, narrow-scope judgement before a human signs off. Read-only by design: they surface what a human should know, never apply fixes.

## Why use a sub-agent

The kit's bar for shipping a sub-agent: it has to do something a skill can't. In practice that means either **tool restriction** (the sub-agent literally can't call `Edit` / `Write`) or **context isolation** for work that would otherwise dump thousands of lines into the main agent's window.

A "specialist who writes blocks" or "specialist who writes REST endpoints" doesn't clear that bar — it's a skill in disguise. Nor does "a planning agent" or "a coding agent": planning is already a skill, and a coding agent needs the main thread's context and hands back a diff rather than a conclusion. So the kit ships three sub-agents, all read-only, each covering one thing the main agent can't do safely or cheaply in its own window.

## Shipped sub-agents

| Sub-agent | Tools | When to invoke |
|---|---|---|
| [`plan-reviewer`](./plan-reviewer.md) | Read, Grep, Glob, Bash | During Phase 2.5 of `wordpress-feature`, after `scripts/open-plan-pr.sh` opens the plan PR. Audits spec + plan against PLANNING.md and the constitution. |
| [`security-reviewer`](./security-reviewer.md) | Read, Grep, Glob, Bash | Before merging a feature PR, before a release, after any change to input handling. |
| [`playground-verifier`](./playground-verifier.md) | Read, Grep, Glob, Bash, `wp-playground` MCP | Before merging a feature PR, and right after a scaffold. Boots the plugin in a real WordPress instance and verifies it activates, serves its routes, and uninstalls cleanly. |

The three map onto what can go wrong at three different times: the plan is wrong (`plan-reviewer`), the code is unsafe (`security-reviewer`), or the code is fine on paper and broken in practice (`playground-verifier`). The last one is the only gate in the kit that boots WordPress — everything else, `quality.sh` included, is static.

`security-reviewer` and `playground-verifier` read the same diff and don't depend on each other, so dispatch them in the same message and let them run concurrently.

Block and REST work is handled by the `wp-block-development` and `wp-rest-api` skills the kit pulls from [WordPress/agent-skills](https://github.com/WordPress/agent-skills) into `.claude/skills/` — those run on the main agent's context, no handoff needed.

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
4. Reference shared knowledge via `@.claude/references/...` paths so sub-agents and the main agent share the same source of truth.

## Naming convention

- kebab-case filename matches the `name:` in frontmatter.
- Verb-noun if the sub-agent acts on something (`security-reviewer`, `migration-auditor`).
- Plural-noun if it manages a set (`release-manager`).

## Tool restrictions

The `tools:` line is a permission allowlist. If you omit a tool, the sub-agent can't call it. Use this aggressively — a sub-agent with no `Edit`/`Write` can't go off-script. The security reviewer is the model: read-only by design.
