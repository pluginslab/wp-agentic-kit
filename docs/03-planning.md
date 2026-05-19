# 3. Planning

## The problem this solves

Agentic coding sessions lose state. Between turns, between sessions, between days. The agent might remember what it was doing in this conversation; it definitely won't remember in a week, and any next session starts cold. Without a written plan the agent re-derives intent from the diff — and that's how features drift, security rules get re-invented, and you end up correcting the same mistake on Tuesday that you already corrected on Friday.

The fix is the **Descrição** D made executable: structured, durable, machine-readable text the agent reads at the start of every turn.

## The four files

The kit ships a four-file cascade under `.claude/plans/`. Each has a different lifetime, audience, and question it answers.

| File | Lifetime | Audience | Question |
|---|---|---|---|
| `constitution.md` | Project | Agent + reviewer | "What's allowed in this codebase?" |
| `spec.md` | Per feature | Agent + reviewer | "What are we building?" |
| `plan.md` | Per feature | Agent (executor) | "What's the next file edit?" |
| `progress.md` | Per feature | Agent (next session) | "Where did we leave off?" |

Plus an optional fifth — `findings.md` — for research notes that surface mid-implementation.

```
.claude/plans/
├── constitution.md
└── features/
    └── NNN-feature-slug/
        ├── spec.md
        ├── plan.md
        ├── findings.md      ← optional
        └── progress.md
```

Templates for each are in `.claude/references/PLANNING.md`. Long-form rationale is there too.

## `constitution.md` — two binding levels

Project-level. Written once at scaffold time by `wordpress-scaffold`, amended deliberately. The file has two kinds of sections that bind the agent differently:

**Strict sections** (`Allowed input sanitizers`, `Allowed output escapers`, `Allowed capability constants`, `Forbidden constructs`). Security-relevant. The agent must NOT deviate without explicit human approval, because the failure mode is a CVE.

**Default sections** (`Default npm dependencies`, `Default Composer dependencies`). Advisory. The agent reaches for these first; if a feature genuinely needs `clsx` or `date-fns`, it just uses the lib and notes the addition in the feature's `findings.md`. No PR ceremony for utility libraries.

The distinction matters. Treating everything as strict makes the agent ask permission for trivia and slows the work to a crawl. Treating nothing as strict puts the plugin one missing escape away from disclosure.

The structural choice for the strict sections: **enumerate, don't describe.**

> Bad: "Use modern WordPress escape functions."
>
> Good:
> ```markdown
> ## Allowed output escapers (strict)
> - esc_html
> - esc_attr
> - esc_url
> - esc_js
> - wp_kses_post
> - wp_kses
> - esc_html__, esc_attr__, esc_html_e, esc_attr_e (translated)
> ```

Prose gets reinterpreted by the agent every time it's read. An enumerated list of exact function names cannot.

Amendments to the **strict** sections live in their own commit, with the reason in the commit message — that's how new capabilities or sanitizers get added without silently broadening the surface. Amendments to the **default** sections happen as needed and get a note in `findings.md`.

## `spec.md` — what + what not

Per-feature. The single most important section is the one most readers forget to write: `## Out of scope`.

```markdown
## Out of scope
- No order list view; this feature is single-order only.
- No historical timeline; status is current-state only.
- No email/SMS notifications; out of band.
```

If something isn't named in `Acceptance` or `Out of scope`, the agent assumes it's in scope. That's the failure mode that turns "add a status block" into a six-feature PR.

Keep `Acceptance` to 3-7 bullets. If you need 12, the feature should split.

## `plan.md` — the executor's map

Per-feature. Phased step list with **file paths in every step**.

> Bad: "Add validation to the form handler."
>
> Good:
> ```markdown
> ### Step 3 — Validate the order ID
> - **Files:** `includes/api/class-rest-order-status.php:42-78`
> - **Test:** `tests/test-rest-order-status.php::test_invalid_id_returns_404`
> - **Why:** the existing controller doesn't `absint` before lookup.
> ```

The file path makes the step executable. Without it, the agent picks a file, and it'll usually be wrong.

