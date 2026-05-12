# `.claude/hooks/`

Deterministic safety net. CLAUDE.md is advisory — it suggests good behaviour. Hooks always run. Anything that MUST happen on every commit, every edit, every session boundary belongs here, not in CLAUDE.md.

## Shipped hooks

### `post-edit.sh` — PostToolUse on Edit/Write/MultiEdit

Fires after the agent modifies any file. Runs the appropriate linter:

| File type | Linter |
|---|---|
| `.php` | `./vendor/bin/phpcs --standard=WordPress` |
| `.js`, `.ts`, `.jsx`, `.tsx` | `./node_modules/.bin/eslint` |
| `.scss`, `.css` | `./node_modules/.bin/stylelint` |

**Non-blocking.** Output goes to stderr where the agent reads it. The agent may still be mid-task; better to surface the issue and let it self-correct than to block a multi-step refactor halfway through.

### `pre-commit.sh` — PreToolUse on Bash

Fires before any `Bash` tool call. Filters: only acts if the command starts with `git commit`. Then runs the full quality gate and **blocks the commit** if anything fails.

What it runs (if the tool is installed in the project):

- `./vendor/bin/phpcs --standard=WordPress`
- `./vendor/bin/phpstan analyse`
- `./node_modules/.bin/eslint src/`
- `./node_modules/.bin/stylelint "src/**/*.{css,scss}"`
- `./vendor/bin/phpunit`

If any one of them fails, the commit is blocked and the agent gets a message describing why. The agent can fix the issues and retry.

## Why hooks, not just CLAUDE.md

CLAUDE.md says "run phpcs before committing." That's a suggestion. The agent might forget, the agent might decide a particular commit is too small to warrant a check, the agent might be tired (context-bloated). Hooks remove the choice. Every commit is gated, every time.

This is the **Diligence** D of the AI Fluency Framework, made into infrastructure.

## Configuration

Hooks are registered in [`../settings.json`](../settings.json) under the `hooks` key. The `matcher` picks the tool event; the `command` runs the script.

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit",
        "hooks": [{ "type": "command", "command": ".claude/hooks/post-edit.sh" }] }
    ],
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [{ "type": "command", "command": ".claude/hooks/pre-commit.sh" }] }
    ]
  }
}
```

## Adding a hook

1. Drop a shell script in this folder. Make it executable: `chmod +x your-hook.sh`.
2. Register it in `../settings.json` under the appropriate event.
3. Decide: blocking or informational? Blocking exits non-zero. Informational always exits 0.

## Event reference (Claude Code)

| Event | When it fires |
|---|---|
| `PreToolUse` | Before any tool runs. Can block. |
| `PostToolUse` | After a tool runs. Can react / log. |
| `Stop` | When the agent finishes a turn. |
| `SubagentStop` | When a sub-agent finishes. |
| `UserPromptSubmit` | When the user submits a prompt. |
| `SessionStart` | When a new session starts. |
| `PreCompact` | Before context compaction. |
| `Notification` | On notifications. |

## Hook payload

Hooks receive a JSON payload on stdin describing the event. Key fields:

- `tool_name` — which tool fired the event (`Edit`, `Bash`, etc.)
- `tool_input` — the arguments passed to the tool (e.g. `{"file_path": "..."}` for Edit, `{"command": "..."}` for Bash)
- `tool_response` — present on PostToolUse, contains the tool's return value

Parse with `python3 -c "import json,sys; ..."` (always available) or `jq` (often available).

## Hook output

- **Exit 0** — allow / continue.
- **Exit non-zero** — block (PreToolUse) or signal failure (PostToolUse).
- **stderr output** — surfaced to the agent's context. Use this to explain why you blocked, or to share findings.
- **stdout JSON** — for advanced control: `{"decision": "block", "reason": "..."}` or `{"hookSpecificOutput": {...}}`.

## Git hooks vs. Claude Code hooks

These hooks run inside Claude Code only. For a belt-and-suspenders setup that also gates commits made from outside the agent (your terminal, IDE, CI), install a `.git/hooks/pre-commit` that invokes the same quality suite. The Pluginslab pattern: a single `scripts/quality.sh` invoked by both `.claude/hooks/pre-commit.sh` and `.git/hooks/pre-commit`.
