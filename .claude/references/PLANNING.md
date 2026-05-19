# PLANNING.md

Templates and rationale for the four plan artifacts. Every file under `.claude/plans/` follows one of these shapes.

## Why these files exist

Agentic coding sessions lose state between turns. The plan files are the only memory that survives compaction, model handoffs, and a fresh session a week later. Without them, every session re-derives intent from the diff — which is how features drift.

The split is purposeful:

| File | Lifetime | Audience | Question it answers |
|---|---|---|---|
| `constitution.md` | Project | Agent + reviewer | "What's allowed in this codebase?" |
| `spec.md` | Per feature | Agent + reviewer | "What are we building?" |
| `plan.md` | Per feature | Agent (executor) | "What's the next file edit?" |
| `findings.md` | Per feature | Agent (future) | "What did we discover that wasn't obvious?" |
| `progress.md` | Per feature | Agent (next session) | "Where did we leave off?" |

`plan.md` and `progress.md` are mandatory for any feature. `findings.md` is lazy — written only when something non-obvious gets discovered. `spec.md` can be skipped for trivial features, but the skill defaults to writing one.

---

## constitution.md

Project-level allowlist. Written once at scaffold time, edited deliberately. The agent treats anything not on the list as "ask the user first."

### Template

```markdown
# Constitution — {Plugin Name}

Last updated: {YYYY-MM-DD}

## Stack

- WordPress: >= 6.7
- PHP: >= 8.2
- Node: >= 20
- Deploy lane: {none | Ploi auto-deploy | GHA + Tailscale | custom}

## Allowed npm dependencies

- `@wordpress/scripts` (build)
- `@wordpress/blocks`, `@wordpress/block-editor`, `@wordpress/components`, `@wordpress/element`, `@wordpress/i18n`, `@wordpress/api-fetch`
- `@wordpress/hooks`, `@wordpress/data`
- {add others by amending this file}

Anything not on this list requires a PR that adds it here first.

## Allowed Composer dependencies

- (none beyond dev tooling unless added here)
- Dev: `squizlabs/php_codesniffer`, `wp-coding-standards/wpcs`, `phpunit/phpunit`

## Allowed input sanitizers

- `sanitize_text_field`, `sanitize_email`, `sanitize_key`, `sanitize_file_name`
- `sanitize_hex_color`, `sanitize_textarea_field`
- `absint`, `floatval`, `(bool) rest_sanitize_boolean`
- `esc_url_raw` (for storage)
- `wp_kses_post`, `wp_kses` (with explicit allowlist)

## Allowed output escapers

- `esc_html`, `esc_attr`, `esc_url`, `esc_js`
- `wp_kses_post`, `wp_kses` (with explicit allowlist)
- `esc_html__`, `esc_attr__`, `esc_html_e`, `esc_attr_e` (translated)

## Allowed capability constants

- `manage_options` — admin-only settings
- `edit_posts` — content editors
- `read` — any logged-in user
- {add others by amending this file with the reason}

## Quality gates (run before merge)

- `./vendor/bin/phpcs` — WordPress Coding Standards
- `npm run lint` — ESLint + stylelint
- `./vendor/bin/phpunit` — PHP unit tests
- `npm test` — JS tests (if blocks/extensions present)

## Forbidden constructs

- `eval`, `extract`, `create_function`, variable variables (`$$x`)
- `unserialize` on user data — use `json_decode`
- `assert` with a string argument
- File includes from user-controlled paths
- `'permission_callback' => '__return_true'` on any mutating REST route

## Conventions

- Slug: `{slug}` · Namespace: `{Namespace}` · Constants: `{CONST_PREFIX}_*` · Functions: `{func_prefix}_*`
- Options: one option per plugin, `{option_key}`, value is an array
- Text domain: literal string `{slug}`, never a variable
```

### Why this shape

- **Allowlist not prose.** "Use modern WordPress APIs" is interpretable; a list of seven exact package names is not. The model has training on bad-pattern WordPress code; the constitution overrides priors.
- **One reason per capability.** When the constitution is edited to add `edit_users`, the reason gets committed alongside it. Drift becomes auditable.
- **Stack at the top.** First thing the agent reads. Anything below is conditional on the stack matching.

---

## spec.md

Per-feature description of *what* and (critically) *what not*.

### Template

