# 3. Skills

## What a skill is

A named, reusable workflow. The agent invokes it explicitly (`/wordpress-feature`) or implicitly when it matches the user's request. Each skill is a single markdown file at `.claude/skills/<name>/SKILL.md` with YAML frontmatter describing it and a body that's the system prompt for that workflow.

Skills are how your team's accumulated experience becomes executable. A senior engineer's mental playbook for "add a REST endpoint" — the questions to ask, the patterns to apply, the gotchas to avoid — written down once and reused on every endpoint.

This is the kit's **Delegação** layer: the structured handoff to the agent.

## When to write a skill vs. just instruct

| Situation | Skill | Instruct |
|---|---|---|
| You'll do this more than three times | yes | |
| The workflow has structure (interview → generate → verify) | yes | |
| You want a sub-agent to use the same playbook | yes | |
| One-off, throwaway | | yes |
| Pure code generation, no decisions | | yes |

If you're typing the same multi-step instructions for the third time, that's the signal.

## What ships in `.claude/skills/`

Two sources, one directory:

1. **The kit's own two skills:**
   - **`wordpress-scaffold`** — interview-driven workflow for spinning up a brand-new plugin. Identity → constitution → feature selection → spec + plan → generate. Used once per plugin.
   - **`wordpress-feature`** — interview-driven workflow for adding features to an existing plugin (or maintenance edits). Spec → plan → **plan freeze for human review** → implement → ship. Used per PR.
2. **The [WordPress/agent-skills](https://github.com/WordPress/agent-skills) library** — pulled fresh from `trunk` at scaffold time by the Node CLI. 15 skills covering blocks, themes, REST, abilities, performance, PHPStan, Playground, WP-CLI, and more. These are reference material — knowledge the main agent loads when relevant.

The kit's skills are *workflows* (interview → plan → generate → verify); the upstream skills are *expertise* the main agent leans on while executing.

```
.claude/skills/
├── wordpress-scaffold/         # kit-shipped, greenfield only
│   ├── README.md
│   └── SKILL.md
├── wordpress-feature/          # kit-shipped, feature + maintenance
│   ├── README.md
│   └── SKILL.md
├── wp-plugin-development/      # upstream, fetched by `npm create wp-ai-plugin`
├── wp-block-development/
├── wp-rest-api/
├── wp-abilities-api/
├── wp-playground/
├── wp-performance/
├── wp-phpstan/
├── wp-block-themes/
├── wp-interactivity-api/
├── wp-wpcli-and-ops/
├── wp-project-triage/
├── wp-plugin-directory-guidelines/
├── wordpress-router/
├── blueprint/
└── wpds/
```

The kit's skills share their reference material via `.claude/references/` (one level up) so plans, sub-agents, and the main agent all see the same `SECURITY.md`, `BLOCKS.md`, and `PLANNING.md` source of truth.

To refresh the upstream skills later, the simplest path is to scaffold a throwaway plugin (`npm create wp-ai-plugin /tmp/refresh`) and copy its `.claude/skills/wp-*` over yours.

## Anatomy of a kit skill

### Frontmatter

```yaml
---
name: wordpress-feature
description: One sentence (or short paragraph) describing when this skill applies. Used by the agent to decide whether to invoke.
---
```

Two required fields: `name` and `description`. Other fields (`allowed-tools`, `model`, `when_to_use`) are optional — see the [Claude Code skills docs](https://docs.claude.com/en/docs/claude-code/skills) for the full list. **Don't invent fields like `license` or `compatibility`** — they're silently ignored.

The `description` matters: it's what the agent matches against the user's request to decide whether this skill is the right one to invoke. Write it from the user's perspective ("when you want to..."), not from yours ("this skill does...").

### Body shape

The skill body is a system prompt. The kit's pattern:

1. **Mode detection** — which variant of the workflow applies (new plugin? feature? maintenance edit?).
2. **Planning** — write `spec.md`, `plan.md` into `.claude/plans/features/NNN-slug/` *before* generating code.
3. **Freeze** — for `wordpress-feature`, stop after the plan and require human review of the plan PR before implementation.
4. **Generate / implement** — file layout, naming, mandatory checks.
5. **Delivery checklist** — what to show the user when done.

Linking out via `@.claude/references/SECURITY.md` keeps the SKILL.md itself focused. The references load only when the agent decides it needs them.

## Adding your own

1. Create `.claude/skills/<your-skill>/SKILL.md`.
2. Frontmatter: at minimum `name` and `description`. Add `allowed-tools` if you want to restrict the tools available within the skill.
3. Body: an interview-driven prompt. Keep questions explicit and ordered.
4. If the skill needs deep reference material (a long checklist, a style guide), add it under `.claude/references/` and `@`-reference it.
5. Optionally add a sub-agent in `.claude/agents/` that specializes in the read-only audit step.

## Versioning

Treat skills like code. Version them via git, review changes, write commit messages explaining *why* the prompt changed. A skill is a small program; small programs deserve discipline.

## Slash commands — skills' simpler cousin

Skills are interview-driven workflows: mode detection, branching phases, conditional logic. **Slash commands** (`.claude/commands/<name>.md`) are one-step shortcuts: "always do exactly this sequence." When the user types `/<name>`, the command's body becomes the agent's marching orders for that turn.

The kit ships three:

| Command | What it wraps |
|---|---|
| `/plan-freeze [slug]` | Runs `scripts/open-plan-pr.sh` to commit `spec.md` + `plan.md` on a `plan/` branch and open a PR |
| `/audit-plan [slug]` | Dispatches the `plan-reviewer` sub-agent against the active feature's plan |
| `/ship-feature [slug]` | After the feature PR merges, marks `progress.md` complete and archives the dir |

Each auto-detects the active feature when called without an argument.

Use a command when the work is mechanical and the sequence is fixed. Use a skill when there are decisions to make along the way (interview, mode detection, conditional behavior). The same shipped script can power both — `/plan-freeze` is a thin wrapper over the same `scripts/open-plan-pr.sh` that `wordpress-feature` Phase 2.5 calls.

Frontmatter is `description` (shown in the slash command picker) and optional `argument-hint`. The body uses `$ARGUMENTS` to substitute whatever the user typed after the command name. See `.claude/commands/README.md` for the conventions and the three shipped examples.

---

← [Planning](./03-planning.md) · Next: [MCP servers →](./05-mcp-servers.md)
