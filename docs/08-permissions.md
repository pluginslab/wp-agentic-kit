# 7. Permissions

## The trust model

By default Claude Code asks before running any tool that mutates state — running a Bash command, calling an MCP tool, writing a file. Asking is safe but breaks flow. The permission system lets you pre-approve specific patterns so the agent moves at the speed of thought on routine work, while still pausing for anything outside the allowlist.

Two layers, both in `.claude/`:

| File | Scope | Committed? |
|---|---|---|
| `settings.json` | Project — shared with everyone on the team | yes |
| `settings.local.json` | Personal additions on top | no (gitignored) |

`settings.local.json` merges on top of `settings.json`. Anything you allow there stays on your machine.

## What the kit pre-approves

The kit's `.claude/settings.json` allows:

**Bash commands** the WordPress workflow needs:
- `wp:*`, `wp-env:*` — WP-CLI and local environment
- `composer:*`, `php:*` — PHP toolchain
- `npm:*`, `pnpm:*`, `npx:*` — JS toolchain
- `git:*`, `gh:*` — version control and GitHub CLI
- `curl:*` — testing REST endpoints
- `./vendor/bin/{phpcs,phpcbf,phpunit,phpstan,psalm}` — quality gates

**MCP servers** registered in `.mcp.json`:
- `mcp__wp-devdocs`, `mcp__wp-blockmarkup`, `mcp__wp-playground`, `mcp__github`, `mcp__chrome-devtools`

If a server is in `.mcp.json` but not in this allowlist, the agent has to ask permission every time it calls one of its tools.

## What's deliberately not in there

- `effortLevel` — personal preference, belongs in your global `~/.claude/settings.json`.
- `enabledPlugins` — install plugins yourself; the kit doesn't dictate.
- `model` — your setup decides which model to use.

## Adding permissions

When the agent stops mid-task asking for the same command three times, that's the signal. Add it. The pattern is the same iteration loop as CLAUDE.md and skills: catch a recurring friction, codify it, move on.

```json
{
  "permissions": {
    "allow": [
      "Bash(docker:*)",
      "Bash(ssh marcel@server:*)"
    ]
  }
}
```

Specific is better than wildcard. `Bash(docker compose up:*)` is safer than `Bash(docker:*)`. Tradeoff: specific means more entries; wildcard means more trust.

## Denying

The system also supports a `deny` list — patterns the agent never gets to run, even if the user asks. Useful for genuinely dangerous things:

```json
{
  "permissions": {
    "deny": [
      "Bash(rm -rf /:*)",
      "Bash(rm -rf ~/:*)"
    ]
  }
}
```

The kit doesn't ship denies because the agent shouldn't be reaching for those in the first place. Add them if you're nervous.

## Settings as commitment, not preference

Treat `.claude/settings.json` like CI config: it expresses how the project should be built. New permissions go through PR review the same as code changes. If someone wants `Bash(rm:*)` allowed, they should have to justify it.

## Adopting on an existing plugin

If you have a plugin already and want to add the kit's harness:

1. Copy `CLAUDE.md` and `AGENTS.md` to your project root, then customize.
2. Copy `.claude/` wholesale. Edit `settings.json` to match your existing commands.
3. Copy `.mcp.json` to your project root.
4. Copy `mcp/` and `docs/` if you want the documentation alongside.
5. Don't copy `cli/` — it's the scaffolder, only useful for the starter case.

Permissions stay project-scoped. Your existing plugin gets the kit's safety nets without altering its source tree.

---

← [Hooks](./07-hooks.md) · Next: [Putting it together →](./09-putting-it-together.md)
