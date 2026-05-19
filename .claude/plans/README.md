# Plans

The agent's load-bearing memory across sessions. Read by the `UserPromptSubmit` hook on every turn.

## Maps to the talk's framework

**Descrição.** This is the description layer made executable — durable, structured text that tells the agent what's allowed (`constitution.md`), what we're building (`spec.md`), how (`plan.md`), and where we are (`progress.md`). Without it, every session re-derives intent from the diff.

## Layout

```
.claude/plans/
├── constitution.md          ← project-stable allowlists
├── features/
│   └── NNN-feature-slug/    ← one dir per in-flight feature / PR
│       ├── spec.md
│       ├── plan.md
│       ├── findings.md      ← optional
│       └── progress.md
└── archive/
    └── YYYY-MM-DD-NNN-slug/ ← shipped features, kept for long-term memory
```

## How to use it

- New plugin: invoke the `wordpress-scaffold` skill. It writes the constitution and the initial-scaffold spec/plan, then generates the plugin.
- New feature: invoke the `wordpress-feature` skill. It writes spec + plan, freezes the plan for human review (via `scripts/open-plan-pr.sh`), then implements after the plan PR merges.

## The example feature

`features/001-example-hello-rest/` ships with the scaffold as a worked example — see [its README](./features/001-example-hello-rest/README.md). It's marked `status: complete` so the hooks ignore it; delete or archive it before starting your first real feature.
- Mid-implementation: open the active `progress.md` to see where the agent left off. Edit it directly if you need to override.
- Shipped a PR: move the feature dir to `archive/{YYYY-MM-DD}-{slug}/`.

## Conventions

- One feature dir per PR. Numbered, zero-padded to three digits.
- `progress.md` stays under 50 lines.
- `spec.md` always ends with "Out of scope."
- `plan.md` steps always include file paths.
- `constitution.md` is a whitelist, not prose.

Templates and rationale: @.claude/references/PLANNING.md
