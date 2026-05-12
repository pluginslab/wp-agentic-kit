# 2. CLAUDE.md (Description)

## What it is

A markdown file at the project root that the agent reads at the start of every session and keeps in context across compactions. It's the persistent brief — the equivalent of bringing a new senior engineer up to speed on the project once, in writing, so you never have to repeat yourself.

In the AI Fluency Framework this is **Descrição** — communicating clearly what you expect.

For non-Anthropic tools (Codex, Cursor, Gemini CLI, Copilot, Windsurf), the same content lives in `AGENTS.md`. The kit keeps them in lockstep.

## What goes in it

Research consistently identifies five sections that earn their place:

1. **What this is** — one sentence, plus identity (slug, namespace, text domain).
2. **Security / non-negotiables** — top of file. The first ~40 lines get the strongest model attention; spend them on rules that absolutely must not be broken.
3. **Commands** — exact, runnable. `./vendor/bin/phpcs` beats "run the linter."
4. **Structure** — directory tree with one-line explanations.
5. **Conventions and negative rules** — naming, prefixes, "never do X."

The kit's [`CLAUDE.md`](../CLAUDE.md) is annotated with HTML comments explaining the *why* of each section. Strip those comments once your team internalizes the pattern.

## What to keep out

- Routing rules ("if X then ask, else proceed") that depend on small context cues — those drift and bloat the file.
- Anything Claude can derive by reading the code — file structure, function names, common patterns.
- Personal preferences. Those live in your global `~/.claude/CLAUDE.md`.
- Anything that MUST always run regardless of agent attention — that's a hook, not a rule.

## Length discipline

- Aim ≤ 200 lines.
- ≤ 15 rules total.
- `IMPORTANT:` / `YOU MUST` on the one or two genuinely non-negotiable rules — the kit reserves them for security.
- Use `@path/to/file` to load deeper context on demand. The kit's CLAUDE.md @-references the SKILL.md and the SECURITY.md so the agent pulls those in only when relevant.

## How to evolve it

The single best heuristic: **when you correct the agent on the same mistake twice, add a rule.**

In Claude Code, the `#` prefix in the chat captures a note straight to CLAUDE.md (asks you project vs. user scope first). Use it whenever a correction surfaces.

Quarterly: re-read the file. Cut rules that haven't been violated in months. Promote any rule that has become non-negotiable into a hook so the next person can't accidentally drop it.

## CLAUDE.md vs. CHANGELOG.md

CLAUDE.md is *instructions*. CHANGELOG.md is *journal*: progress, decisions, dead ends. Anthropic's long-running-agent research recommends pairing the two — without a record of what failed and why, the next session re-attempts the same dead ends.

The kit ships CLAUDE.md but not CHANGELOG.md; it's project-specific and starts the moment you make the first decision worth recording.

---

← [Getting started](./01-getting-started.md) · Next: [Skills →](./03-skills.md)
