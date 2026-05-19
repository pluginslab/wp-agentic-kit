# `.claude/commands/`

Project-scoped slash commands. Type `/<name>` in a Claude Code session and the command's body becomes the agent's marching orders for that turn.

## Shipped commands

| Command | What it does |
|---|---|
| `/plan-freeze [slug]` | Commits the active feature's `spec.md` + `plan.md`, pushes a `plan/` branch, opens a PR. Wraps `scripts/open-plan-pr.sh`. |
| `/audit-plan [slug]` | Dispatches the `plan-reviewer` sub-agent against the active feature's plan. Read-only audit. |
| `/ship-feature [slug]` | After the feature PR merges: marks `progress.md` complete and moves the dir to `.claude/plans/archive/`. |

Each command auto-detects the active feature when called without an argument (most recently modified `progress.md` whose status isn't a completion synonym).

## Why slash commands, not skills

Skills are interview-driven workflows (multi-phase, branching). Commands are one-step shortcuts. Use a command when the work is "always do exactly this sequence."

The three above wrap three different primitives:

- `plan-freeze` → a shell script (`open-plan-pr.sh`)
- `audit-plan` → a sub-agent (`plan-reviewer`)
- `ship-feature` → file-system + git operations

Without the commands you'd type the script invocation, the sub-agent dispatch, or the archive sequence from memory each time. The commands move that into muscle memory — `/plan-freeze` is shorter than `./scripts/open-plan-pr.sh 003-order-status-block`.

## Frontmatter

```yaml
---
description: One sentence shown in the slash command picker.
argument-hint: "[feature-slug]"
---
```

Both fields are optional but recommended. `$ARGUMENTS` in the body substitutes whatever the user typed after the command name.

## Adding a command

1. Drop a `<name>.md` in this directory.
2. Add the frontmatter.
3. Write the body as instructions to the agent — verbs in second person, one step per line.
4. If the command needs new tools or scripts, register them in `.claude/settings.json` so the agent doesn't ask permission every time.