Encourage (don't require) a `Test:` line per step. PHPUnit for PHP, Jest for JS, Playwright for editor flows. The constitution names the test tools; the plan names the specific test.

End with a `## Risks / open questions` section. If a step's premise is unclear, flag it before coding starts. If the unknown isn't listed, the plan needed another pass.

## `progress.md` — the state file

Per-feature. Under 50 lines. Machine-oriented.

```markdown
status: in_progress
last_updated: 2026-05-18 14:30

## State
- last_completed: Step 2 — Register REST controller
- next_action: Step 3 — Validate order ID at class-rest-order-status.php:42
- blockers: none

## Log
- 2026-05-18 14:20 — Step 1 phpunit fixture written, passes.
- 2026-05-18 14:30 — Step 2 controller registered, smoke test green.
```

This isn't a journal for humans. The `UserPromptSubmit` hook parses `last_completed` and `next_action` and feeds them back into the agent's context on every turn. Don't add freeform sections that break the format.

The `Stop` hook auto-updates `last_updated` when the agent finishes a turn, so age reflects activity even when the agent forgets to write a log entry.

## The plan freeze (conditional)

The structural commitment that makes this work in practice — but not on every change.

`plan.md` ends with a **Freeze assessment** checklist. The agent fills it in honestly while writing the plan:

```markdown
## Freeze assessment

- [ ] Touches security-relevant code (sanitizers, escapers, capabilities, REST permission callbacks, file uploads, raw queries)
- [ ] Adds a new dependency outside the constitution's defaults
- [ ] Modifies database schema
- [ ] Changes the public API surface (REST routes, hook signatures, options keys)
- [ ] Cross-cuts more than 3 files

**Recommendation:** freeze | proceed in-session
```

Any one box checked → recommendation is **freeze**. The skill then runs `./scripts/open-plan-pr.sh NNN-feature-slug`, which commits `spec.md` + `plan.md` on a `plan/NNN-feature-slug` branch and opens a PR titled `plan: NNN-feature-slug`. Phase 3 (implementation) waits for the plan PR to merge.

Zero boxes checked → recommendation is **proceed in-session**. The skill commits `plan.md` as the first commit of the `feat/NNN-feature-slug` branch, surfaces the assessment to the user for confirmation, and starts Phase 3 immediately. The plan still ships — it's just in the feature PR, not its own PR.

A typo fix and a new REST endpoint shouldn't go through the same ceremony. The checklist makes the call explicit and reviewable. The `plan-reviewer` sub-agent verifies the assessment is honest: if a plan recommends "proceed" but names a permission callback in a step, that's flagged as Critical and the plan won't merge until re-assessed.

Human override is always available either direction.

> **GitHub assumption.** The script uses the `gh` CLI. For GitLab, Bitbucket, or local-only repos, replace the script with one that calls the equivalent (`glab mr create`, `bb pr create`, manual git push + PR via the host's web UI). The kit doesn't ship adapters — most WP shops are on GitHub, and the failure is loud (`gh: command not found`) if you're not.

The agent then dispatches the `plan-reviewer` sub-agent, which audits:

- `spec.md` has an `Out of scope` section ✓
- Every step in `plan.md` has a `Files:` line ✓
- No library, sanitizer, or capability is used that isn't in the constitution ✓
- Steps reference real file paths (via `Glob`) or paths an earlier step creates ✓

If the audit is clean, the human reviews — focused on whether the **approach** is right, not whether the syntax is. Five minutes, not an hour. Then merges.

**Only after the plan PR merges does the agent start writing implementation code.**

This is the load-bearing defense against plan drift. Research published in 2025 measured ~33% edit-without-prior-read rates in unattended agentic sessions. The plan freeze cuts that to near zero, because the agent literally cannot start coding until a human has signed off on the plan.

## How the planning layer plugs into the harness

| When | What | Hook / skill / agent |
|---|---|---|
| Session opens | The active feature's plan + progress is injected into context | `user-prompt-submit.sh` hook |
| User asks for a feature | Spec + plan written; freeze; reviewer audits | `wordpress-feature` skill + `plan-reviewer` agent |
| Each implementation step completes | `progress.md` updated by the agent | (manual, but reinforced by next prompt's hook injection) |
| Each turn ends | `progress.md` `last_updated` touched | `stop.sh` hook |
| Feature ships | Plan dir moved to `.claude/plans/archive/{date}-{slug}/` | `wordpress-feature` skill, Phase 5 |

Five separate pieces, each doing one thing. Together they keep the plan and the code in sync without depending on the agent's memory.

## Anti-patterns to avoid

- **Plan files that read like a human PR description.** They're for the next agent session, not GitHub readers. Tight, structured, parseable.
- **Specs without `Out of scope`.** The single most common drift source.
- **Plans without file paths.** The agent will pick a file; it'll usually be wrong.
- **`progress.md` as a journal.** It's a state file. Use `findings.md` for narrative.
- **Editing `constitution.md` mid-feature without a commit.** Constitution changes belong in their own PR with their own reason.
- **Lying on the freeze assessment to skip the plan PR.** The checklist exists so the call is explicit. Marking the dependency box "no" because you "barely" added a library is exactly the drift the planning layer is meant to defend against. The plan-reviewer audit catches it.

## When NOT to plan

The planning layer is overhead. For genuinely small changes — a typo, a version bump, a one-line CSS tweak — invoke the maintenance mode of `wordpress-feature` instead:

```
> this is a maintenance edit: bump version to 1.2.4
```

The skill skips spec/plan, makes the change, and appends a one-liner to `progress.md` (or `.claude/plans/maintenance.md` if no feature is active). The trail stays, the ceremony doesn't.

If you find yourself wishing every change were a maintenance edit, the planning layer is mis-sized for your project. Loosen the plan template — `spec.md` can be three bullets, `plan.md` can be a single phase — before abandoning it.

---

← [CLAUDE.md](./02-claude-md.md) · Next: [Skills →](./04-skills.md)