```markdown
# Spec — {NNN feature slug}

## What

{One paragraph. The user-visible behavior or developer-visible API surface. No implementation detail.}

## Why

{One paragraph. The motivation. Link to the issue, ticket, or conversation.}

## Acceptance

- {Bullet — a thing that must be true for this to ship.}
- {Bullet — another.}
- {3-7 bullets max. If you need 12, split the feature.}

## Out of scope

- {Explicit thing that someone might reasonably assume is included but isn't.}
- {Another.}

Anything not named in "Acceptance" or "Out of scope" is undefined. The plan
phase resolves the undefined; this phase commits the constraints.
```

### Why this shape

- **"Out of scope" prevents scope creep.** The agent will happily build everything adjacent unless told not to. The single highest-leverage line in the entire planning system.
- **No implementation detail.** Specs survive refactors; plans don't. Don't entangle them.
- **3-7 acceptance bullets.** Anything longer is a sign the feature should split.

---

## plan.md

Per-feature step list. This is what the executor follows.

### Template

```markdown
# Plan — {NNN feature slug}

## Approach

{2-3 sentences. The strategy. "We extend the existing settings class with a
new tab, register the block under the existing category, dispatch from a new
REST endpoint." If you can't write this in 3 sentences, the spec isn't ready.}

## Steps

### Step 1 — {imperative summary}

- **Files:** `includes/class-settings.php`, `includes/class-settings.php:140-160`
- **Test:** (encouraged) `tests/test-settings.php::test_new_tab_renders`
- **Why:** {one line, if non-obvious}

### Step 2 — …

…

## Risks / open questions

- {Anything the spec didn't fully resolve — flag it before you start coding.}
```

### Why this shape

- **File paths in every step.** "Add a new method" is not a step. The path makes it executable; the agent can locate the edit point on first try.
- **Test step encouraged, not required.** The constitution names the test tools; the plan names the specific test. Skip when genuinely untestable (UI tweaks); always list it for behavior.
- **"Why" only when non-obvious.** If the step description self-explains, no `Why:`. Prevents comment rot.
- **Risks at the bottom.** When you start coding and hit an unknown, you check here first. If the unknown isn't listed, the plan needed another pass.

---

## findings.md

Optional. Append-only. Written lazily during implementation when an MCP lookup or codebase read surfaces a non-obvious fact.

### Template

```markdown
# Findings — {NNN feature slug}

## {YYYY-MM-DD} — {short title}

{One paragraph. The fact, where it came from, why it shaped the plan or the
code. Link to wp-devdocs entry, hook reference, or commit that introduced it.}

## {YYYY-MM-DD} — …
```

### Why this shape

- **Lazy.** Most steps don't surprise. Don't write `findings.md` for nothing.
- **Append-only.** History matters. If a finding later turns out to be wrong, add a new entry that supersedes it; don't edit the old one.
- **Why it shaped the plan.** The fact alone is trivia; the impact is the value.

---

## progress.md

Live state. The agent reads this at session start (via the `UserPromptSubmit` hook) and writes to it as steps complete. Under 50 lines.

### Template

```markdown
# Progress — {NNN feature slug}

status: in_progress | blocked | complete
last_updated: {YYYY-MM-DD HH:MM}

## State

- last_completed: {step number + short name}
- next_action: {the literal next thing to do — file:line if relevant}
- blockers: {none | bullet list}

## Log

- {YYYY-MM-DD HH:MM} — {one line, what just happened}
- {YYYY-MM-DD HH:MM} — …
```

### Why this shape

- **Machine-oriented.** The hook parses `last_completed` and `next_action`. Don't add freeform sections that break the format.
- **Log is append-only.** Newest entry at the bottom. No editing past entries.
- **Under 50 lines.** When it grows, the feature is probably ready to archive.

---

## Archiving

When the PR ships:

```bash
mv .claude/plans/features/NNN-slug .claude/plans/archive/$(date +%Y-%m-%d)-NNN-slug
```

Archived plans stay readable forever. The numbered prefix preserves order; the date prefix preserves chronology. Don't delete archived plans — they're the long-term memory of the project.

---

## Anti-patterns to avoid

- **Plan files that read like a human PR description.** They're for the next agent session, not GitHub readers. Tight, structured, parseable.
- **Specs without "Out of scope."** The single most common drift source.
- **Plans without file paths.** The agent will pick a file; it'll usually be wrong.
- **`progress.md` as a journal.** It's a state file. Use `findings.md` for narrative.
- **Editing `constitution.md` mid-feature without a commit.** Constitution changes belong in their own PR with their own reason.
