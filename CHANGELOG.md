# Changelog

The kit's evolution, kept for humans. Per-feature progress lives in `.claude/plans/`.

## v1.0.4 — 2026-09-16

### Added

- **`playground-verifier` sub-agent** (`.claude/agents/playground-verifier.md`). The kit's first *runtime* gate. Boots the plugin in an ephemeral WordPress Playground instance — at the WP and PHP versions the plugin's own header declares, not at latest — mounts the working tree, then activates, reads the error log, confirms every `register_rest_route` call actually resolves, checks that mutating routes reject unauthenticated requests, deactivates, uninstalls, and verifies no options are left behind. Read-only plus the `wp-playground` MCP tools: no `Edit`, no `Write`. Always stops the instance, including on early exit.

  This closes the hole that v1.0.2 exposed. That release fixed a scaffold which fataled the instant it was activated, and the fix note said it plainly: *"None of the static gates caught it, because nothing in `quality.sh` boots WordPress."* phpcs reads syntax, `security-reviewer` reads patterns, `plan-reviewer` reads markdown. Nothing ran the plugin. Now something does.

  The definition was then **corrected against a live run** before shipping. Dispatching it at the kit's own `pl-example` template surfaced 13 defects in its own playbook, two of which would have produced false passes: `get_playground_logs` surfaces the Node process's output and **not** PHP errors (those land in `wp-content/debug.log`, invisible to it — an agent following the original instructions would report "no errors" on a fataling plugin), and the unauthenticated-REST check could not run at all, because Playground's auto-login mu-plugin 302-redirects every cookie-less request until curl dies at exit 47. The playbook now names `debug.log` as the evidence channel, requires a deliberate `trigger_error` probe to prove logging is on before an empty log means anything, carries working recipes for the commands the MCP bridge doesn't implement (`wp plugin uninstall`, `is_plugin_active()`, `option get`'s missing-vs-empty ambiguity), confirms the booted versions from inside the instance rather than trusting the CLI banner (which reported PHP 8.3 / WP latest for an instance serving 8.2.33 / 6.7.7), and filters the route dump to the plugin's namespace instead of flooding context with every core route.

  It also gained one deliberate carve-out from "never edit": VFS-only scratch copies at non-mounted paths, so the agent can remove a dependency to prove a fix carries its own weight — which is how it established that the v1.0.2 autoload fix is real and not merely masked by Composer's classmap. Host tree untouched, verified with `git status --porcelain`.

- **Sub-agent contract tests** (`tests/agents/test-agent-contracts.sh`, 43 assertions). The read-only guarantee lives in each agent's `tools:` allowlist, not in its prompt body — a prompt saying "you do not modify code" is advisory, an omitted `Edit` is structural. These tests assert the structural half: no kit sub-agent declares `Edit` / `Write` / `MultiEdit` / `NotebookEdit`, every `name:` matches its filename, every agent has a `description:` (the main agent matches intent against it), `playground-verifier` holds the four `wp-playground` tools it can't work without, and no skill dispatches an agent that isn't on disk. Six further assertions pin the false-pass traps above, so a future edit that drops the `debug.log` warning or the auto-login recipe reintroduces a gate that cannot fail. Suite total: 92 → 135.

### Changed

- **`wordpress-feature` step 7** now dispatches `security-reviewer` and `playground-verifier` together, in one message, so they run concurrently against the same diff. `quality.sh` proves the code is well-formed; `playground-verifier` proves it runs.
- **`wordpress-scaffold` step 6** dispatches `playground-verifier` instead of offering a manual Playground smoke test, and its "After generation" reminder hands the activation → deactivation → uninstall cycle to the agent rather than to the user. A scaffold that doesn't activate is worse than no scaffold.
- **`docs/06-sub-agents.md`** gains a "why not planner / coder / tester" section. One-agent-per-phase is the structure most people reach for first; the doc now runs each candidate through the kit's three criteria (context isolation, tool discipline, parallelism) and shows why only the verifier clears the bar. The rule it lands on: delegate work whose **output is a conclusion**, not work whose output is a diff.

### Fixed

- **`playground-verifier`'s own playbook**, corrected against a second live run: `WP_DEBUG_DISPLAY` is false by default in Playground, which made the "notices in the page body" check structurally incapable of failing; the `wp-admin/includes/` caveat was written as a quirk of `is_plugin_active()` when it applies to `activate_plugin()` and `get_plugins()` equally; there was no recipe for *authenticated* admin loads (the inverse of the anonymous one — omit the suppression cookie and let auto-login work); and the deactivation criterion put transients at High, which flags correct conventional behaviour on nearly every plugin. The fresh-clone reproduction now uses `git archive HEAD` rather than a hand-derived exclusion list that drifts from `.gitignore`.

- **The planning layer was dead on Linux.** `session-start.sh`, `user-prompt-submit.sh` and `stop.sh` each derived a file's mtime with `stat -f %m "$f" || stat -c %Y "$f"`. That is correct on BSD/macOS. On GNU/Linux `-f` means *file system status*, so `%m` is not a format string — it is parsed as a second FILE argument. GNU prints a six-line filesystem dump for `$f`, **then** exits 1 because no file named `%m` exists, so the `||` fallback runs too and the capture holds both. Arithmetic on that blob is a syntax error, the comparison silently evaluates false, and all three hooks concluded there was no active feature.

  Net effect: no plan injection on every turn, no session-start banner, no `progress.md` timestamping — the entire Descrição mechanism, silently inert, on every Linux machine. Green on the author's laptop the whole time.

  Found by the new CI workflow on its first run: 17 failures on Linux, 0 on macOS.

- **Hook logic is no longer triplicated.** The active-feature selection was copy-pasted into all three hooks, with a comment in `stop.sh` asking the reader to keep them "in lockstep" by hand — which is how they came to share an identical bug. `.claude/hooks/lib.sh` now owns `hook_mtime`, `hook_is_complete` and `hook_active_progress`. `hook_mtime` probes once for which `stat` the machine has and validates its own output is numeric, so no future platform can reintroduce this class of bug.

- **The pre-commit gate never fired for the most common way to commit.** `pre-commit.sh` matched `git commit*` as a *prefix*, so it only triggered when the command began with those words. `git add -A && git commit -m x` — the idiom most people and most agents actually type — sailed straight past it, as did `cd sub && git commit` and `git -C dir commit`. The gate looked present and was inert for the shapes that matter. It now matches `git … commit` anywhere in the command, allowing flags and paths between the two words but not a command separator.

  The tradeoff is that a command merely *mentioning* committing (`git log --grep=commit`) now runs the suite. That is the safe direction — a needless quality run costs seconds, a skipped gate costs a broken commit — and a block now names the command that triggered it, so a false positive explains itself.

- **The pre-commit gate silently disabled itself without `python3`.** The payload was parsed with `python3 -c` and nothing checked whether the interpreter existed. On a host without it the capture came back empty, matched no pattern, and the hook exited 0 — no gate, no warning, no way to notice. It now tries `python3`, falls back to `jq`, and if neither is available says **"THE QUALITY GATE IS NOT RUNNING"** on stderr. It still does not block, because this hook fires before every Bash call and blocking on its own internal errors would wedge the session — but failing open silently and failing open loudly are very different things.

- **A flaky test in `test-stop.sh`.** The multi-feature case rewrote both fixtures with `sed -i.bak`, making their mtimes equal to the second, then `touch`ed the newer one to break the tie. Since mtime resolution here is whole seconds, that only won a sub-second race — which macOS happened to win and Linux consistently lost. It now pushes the older fixture into the past with `touch -t`, which is portable and deterministic.

## v1.0.3 — 2026-06-11

### Added

- **`DataForm` reference for React admin settings pages** (`.claude/references/DATAFORM.md`). `@wordpress/dataviews`' `DataForm` / `DataViews` is the direction WordPress core is taking for admin UI, so the kit now offers it as a forward-looking option alongside the PHP Settings API — with a decision table for which to reach for. Covers the `@wordpress/dataviews/wp` import path required under `wp-scripts`, registering the plugin's one option as a REST-exposed schema (`show_in_rest` + `additionalProperties => false`), enqueuing via the generated `index.asset.php`, mounting the React app, and the `fields` / `form` config shape. Critically it supplies the **security layer the upstream WordPress.org tutorial omits**: double capability gating, schema-as-validation, a `sanitize_callback` for defense in depth, and why the REST nonce authenticates but does not authorise.
- **`@wordpress/dataviews` added to the constitution's default npm dependencies**, flagged pre-1.0 — import from `/wp`, pin the version, re-check the API on upgrade.

### Changed

- `CLAUDE.md`'s load-on-demand references now list `DATAFORM.md` alongside `BLOCKS.md`.

### Fixed

- **Quality gate is green again.** The v1.0.2 autoloader closure named its parameter `$class`, which a newer WPCS sniff (`Universal.NamingConventions.NoReservedKeywordParameterNames`) flags as a reserved keyword — turning `scripts/quality.sh` red. Renamed it to `$fqcn`. No behaviour change.

## v1.0.2 — 2026-06-02

### Fixed

- **A freshly scaffolded plugin no longer fatals on activation.** The template's Composer autoload was PSR-4 (`PLExample\ => includes/`), which cannot resolve the kit's own WordPress-style `class-{name}.php` filenames — so every plugin class (starting with the example `Rest` controller) failed to load and the plugin died with `Class ... not found` the instant it was activated. None of the static gates caught it, because nothing in `quality.sh` boots WordPress; it only surfaced under a live wp-playground activation. Switched the plugin's own classes to a `classmap` autoload, plus a small WordPress-style `spl_autoload_register` in the main file that resolves `class-*.php` files — including new ones added mid-feature, with no `composer dump-autoload` step.

## v1.0.1 — 2026-06-02

### Fixed

- **The quality gate now passes on a fresh scaffold.** `scripts/quality.sh` ran `phpcs --standard=WordPress`, which overrode the project `phpcs.xml.dist` and discarded its `<file>` list, so phpcs aborted with "must supply at least one file or directory" — and `pre-commit.sh` blocked the very first commit. It now runs `phpcs` against the project ruleset, gated on a `phpcs.xml(.dist)` being present.
- **phpunit no longer fails an unconfigured scaffold.** The suite runs phpunit only when a `phpunit.xml(.dist)` exists. The example `WP_UnitTestCase` test needs the WordPress test harness (wp-env); until that's set up, phpunit stays benign instead of erroring out.
- **Example template files are now WordPress-Coding-Standards clean** (36 phpcs violations → 0): added the missing class / function / parameter / member docblocks, switched to long array syntax, scoped a `phpcs:ignore` to the one-shot direct DB call in `uninstall.php`, and excluded the entry-point main file from the class-file-naming sniff. A freshly scaffolded plugin is green out of the box.

## v1.0.0 — 2026-05-19

The first release that's structurally complete: every D of the talk's framework is wired into the kit, and every piece has its place.

### Added

- **Planning layer** (`.claude/plans/`). Four-file cascade — `constitution.md` (project-stable), per-feature `spec.md` / `plan.md` / `progress.md`, optional `findings.md`. Shipped features archive to `.claude/plans/archive/{YYYY-MM-DD}-{slug}/`. Templates and rationale in `.claude/references/PLANNING.md`.
- **`wordpress-feature` skill.** Greenfield was `wordpress-development` before; now split so `wordpress-feature` handles the per-PR loop (spec → plan → freeze → implement → ship) and `wordpress-scaffold` handles the once-per-plugin bootstrap.
- **Conditional plan-freeze.** Every `plan.md` ends with a five-checkbox Freeze assessment. Any box checked → plan-PR loop. Zero checked → in-session execution. Trivial features no longer pay PR ceremony.
- **`plan-reviewer` sub-agent.** Read-only audit of `spec.md` + `plan.md` before human review. Catches missing `Out of scope`, steps without file paths, dishonest freeze assessments, and constitution-violating choices.
- **`UserPromptSubmit` hook.** Injects the active feature's `next_action` and `last_completed` on every prompt — the load-bearing defense against plan drift.
- **`Stop` hook.** Auto-bumps `progress.md`'s `last_updated` when the agent finishes a turn, so file age tracks activity even when the agent forgets to log.
- **`SessionStart` hook.** Orientation banner on `resume|compact|clear` naming the active feature and next step.
- **Slash commands.** `/plan-freeze`, `/audit-plan`, `/ship-feature` wrap the common operations as muscle-memory shortcuts.
- **`scripts/open-plan-pr.sh`.** Automates the plan-freeze flow — branch, commit, push, `gh pr create` with pre-filled body.
- **`tests/` directory.** Bash test suite for the four hooks (56 cases, plain bash, zero deps). Integrated into `scripts/quality.sh` so a failing hook blocks commits.
- **Worked example feature** (`.claude/plans/features/001-example-hello-rest/`). Spec, plan, findings, progress — plus the actual code (`pl-example.php`, `includes/api/class-rest-hello.php`, `tests/phpunit/test-rest-hello.php`) that the plan refers to. Every file the plan names exists.
- **Docs chapter 3 — Planning.** Walks the four-file cascade, the freeze assessment, and the conditional-vs-unconditional reasoning end to end. Existing chapters renumbered (4–9).
- **Four D's framing wired through every README** (`.claude/plans/`, `.claude/skills/*/`, `.claude/agents/`, `.claude/hooks/`, top-level README, docs walkthrough) — Delegação / Descrição / Discernimento / Diligência mapped to specific kit pieces.

### Changed

- **Constitution split into two binding levels.** Strict sections (sanitizers, escapers, capability constants, forbidden constructs) bind hard — the failure mode is a CVE. Default sections (npm / Composer dependencies) are advisory — extend as needed, note why in `findings.md`. Treats security and dependency choices as the different decisions they are.
- **`SKILL.md` files trimmed ~70%.** Both `wordpress-scaffold/SKILL.md` and `wordpress-feature/SKILL.md` down from ~180 lines to 54. Duplicated security and plan-file rules removed; phase prose compressed; references centralized in `.claude/references/`. Trusts the model more.
- **References promoted to `.claude/references/`.** `SECURITY.md`, `BLOCKS.md`, `PLANNING.md` now shared across both skills, both sub-agents, and the planning chapter — single source of truth.
- **`security-reviewer` description.** Now references the shared `.claude/references/SECURITY.md` instead of the old per-skill copy.
- **CLAUDE.md / AGENTS.md "Memory hygiene" section.** Clarified that per-feature memory lives in `progress.md` / `findings.md`; `CHANGELOG.md` is for release notes only.

### Removed

- `wordpress-development` skill — split into `wordpress-scaffold` + `wordpress-feature`. The old skill name no longer appears anywhere in the kit.
- Duplicated security checklists from `SKILL.md` files. The canonical list is at `.claude/references/SECURITY.md`; `CLAUDE.md` repeats the load-bearing items in its first 40 lines.
- Invented skill frontmatter fields (`license:`, `compatibility:`). Claude Code skills only honor a defined set of keys; the others were silently ignored.

### Fixed

- `UserPromptSubmit` hook status parser now tolerates whitespace, case, and completion synonyms (`done`, `shipped`, `archived`, `completed`).
- Plan PR script (`scripts/open-plan-pr.sh`) header now documents the GitHub assumption and the requirement for `gh` on PATH.
- `github` MCP entry in `.mcp.json` ships with the `${GITHUB_TOKEN}` env block pre-wired — just export the variable in your shell.

---

## v0.1.0 — 2026-04

Initial scaffold release: CLAUDE.md / AGENTS.md templates, the `wordpress-development` skill, `security-reviewer` sub-agent, post-edit + pre-commit hooks, the five MCP servers, the Node CLI (`create-wp-ai-plugin`), and the eight-chapter docs walkthrough.
