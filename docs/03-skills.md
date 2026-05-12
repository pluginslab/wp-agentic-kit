# 3. Skills

## What a skill is

A named, reusable workflow. The agent invokes it explicitly (`/wordpress-development`) or implicitly when it matches the user's request. Each skill is a single markdown file at `.claude/skills/<name>/SKILL.md` with YAML frontmatter describing it and a body that's the system prompt for that workflow.

Skills are how your team's accumulated experience becomes executable. A senior engineer's mental playbook for "add a REST endpoint" — the questions to ask, the patterns to apply, the gotchas to avoid — written down once and reused on every endpoint.

## When to write a skill vs. just instruct

| Situation | Skill | Instruct |
|---|---|---|
| You'll do this more than three times | yes | |
| The workflow has structure (interview → generate → verify) | yes | |
| You want a sub-agent to use the same playbook | yes | |
| One-off, throwaway | | yes |
| Pure code generation, no decisions | | yes |

If you're typing the same multi-step instructions for the third time, that's the signal.

## Anatomy of the wordpress-development skill

The kit ships one skill, [`wordpress-development`](../.claude/skills/wordpress-development/). Read it as a template for your own.

```
.claude/skills/wordpress-development/
├── README.md                  # human-facing summary
├── SKILL.md                   # the agent-facing prompt (with frontmatter)
└── references/
    ├── SECURITY.md            # deep-dive loaded on demand via @
    └── BLOCKS.md              # ditto
```

### Frontmatter

```yaml
---
name: wordpress-development
description: One sentence. Used by the agent to decide when to invoke.
license: MIT
compatibility:
  wordpress: ">=6.7"
  php: ">=8.2"
---
```

The `description` matters: it's what the agent matches against the user's request to decide whether this skill is the right one to invoke.

### Body shape

The skill body is a system prompt. The kit's pattern:

1. **Mode detection** — new plugin vs. feature addition.
2. **Interview** — explicit questions, one at a time, with examples.
3. **Generation rules** — what file layout, what naming, what mandatory checks.
4. **Delivery checklist** — what to show the user when done.

Linking out via `@references/SECURITY.md` keeps the SKILL.md itself focused. The references load only when the agent decides it needs them.

## Adding your own

1. Create `.claude/skills/<your-skill>/SKILL.md`.
2. Frontmatter: `name`, `description`, optional `compatibility`, `license`.
3. Body: an interview-driven prompt. Keep questions explicit and ordered.
4. If the skill needs deep reference material (a long checklist, a style guide), add `references/*.md` files and `@`-reference them in SKILL.md.
5. Optionally add a sub-agent in `.claude/agents/` that specializes in part of the workflow.

## Versioning

Treat skills like code. Version them (in frontmatter or git tags), review changes, write commit messages explaining *why* the prompt changed. A skill is a small program; small programs deserve discipline.

---

← [CLAUDE.md](./02-claude-md.md) · Next: [MCP servers →](./04-mcp-servers.md)
