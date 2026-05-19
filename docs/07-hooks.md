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

## The kit's five hooks

### `post-edit.sh` (non-blocking)

Fires on `Edit | Write | MultiEdit`. Reads `tool_input.file_path` from the hook payload and lints just that one file (`phpcs` for PHP, `eslint` for JS/TS, `stylelint` for CSS/SCSS). Output to stderr where the agent reads it.

Non-blocking on purpose: the agent might still be mid-refactor. Surfacing the issue lets it self-correct on the next pass; blocking would freeze a multi-step task.

Linting only the changed file keeps the hook cheap when the agent does many edits in a single turn — a 10-edit refactor runs 10 single-file lints, not 10 full sweeps.

### `pre-commit.sh` (blocking)

Fires on every `Bash` call. Filters: only acts if the command starts with `git commit`. On a match it delegates to `scripts/quality.sh`, which runs the full suite:

- `phpcs --standard=WordPress`
- `phpstan analyse` (if installed)
- `eslint src/`
- `stylelint src/**/*.{css,scss}`
- `phpunit`

If any one fails, `quality.sh` exits non-zero, the hook propagates the exit, and the commit is blocked. The agent gets the stderr message and can fix.

This is the safety net. Even if the agent "forgot" to run phpcs (because CLAUDE.md is advisory), the hook runs it.

### `user-prompt-submit.sh` (non-blocking)

Fires every time you submit a prompt. Scans `.claude/plans/features/*/progress.md`, finds the most recently modified active feature (status not `complete`), and emits a `<system-reminder>` with the plan's `last_completed`, `next_action`, and `blockers`. Stays silent when no feature is active.

This is the load-bearing defense against plan drift: without it, the agent re-derives intent from the diff on every fresh session, and behavior wanders. With it, the agent re-anchors on its plan every turn. (Research published in 2025 measured a ~33% edit-without-prior-read rate in unattended sessions; this hook is the cheapest mitigation.)

Cost: a few hundred tokens per turn when a plan is active. Zero otherwise.

### `stop.sh` (non-blocking)

Fires when the agent finishes a turn. Updates `last_updated:` in the active feature's `progress.md` to the current timestamp.

Without this, `last_updated` only changes when the agent remembers to write to `progress.md` — which is exactly the failure mode the planning layer defends against. This hook closes the loop: file age now reflects real activity even when the agent forgets to log.

Silent. Modifies at most one file per turn.

### `session-start.sh` (non-blocking, matcher: `resume|compact|clear`)

Fires when a session resumes, compacts context, or is cleared. Prints a one-line banner naming the active feature and its next action, so you re-anchor before typing the next prompt. Silent when nothing's active.

The `matcher` is deliberate: per [Anthropic issue #10373](https://github.com/anthropics/claude-code/issues/10373), `SessionStart` stdout is dropped on brand-new sessions, so the kit doesn't try to use it there. The `user-prompt-submit.sh` hook covers the new-session case once you type your first prompt.

## Testing the hooks

Anything trustable should be testable. The kit ships a small bash test suite at `tests/` that exercises each hook with isolated sandboxes per case:

```bash
./tests/run.sh                # 56 cases across all five hooks
./tests/run.sh hooks/test-stop.sh   # one hook
```

`scripts/quality.sh` runs the suite as one of its gates, so a failing hook test blocks commits via `pre-commit.sh`. Plain bash, no external deps. See `tests/README.md` for the conventions.

## Event reference

| Event | When | Common use |
|---|---|---|
| `PreToolUse` | Before any tool | Block dangerous commands, gate commits |
| `PostToolUse` | After a tool | Lint edited files, log activity |
| `Stop` | When the agent finishes a turn | Quality summary, push reminder |
| `SubagentStop` | When a sub-agent finishes | Aggregate findings |
| `UserPromptSubmit` | When you hit enter | Plan injection (the kit uses this), context briefing |
| `SessionStart` | New session | Status banner, project briefing |
| `PreCompact` | Before context compaction | Save state to a planning file |
| `Notification` | On notifications | Forward to Slack |

## What belongs in a hook (vs. CLAUDE.md, vs. a skill)

- "Always lint before committing." → **hook** (must always run).
- "Use kebab-case for slugs." → **CLAUDE.md** (rule of style; the agent applies it).
- "When asked to add a block, follow this 12-step interview." → **skill** (workflow).

If the rule has the form "must always run," it's a hook. If it has the form "when X, do Y," it's CLAUDE.md or a skill.

## Cost

Hooks add latency. A pre-commit hook that runs phpunit can add seconds. That's the point — but mind it. Don't put a 10-minute test suite in a PreToolUse hook that fires on every Bash call. Reserve heavy work for `Stop` (turn end) or genuine commits.

## Belt and suspenders

Claude Code hooks only fire inside Claude Code. The kit ships `scripts/quality.sh` as the single source of truth for the suite — `.claude/hooks/pre-commit.sh` calls it. To gate commits from a terminal, an IDE, or CI too, point them at the same script:

```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash
exec ./scripts/quality.sh
```

One script, three call sites, same gate everywhere.

---

← [Sub-agents](./06-sub-agents.md) · Next: [Permissions →](./08-permissions.md)
