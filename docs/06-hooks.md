# 6. Hooks

## The point of hooks

CLAUDE.md is advisory. Hooks are deterministic.

When the rule absolutely must run — every commit, every file change, every session boundary — it belongs in a hook, not in the prompt. Hooks aren't a suggestion the agent can forget about under context pressure. They're infrastructure.

This is **Diligência** as engineering, not as memory.

## Anatomy

A hook is two things:

1. A shell script in `.claude/hooks/`.
2. A registration in `.claude/settings.json` matching an event to that script.

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": ".claude/hooks/post-edit.sh" }] }
    ]
  }
}
```

The hook receives a JSON payload on stdin describing the event (which tool fired, which file was edited, what command was run). It can react via:

- **Exit code** — non-zero blocks (for PreToolUse) or signals failure (for PostToolUse).
- **stderr** — surfaced to the agent's context. Use this to explain a block or share findings.
- **stdout JSON** — advanced control: `{"decision": "block", "reason": "..."}`.

## The kit's two hooks

### `post-edit.sh` (non-blocking)

Fires on `Edit | Write | MultiEdit`. Reads `git status`, lints each modified file by extension (`phpcs` for PHP, `eslint` for JS/TS, `stylelint` for CSS/SCSS). Output to stderr where the agent reads it.

Non-blocking on purpose: the agent might still be mid-refactor. Surfacing the issue lets it self-correct on the next pass; blocking would freeze a multi-step task.

### `pre-commit.sh` (blocking)

Fires on every `Bash` call. Filters: only acts if the command starts with `git commit`. Then runs the full quality suite:

- `phpcs --standard=WordPress`
- `phpstan analyse` (if installed)
- `eslint src/`
- `stylelint src/**/*.{css,scss}`
- `phpunit`

If any one fails, exits non-zero. The commit is blocked. The agent gets the stderr message and can fix.

This is the safety net. Even if the agent "forgot" to run phpcs (because CLAUDE.md is advisory), the hook runs it.

## Event reference

| Event | When | Common use |
|---|---|---|
| `PreToolUse` | Before any tool | Block dangerous commands, gate commits |
| `PostToolUse` | After a tool | Lint edited files, log activity |
| `Stop` | When the agent finishes a turn | Quality summary, push reminder |
| `SubagentStop` | When a sub-agent finishes | Aggregate findings |
| `UserPromptSubmit` | When you hit enter | Context injection |
| `SessionStart` | New session | Status banner, project briefing |
| `PreCompact` | Before context compaction | Save state to CHANGELOG.md |
| `Notification` | On notifications | Forward to Slack |

## What belongs in a hook (vs. CLAUDE.md, vs. a skill)

- "Always lint before committing." → **hook** (must always run).
- "Use kebab-case for slugs." → **CLAUDE.md** (rule of style; the agent applies it).
- "When asked to add a block, follow this 12-step interview." → **skill** (workflow).

If the rule has the form "must always run," it's a hook. If it has the form "when X, do Y," it's CLAUDE.md or a skill.

## Cost

Hooks add latency. A pre-commit hook that runs phpunit can add seconds. That's the point — but mind it. Don't put a 10-minute test suite in a PreToolUse hook that fires on every Bash call. Reserve heavy work for `Stop` (turn end) or genuine commits.

## Belt and suspenders

Claude Code hooks only fire inside Claude Code. If commits also happen from a terminal, an IDE, or CI, install the same checks as a `.git/hooks/pre-commit` or via husky. The Pluginslab pattern: one `scripts/quality.sh` invoked from both `.claude/hooks/pre-commit.sh` and `.git/hooks/pre-commit`. Single source of truth, two invocation paths.

---

← [Sub-agents](./05-sub-agents.md) · Next: [Permissions →](./07-permissions.md)
