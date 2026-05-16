# 1. Getting started

## What you need

- macOS or Linux (Windows works with WSL or symlink support enabled)
- Node.js 20+ and npm
- PHP 8.2+ and Composer
- `wp-cli` recommended
- Claude Code installed (`npm install -g @anthropic-ai/claude-code` or your preferred install)

You don't need to install MCP servers yourself — the kit's `.mcp.json` does that via `npx` on first call.

## Scaffold

```bash
npm create wp-ai-plugin my-cool-plugin
# or
npx create-wp-ai-plugin my-cool-plugin
cd my-cool-plugin
```

The interactive scaffolder asks for:

1. **Plugin name** — human-friendly, e.g. `Order Tracker`
2. **Vendor prefix** — optional, e.g. `acme` (press Enter to skip)
3. **Description**, **author**, **minimum WordPress version**, **minimum PHP version**

It derives the slug, namespace, constants, and function prefixes from those answers, shows you the full set, asks for confirmation, then fetches the kit from GitHub, runs find/replace across every file, initialises a fresh git repo with a `scaffold` tag on the initial commit, and kicks off background jobs to index WP docs and pull the upstream [WordPress/agent-skills](https://github.com/WordPress/agent-skills) library into `.claude/skills/`.

Need to pin a release?

```bash
npm create wp-ai-plugin my-cool-plugin -- --ref v0.2.0
```

## Open your first session

```bash
claude
```

Claude Code starts in the project directory. It reads, in order:

1. `~/.claude/CLAUDE.md` — your global preferences
2. `./CLAUDE.md` — the project brief you just customized
3. `./.claude/settings.json` — what tools and MCPs are pre-approved
4. `./.mcp.json` — which MCP servers to start
5. `./.claude/skills/*/SKILL.md` — invokable workflows
6. `./.claude/agents/*.md` — sub-agents available for delegation
7. `./.claude/hooks/*` — events that fire automatically

The first time you call an MCP server, `npx` fetches it (a few seconds of warm-up). After that, calls are instant.

## Verify the harness works

Inside the session:

```
> what tools do you have available for WordPress work?
```

The agent should mention the MCP servers (`wp-devdocs`, `wp-blockmarkup`, `wp-playground`, `chrome-devtools`, `github`) and the available skills / sub-agents.

If it doesn't, check that `.mcp.json` and `.claude/settings.json` weren't gitignored on clone, and that the file paths in the hooks config match the actual scripts.

## What you've got now

You're sitting on a working harness for one plugin. The next chapters walk through what each piece does and how to evolve it.

If you want to use the kit as an *overlay* on an existing plugin instead of as a starter, see [Permissions](./07-permissions.md) for which files to copy and which to merge.

---

Next: [CLAUDE.md (Description) →](./02-claude-md.md)
